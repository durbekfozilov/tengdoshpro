import 'package:flutter/material.dart';
import '../../../../core/services/data_service.dart';
import 'survey_detail_analytics_screen.dart';

class ManagementRatingStatsScreen extends StatefulWidget {
  const ManagementRatingStatsScreen({super.key});

  @override
  State<ManagementRatingStatsScreen> createState() => _ManagementRatingStatsScreenState();
}

class _ManagementRatingStatsScreenState extends State<ManagementRatingStatsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  List<dynamic> _surveys = [];

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    setState(() => _isLoading = true);
    final surveys = await _dataService.getManagementSurveys();
    
    // Mock data if empty for testing
    if (surveys.isEmpty) {
      _surveys = [
        {
          'id': 1,
          'title': "Tyutorlarni baholash (Aprel)",
          'status': 'active', // active, finished, pending
          'start_at': '2026-04-01 09:00:00',
          'end_at': '2026-04-30 18:00:00',
          'total_votes': 156,
        },
        {
          'id': 2,
          'title': "Mart oyi yakuniy so'rovnoma",
          'status': 'finished',
          'start_at': '2026-03-01 09:00:00',
          'end_at': '2026-03-31 18:00:00',
          'total_votes': 1240,
        },
        {
          'id': 3,
          'title': "May oyi rejasi",
          'status': 'pending',
          'start_at': '2026-05-01 09:00:00',
          'end_at': '2026-05-31 18:00:00',
          'total_votes': 0,
        }
      ];
    } else {
      _surveys = surveys;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("So'rovnomalar natijalari"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _loadSurveys,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _surveys.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _surveys.length,
                  itemBuilder: (context, index) {
                    final survey = _surveys[index];
                    return _SurveyListItem(survey: survey);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "So'rovnomalar topilmadi",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SurveyListItem extends StatelessWidget {
  final dynamic survey;
  const _SurveyListItem({required this.survey});

  @override
  Widget build(BuildContext context) {
    final String status = survey['status'] ?? 'pending';
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurveyDetailAnalyticsScreen(surveyId: survey['id'], title: survey['title']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${survey['total_votes']} ta ovoz",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                survey['title'] ?? 'Nomsiz so\'rovnoma',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    "${survey['start_at'].substring(0, 10)} - ${survey['end_at'].substring(0, 10)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'finished': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return "Faol";
      case 'finished': return "Tugagan";
      case 'pending': return "Kutilayotgan";
      default: return "Noma'lum";
    }
  }
}
