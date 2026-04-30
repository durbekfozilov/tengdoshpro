import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talabahamkor_mobile/core/network/data_service.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTarget = 'Guruh'; // 'Guruh', 'Fakultet', 'Hamma'
  bool _isSending = false;

  void _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sarlavha va xabar matnini to\'ldiring!')),
      );
      return;
    }

    setState(() => _isSending = true);
    
    final dataService = Provider.of<DataService>(context, listen: false);
    try {
      // Mocking the push notification logic
      final response = await dataService.authPost(
        '/management/notifications/send',
        body: {
          'title': _titleController.text,
          'message': _messageController.text,
          'target': _selectedTarget,
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xabarnoma muvaffaqiyatli yuborildi!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Server xatosi');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Xabarnoma yuborish'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kimga yuborish?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: ['Guruh', 'Fakultet', 'Hamma'].map((target) {
                final isSelected = _selectedTarget == target;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(target),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedTarget = target),
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Xabar tafsilotlari', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Sarlavha',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Xabar matni...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendNotification,
                icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                label: Text(_isSending ? 'Yuborilmoqda...' : 'Xabarnomani yuborish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
