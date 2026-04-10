import 'dart:async';
import 'package:flutter/material.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import '../../../../core/services/data_service.dart';
import '../../../../core/localization/app_dictionary.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentRatingScreen extends StatefulWidget {
  final String roleType;
  const StudentRatingScreen({super.key, required this.roleType});

  @override
  State<StudentRatingScreen> createState() => _StudentRatingScreenState();
}

class _StudentRatingScreenState extends State<StudentRatingScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  dynamic _target;
  int? _selectedRating;
  bool _isSubmitting = false;
  
  DateTime? _expiresAt;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final targets = await _dataService.getRatingTargets(widget.roleType);
      
      // Get expires_at from dashboard data as well
      final dashboard = await _dataService.getDashboardStats();
      final expiresAtStr = dashboard['expires_at'];
      
      if (mounted) {
        setState(() {
          if (targets.isNotEmpty) {
            _target = targets.first;
          }
          if (expiresAtStr != null) {
            _expiresAt = DateTime.tryParse(expiresAtStr);
            if (_expiresAt != null) {
              _startTimer();
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expiresAt == null) return;
      
      final now = DateTime.now();
      final diff = _expiresAt!.difference(now);
      
      if (mounted) {
        setState(() {
          _timeLeft = diff.isNegative ? Duration.zero : diff;
          if (diff.isNegative) {
            _timer?.cancel();
          }
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> _submit() async {
    if (_selectedRating == null || _target == null) return;

    setState(() => _isSubmitting = true);
    final result = await _dataService.submitRating(
      ratedPersonId: _target['staff_id'],
      roleType: widget.roleType,
      rating: _selectedRating!,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Bahoyingiz qabul qilindi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Xatolik yuz berdi'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          AppDictionary.tr(context, 'lbl_rate_your_tutor'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textBlack,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _target == null
              ? const _EmptyTargetView()
              : Column(
                  children: [
                    if (_expiresAt != null) _buildCountdownBanner(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            _buildTutorCard(),
                            const SizedBox(height: 32),
                            _buildRatingSection(),
                            const SizedBox(height: 40),
                            _buildSubmitButton(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCountdownBanner() {
    final isCritical = _timeLeft.inHours < 24;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red[50] : AppTheme.primaryBlue.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: isCritical ? Colors.red[100]! : AppTheme.primaryBlue.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 20, color: isCritical ? Colors.red : AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Text(
            "Tugashiga qoldi: ",
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textBlack.withOpacity(0.7)),
          ),
          Text(
            _formatDuration(_timeLeft),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: isCritical ? Colors.red : AppTheme.primaryBlue
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorCard() {
    final imageUrl = _target['image_url'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 2),
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: const Color(0xFFF1F5F9),
              backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
              child: imageUrl == null
                  ? const Icon(Icons.person_outline_rounded, size: 70, color: AppTheme.primaryBlue)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _target['full_name'] ?? '---',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textBlack),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _target['role_name'] ?? 'Guruh tyutori',
              style: GoogleFonts.inter(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final ratings = [
      {'val': 5, 'label': "A'lo darajada", 'icon': '🌟'},
      {'val': 4, 'label': "Yaxshi ko'rsatkich", 'icon': '😊'},
      {'val': 3, 'label': "O'rtacha faoliyat", 'icon': '😐'},
      {'val': 2, 'label': "Qoniqarsiz", 'icon': '😟'},
      {'val': 1, 'label': "Juda yomon", 'icon': '👎'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 20),
          child: Text(
            "Tyutoringizga baho bering",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBlack),
          ),
        ),
        ...ratings.map((r) {
          final val = r['val'] as int;
          final isSelected = _selectedRating == val;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _selectedRating = val),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryBlue : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(r['icon'] as String, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        r['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 16, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textBlack
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24)
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withOpacity(0.1), width: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _selectedRating != null && !_isSubmitting;

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                AppDictionary.tr(context, 'btn_submit'),
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class _EmptyTargetView extends StatelessWidget {
  const _EmptyTargetView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_off_rounded, size: 80, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            Text(
              AppDictionary.tr(context, 'msg_no_rating_targets'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textBlack),
            ),
            const SizedBox(height: 12),
            Text(
              AppDictionary.tr(context, 'msg_rating_unavailable'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppDictionary.tr(context, 'btn_back')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
