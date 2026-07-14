import 'package:flutter/material.dart';

import '../../services/key_repository.dart';

class TakeKeyDetailScreen extends StatefulWidget {
  const TakeKeyDetailScreen({required this.record, super.key});

  final KeyRecord record;

  @override
  State<TakeKeyDetailScreen> createState() => _TakeKeyDetailScreenState();
}

class _TakeKeyDetailScreenState extends State<TakeKeyDetailScreen> {
  late KeyRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  @override
  Widget build(BuildContext context) {
    final borrowerLabel = _borrowerLabel(_record);
    final fields = <Widget>[
      _Field(label: 'Status', value: _record.status),
      _Field(label: 'Borrower Category', value: _record.metadata['borrowerCategory']?.toString() ?? ''),
      _Field(label: 'Name', value: borrowerLabel),
      _Field(label: 'IC / Passport', value: _record.icPassport),
      _Field(label: 'Phone', value: _record.phoneNumber),
      _Field(label: 'Company', value: _record.company),
      _Field(label: 'Department', value: _record.metadata['department']?.toString() ?? ''),
      _Field(label: 'Purpose', value: _record.purpose),
      _Field(label: 'Date / Time Taken', value: _formatDateTime(_record.takenAt)),
      _Field(label: 'Document Report No.', value: _record.metadata['documentReportNo']?.toString() ?? ''),
      _Field(label: 'Handover By', value: _record.metadata['handoverBy']?.toString() ?? ''),
      _Field(label: 'Received By', value: _record.metadata['receivedBy']?.toString() ?? ''),
      _Field(label: 'Witnesses By', value: _record.metadata['witnessesBy']?.toString() ?? ''),
      _Field(label: 'Handover Date', value: _record.metadata['handoverDate']?.toString() ?? ''),
      _Field(label: 'Handover Time', value: _record.metadata['handoverTime']?.toString() ?? ''),
    ].whereType<_Field>().where((field) => field.hasValue).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Take Key Details'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...fields,
          ],
        ),
      ),
    );
  }

  String _borrowerLabel(KeyRecord key) {
    final staff = key.metadata['staffName']?.toString().trim() ?? '';
    final others = key.metadata['othersName']?.toString().trim() ?? '';
    if (staff.isNotEmpty) return staff;
    if (others.isNotEmpty) return others;
    if (key.borrowerName.trim().isNotEmpty) return key.borrowerName;
    return '-';
  }

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute:$second';
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  bool get hasValue => value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final normalized = value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: normalized,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
          ),
        ),
      ),
    );
  }
}
