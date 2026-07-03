import 'package:flutter/material.dart';
import '../../services/key_repository.dart';
import '../smart_detail/smart_detail_screen.dart';

class AllKeysScreen extends StatelessWidget {
  const AllKeysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('All Keys'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<List<KeyRecord>>(
          stream: KeyRecordRepository.watchAllKeys(),
          builder: (context, snapshot) {
            final keys = snapshot.data ?? const [];
            if (snapshot.connectionState == ConnectionState.waiting && keys.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (keys.isEmpty) {
              return const Center(child: Text('No key records available.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: keys.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = keys[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE0E5E8)),
                  ),
                  child: ListTile(
                    title: Text(record.keyName),
                    subtitle: Text('${record.zone} • ${record.keyId}'),
                    trailing: _StatusTag(status: record.status),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SmartDetailScreen(record: record),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Available'
        ? const Color(0xFFE7F5EA)
        : status == 'In Use'
            ? const Color(0xFFE8F3F1)
            : const Color(0xFFFFE5E5);
    final textColor = status == 'Available'
        ? const Color(0xFF2E7D32)
        : status == 'In Use'
            ? const Color(0xFF00695C)
            : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
