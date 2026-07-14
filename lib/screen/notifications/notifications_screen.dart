import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/key_repository.dart';
import '../smart_detail/smart_detail_screen.dart';

String? extractNotificationKeyId(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }

  for (final key in ['keyId', 'key_id', 'itemId', 'key']) {
    final value = data[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return null;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.initialPayload});

  final Map<String, dynamic>? initialPayload;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _selectedKeyId;
  bool _isHandlingTap = false;

  @override
  void initState() {
    super.initState();
    _selectedKeyId = extractNotificationKeyId(widget.initialPayload);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      final payload = Map<String, dynamic>.from(arguments as Map);
      final keyId = extractNotificationKeyId(payload);
      if (keyId != null && keyId != _selectedKeyId) {
        setState(() => _selectedKeyId = keyId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(100)
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
              final rawData = docs[index].data();
              final data = <String, dynamic>{'id': docs[index].id, ...rawData};
              final title = data['title']?.toString() ?? 'Notification';
              final message = data['body']?.toString() ?? '';
              final user = (data['actorName']?.toString().trim().isNotEmpty ?? false)
                  ? data['actorName']!.toString()
                  : (data['recordedBy']?.toString().trim().isNotEmpty ?? false)
                      ? data['recordedBy']!.toString()
                      : 'System';
              final keyId = extractNotificationKeyId(data);
              final relatedKey = keyId == null || keyId.isEmpty
                  ? null
                  : KeyRecordRepository.findKeyById(keyId);
              final keyName = relatedKey?.keyName ?? data['keyName']?.toString() ?? '—';
              final createdAt = data['createdAt'];
              final formattedDate = _formatTimestamp(createdAt);
              final isSelected = keyId != null && keyId == _selectedKeyId;

              return Material(
                color: Colors.transparent,
                child: Card(
                  elevation: isSelected ? 3 : 1,
                  color: isSelected ? const Color(0xFFE8F5E9) : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(message, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text('User: $user', style: Theme.of(context).textTheme.bodySmall),
                      Text('Key: $keyName', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        'Date: $formattedDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                    trailing: const Icon(Icons.chevron_right_outlined),
                    onTap: _isHandlingTap ? null : () => _openRelatedKey(context, data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openRelatedKey(BuildContext context, Map<String, dynamic> data) async {
    if (_isHandlingTap) {
      return;
    }

    setState(() => _isHandlingTap = true);
    try {
      final keyId = extractNotificationKeyId(data);
      if (keyId == null || keyId.isEmpty) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This notification is not linked to a key.')),
        );
        return;
      }

      final relatedKey = KeyRecordRepository.findKeyById(keyId);
      if (relatedKey == null) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The related key is no longer available.')),
        );
        return;
      }

      if (!context.mounted) {
        return;
      }

      setState(() => _selectedKeyId = keyId);
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SmartDetailScreen(record: relatedKey)),
      );
    } finally {
      if (mounted) {
        setState(() => _isHandlingTap = false);
      }
    }
  }

  String _formatTimestamp(Object? createdAt) {
    DateTime? parsed;
    if (createdAt is Timestamp) {
      parsed = createdAt.toDate().toLocal();
    } else if (createdAt is DateTime) {
      parsed = createdAt.toLocal();
    }

    if (parsed == null) {
      return '—';
    }

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }
}
