import 'package:flutter/material.dart';
import '../../../../core/services/data_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SurveyDetailAnalyticsScreen extends StatefulWidget {
  final int surveyId;
  final String title;
  const SurveyDetailAnalyticsScreen({super.key, required this.surveyId, required this.title});

  @override
  State<SurveyDetailAnalyticsScreen> createState() => _SurveyDetailAnalyticsScreenState();
}

class _SurveyDetailAnalyticsScreenState extends State<SurveyDetailAnalyticsScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final analytics = await _dataService.getSurveyAnalyticsDetail(widget.surveyId);
    
    // Mock data for demonstration if empty
    if (analytics.isEmpty) {
      _analytics = {
        'overall_votes': 156,
        'completion_rate': 85.5,
        'questions_summary': [
          {
            'question': "Tyutorning talabalar bilan muloqot madaniyati",
            'votes_distribution': [
              {'label': "A'lo", 'count': 90, 'percentage': 57.7},
              {'label': "Yaxshi", 'count': 45, 'percentage': 28.8},
              {'label': "Qoniqarli", 'count': 15, 'percentage': 9.6},
              {'label': "Yomon", 'count': 6, 'percentage': 3.8},
            ]
          },
          {
            'question': "Tyutorning o'z vaqtida yordam berishi",
            'votes_distribution': [
              {'label': "A'lo", 'count': 110, 'percentage': 70.5},
              {'label': "Yaxshi", 'count': 30, 'percentage': 19.2},
              {'label': "Qoniqarli", 'count': 10, 'percentage': 6.4},
              {'label': "Yomon", 'count': 6, 'percentage': 3.8},
            ]
          }
        ],
        'tutors_ranking': [
          {
            'full_name': 'Aliyev Valijon',
            'average_rating': 4.8,
            'total_votes': 45,
            'image_url': null,
          },
          {
            'full_name': 'Karimova Gulnoza',
            'average_rating': 4.6,
            'total_votes': 38,
            'image_url': null,
          },
          {
            'full_name': 'Solijonov Rustam',
            'average_rating': 4.2,
            'total_votes': 73,
            'image_url': null,
          }
        ]
      };
    } else {
      _analytics = analytics;
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
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryHeader(),
                  const SizedBox(height: 24),
                  const Text("Savollar bo'yicha tahlil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...(_analytics['questions_summary'] as List).map((q) => _buildQuestionAnalytics(q)).toList(),
                  const SizedBox(height: 24),
                  const Text("Tyutorlar reytingi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...(_analytics['tutors_ranking'] as List).map((t) => _buildTutorRankCard(t)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.blue]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem("Umumiy ovozlar", _analytics['overall_votes'].toString(), Icons.people_outline),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem("Aktivlik", "${_analytics['completion_rate']}%", Icons.trending_up_rounded),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildQuestionAnalytics(dynamic q) {
    final List<dynamic> dist = q['votes_distribution'];
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q['question'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ...dist.map((d) => _buildVoteBar(d)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteBar(dynamic d) {
    final double pct = (d['percentage'] as num).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(d['label'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text("${d['count']} ta (${pct.toStringAsFixed(1)}%)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey[100],
              color: _getBarColor(d['label']),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(String label) {
    if (label.contains("A'lo")) return Colors.green;
    if (label.contains("Yaxshi")) return Colors.blue;
    if (label.contains("Qoniqarli")) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTutorRankCard(dynamic t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          backgroundImage: t['image_url'] != null ? CachedNetworkImageProvider(t['image_url']) : null,
          child: t['image_url'] == null ? const Icon(Icons.person, color: Colors.blue) : null,
        ),
        title: Text(t['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${t['total_votes']} ta ovoz olingan", style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                t['average_rating'].toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
