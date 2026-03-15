import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatelessWidget {
  final String uid;

  const NotificationsPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final notificationsRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark all as read
              final unreadDocs = await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(uid)
                  .collection('items')
                  .where('read', isEqualTo: false)
                  .get();

              final batch = FirebaseFirestore.instance.batch();
              for (var doc in unreadDocs.docs) {
                batch.update(doc.reference, {'read': true});
              }
              await batch.commit();
            },
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isRead = data['read'] ?? false;
              final timestamp = data['createdAt'] as Timestamp?;
              final dateStr = timestamp != null 
                  ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                  : '';

              return ListTile(
                tileColor: isRead ? null : Colors.blue.shade50,
                leading: CircleAvatar(
                  backgroundColor: _getIconColor(data['type']),
                  child: Icon(_getIcon(data['type']), color: Colors.white),
                ),
                title: Text(
                  data['title'] ?? 'Notification',
                  style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['body'] ?? ''),
                    if (dateStr.isNotEmpty)
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                onTap: () {
                  if (!isRead) {
                    docs[index].reference.update({'read': true});
                  }
                  // TODO: Navigate to related item based on data['type'] and data['relatedId']
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String? type) {
    if (type == null) return Icons.notifications;
    switch (type) {
      case 'job_offer':
      case 'job_accepted':
      case 'job_completed':
        return Icons.work;
      case 'new_message':
        return Icons.message;
      case 'badge_earned':
        return Icons.emoji_events;
      case 'lesson_completed':
        return Icons.school;
      case 'account_approved':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    if (type == null) return Colors.blue;
    switch (type) {
      case 'job_offer':
      case 'job_accepted':
      case 'job_completed':
        return Colors.green;
      case 'new_message':
        return Colors.blue;
      case 'badge_earned':
        return Colors.amber;
      case 'lesson_completed':
        return Colors.purple;
      case 'account_approved':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
