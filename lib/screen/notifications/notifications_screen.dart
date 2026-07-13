import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF263238),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Card(
                child: ListTile(
                  title: Text(data['title']?.toString() ?? 'Notification'),
                  subtitle: Text(data['body']?.toString() ?? ''),
                  trailing: Text(
                    data['type']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NotificationDetailsScreen(notification: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationDetailsScreen extends StatelessWidget {
  const NotificationDetailsScreen({
    super.key,
    required this.notification,
  });

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    final title = notification['title']?.toString() ?? 'Notification';
    final body = notification['body']?.toString() ?? '';
    final type = notification['type']?.toString() ?? 'General';
    final createdAt = notification['createdAt'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
        backgroundColor: const Color(0xFF263238),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Type: $type', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (createdAt != null)
              Text(
                'Created: ${createdAt is Timestamp ? createdAt.toDate() : createdAt}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
