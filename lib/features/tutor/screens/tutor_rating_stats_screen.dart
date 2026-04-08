import 'package:flutter/material.dart';
import 'package:talabahamkor_mobile/core/services/data_service.dart';
import 'package:talabahamkor_mobile/core/theme/app_theme.dart';
import 'package:talabahamkor_mobile/core/localization/app_dictionary.dart';

class TutorRatingStatsScreen extends StatefulWidget {
  const TutorRatingStatsScreen({super.key});

  @override
  State<TutorRatingStatsScreen> createState() => _TutorRatingStatsScreenState();
}

class _TutorRatingStatsScreenState extends State<TutorRatingStatsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await _dataService.getTutorRatingStats();
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading tutor rating stats: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Mening Reytingim"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyticsData == null || _analyticsData!['data'] == null
              ? _buildEmptyState()
              : _buildAnalyticsContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "Hozircha ma'lumotlar mavjud emas",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "So'rovnoma yakunlangach natijalar shu yerda ko'rinadi",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    final data = _analyticsData!['data'];
    final int totalVotes = data['total_votes'] ?? 0;
    final double averageRating = double.tryParse(data['average_rating']?.toString() ?? "0") ?? 0.0;
    final List<dynamic> questions = data['questions'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Header
          _buildSummaryHeader(totalVotes, averageRating),
          const SizedBox(height: 24),

          const Text(
            "Savollar bo'yicha tahlil",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // Questions List
          ...questions.map((q) => _buildQuestionCard(q)).toList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(int totalVotes, double averageRating) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Umumiy O'rtacha Ball",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
          ),
          Container(
            height: 80,
            width: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              const Text(
                "Ovozlar",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                "$totalVotes",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "ta",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final String text = question['text'] ?? "Savol matni yo'q";
    final List<dynamic> options = question['options'] ?? [];
    final int qTotalVotes = question['total_votes'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          ...options.map((opt) {
            final String optText = opt['text'] ?? "";
            final int count = opt['votes_count'] ?? 0;
            final double percent = (count / (qTotalVotes > 0 ? qTotalVotes : 1));
            
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        optText,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                    Text(
                      "$count ta (${(percent * 100).toStringAsFixed(1)}%)",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.indigo.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent > 0.7 ? Colors.green : (percent > 0.3 ? Colors.indigo.shade400 : Colors.orange),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
