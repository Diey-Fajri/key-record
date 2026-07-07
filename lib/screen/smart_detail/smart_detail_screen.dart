import 'package:flutter/material.dart';

import '../../services/key_repository.dart';
import '../register/register.dart';

class SmartDetailScreen extends StatelessWidget {
  const SmartDetailScreen({required this.record, super.key});

  final KeyRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Smart Detail'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E5E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.keyName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      _StatusTag(status: record.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.zone,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  _ReadOnlyField(label: 'Key ID', value: record.keyId),
                  _ReadOnlyField(label: 'Category', value: record.category),
                  _ReadOnlyField(label: 'Zone', value: record.zone),
                  _ReadOnlyField(label: 'Status', value: record.status),
                  _ReadOnlyField(label: 'Borrower Name', value: record.borrowerName),
                  _ReadOnlyField(label: 'I/C Passport No', value: record.icPassport),
                  _ReadOnlyField(label: 'Phone Number', value: record.phoneNumber),
                  _ReadOnlyField(label: 'Company', value: record.company),
                  _ReadOnlyField(label: 'Purpose', value: record.purpose),
                  _ReadOnlyField(
                    label: 'Date/Time Taken',
                    value: '${_formatDate(record.takenAt)} ${_formatTime(record.takenAt)}',
                  ),
                  if (record.metadata.isNotEmpty) ...[
                    _ReadOnlyField(label: 'Metadata', value: _formatMetadata(record.metadata)),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _canReturn ? () async => _handleAction(context, 'Returned') : null,
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('Returned'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (_canAddKey)
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Key'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00695C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          await _handleAction(context, value);
                        },
                        itemBuilder: (context) => [
                          if (_canEdit)
                            const PopupMenuItem(value: 'Edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'Lost', child: Text('Lost')),
                          const PopupMenuItem(value: 'Replaced', child: Text('New key replaced')),
                          const PopupMenuItem(value: 'Hand Over', child: Text('Hand Over')),
                          const PopupMenuItem(value: 'Damaged', child: Text('Damaged')),
                          if (record.status == 'Lost')
                            const PopupMenuItem(value: 'Found', child: Text('Key found')),
                        ],
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.more_horiz),
                          label: const Text('More'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canReturn => record.status == 'In Use' || record.status == 'Hand Over';

  bool get _canAddKey => record.status == 'Available';

  bool get _canEdit => record.status == 'In Use';

  Future<void> _handleAction(BuildContext context, String action) async {
    if (action == 'Returned') {
      await KeyRecordRepository.returnKey(record);
    } else if (action == 'Edit') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit key action is ready to connect next.')),
        );
      }
      return;
    } else if (action == 'Found') {
      await KeyRecordRepository.returnKey(record);
    } else if (action == 'Lost') {
      await KeyRecordRepository.markLost(record);
    } else if (action == 'Replaced') {
      await KeyRecordRepository.markReplaced(record);
    } else if (action == 'Hand Over') {
      await KeyRecordRepository.markHandOver(record);
    } else if (action == 'Damaged') {
      await KeyRecordRepository.markDamaged(record);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action updated.')),
      );
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF9FBFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

String _formatMetadata(Map<String, dynamic> metadata) {
  return metadata.entries.map((entry) => '${entry.key}: ${entry.value}').join(' | ');
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bgColor = status == 'In Use'
        ? const Color(0xFFE8F3F1)
        : status == 'Available'
            ? const Color(0xFFE7F5EA)
            : status == 'Hand Over'
                ? const Color(0xFFE9EEF6)
                : status == 'Damaged' || status == 'Replaced'
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFFFE5E5);
    final textColor = status == 'In Use'
        ? const Color(0xFF00695C)
        : status == 'Available'
            ? const Color(0xFF2E7D32)
            : status == 'Hand Over'
                ? const Color(0xFF1E3A5F)
                : status == 'Damaged' || status == 'Replaced'
                    ? const Color(0xFFEF6C00)
                    : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
