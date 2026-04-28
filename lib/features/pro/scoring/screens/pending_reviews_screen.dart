import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scoring_provider.dart';

class PendingReviewsScreen extends StatefulWidget {
  const PendingReviewsScreen({super.key});

  @override
  State<PendingReviewsScreen> createState() => _PendingReviewsScreenState();
}

class _PendingReviewsScreenState extends State<PendingReviewsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ScoringProvider>().fetchPendingActivities());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arizalarni ko\'rib chiqish'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Consumer<ScoringProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pendingActivities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Barcha arizalar ko\'rib chiqilgan!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pendingActivities.length,
            itemBuilder: (context, index) {
              final activity = provider.pendingActivities[index];
              return _buildActivityCard(context, activity);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, dynamic activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: activity['student_image'] != null 
                  ? NetworkImage(activity['student_image']) 
                  : null,
              child: activity['student_image'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(activity['student_name'] ?? 'Noma\'lum talaba', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(activity['category'] ?? 'Faoliyat'),
            trailing: Text(activity['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              activity['description'] ?? '',
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (activity['image_url'] != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  activity['image_url'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showReviewDialog(context, activity['id'], 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Rad etish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showReviewDialog(context, activity['id'], 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Tasdiqlash'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, int id, String status) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'approved' ? 'Tasdiqlash' : 'Rad etish'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            hintText: 'Izoh yozing (ixtiyoriy)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<ScoringProvider>().updateActivityStatus(
                id, 
                status, 
                comment: commentController.text
              );
              if (mounted && success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(status == 'approved' ? 'Tasdiqlandi' : 'Rad etildi'),
                    backgroundColor: status == 'approved' ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yuborish'),
          ),
        ],
      ),
    );
  }
}
