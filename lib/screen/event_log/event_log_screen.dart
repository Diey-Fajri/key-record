import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/key_repository.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({super.key});

  @override
  State<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Stream<List<EventLog>> _eventsStream = KeyRecordRepository.watchEventLogs();

  String _statusFilter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;

  List<EventLog> _latestEvents = const [];

  static const List<String> _statusOptions = ['All', 'Still Out', 'Returned', 'Lost'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Event Log'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearFilteredLogs,
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'Clear Filtered',
          ),
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Log',
          ),
          IconButton(
            onPressed: _refreshLogs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from Firestore',
          ),
          IconButton(
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<EventLog>>(
          stream: _eventsStream,
          builder: (context, snapshot) {
            final events = snapshot.data ?? const [];
            _latestEvents = events;

            if (snapshot.connectionState == ConnectionState.waiting && events.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredEvents = _filterEvents(events);
            final sortedEvents = _sortEvents(filteredEvents);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWhatsNewCard(sortedEvents),
                  const SizedBox(height: 12),
                  _buildFilterRow(context),
                  const SizedBox(height: 12),
                  Expanded(
                    child: sortedEvents.isEmpty
                        ? const Center(child: Text('No matching event logs found.'))
                        : _buildSimpleList(sortedEvents),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWhatsNewCard(List<EventLog> events) {
    final latest = events.isEmpty ? null : events.first;
    final latestAction = latest == null ? 'No new updates yet. Your log is all caught up.' : _buildSimpleMessage(latest);
    final latestTime = latest == null ? '' : _formatDateTime(latest.dateTimeTaken);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s New',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (latestTime.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              latestTime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            latestAction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Search by Key, Name, I/C, Company, or Date',
                  hintText: 'Type key, name, I/C, company, or date',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _statusFilter,
              items: _statusOptions
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _statusFilter = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickDate(isFrom: true),
              icon: const Icon(Icons.date_range),
              label: Text(_fromDate == null ? 'From Date' : _formatDate(_fromDate!)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _pickDate(isFrom: false),
              icon: const Icon(Icons.date_range_outlined),
              label: Text(_toDate == null ? 'To Date' : _formatDate(_toDate!)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
              },
              child: const Text('Clear Date Range'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  List<EventLog> _filterEvents(List<EventLog> events) {
    final query = _searchController.text.trim().toLowerCase();

    return events.where((event) {
      if (_statusFilter != 'All' && !_matchesStatusFilter(event)) {
        return false;
      }

      if (_fromDate != null && event.dateTimeTaken.isBefore(_fromDate!)) {
        return false;
      }
      if (_toDate != null && event.dateTimeTaken.isAfter(_toDate!)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final tokens = <String>[
        _displayKey(event),
        event.borrowerName,
        event.icPassport,
        event.company,
        _formatDate(event.dateTimeTaken),
        _formatDateTime(event.dateTimeTaken),
      ];
      return tokens.any((token) => token.toLowerCase().contains(query));
    }).toList();
  }

  bool _matchesStatusFilter(EventLog event) {
    switch (_statusFilter) {
      case 'Still Out':
        return event.status == 'In Use' ||
            event.status == 'No Return' ||
            event.status == 'At Maintenance' ||
            event.status == 'Hand Over';
      case 'Returned':
        return event.status == 'Returned';
      case 'Lost':
        return event.status == 'Lost';
      default:
        return true;
    }
  }

  List<EventLog> _sortEvents(List<EventLog> events) {
    final sorted = List<EventLog>.from(events)
      ..sort((a, b) => b.dateTimeTaken.compareTo(a.dateTimeTaken));
    return sorted;
  }

  Widget _buildSimpleList(List<EventLog> events) {
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final event = events[index];
        final sentence = _buildSimpleMessage(event);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: index == 0 ? const Color(0xFFE8F3F1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E5E8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDateTime(event.dateTimeTaken),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                sentence,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    final events = _sortEvents(_filterEvents(_latestEvents));
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Message,Date/Time');

    for (final event in events) {
      final row = [
        _buildSimpleMessage(event),
        _formatDateTime(event.dateTimeTaken),
      ].map(_escapeCsv).join(',');
      csvBuffer.writeln(row);
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/event_log_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvBuffer.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported to ${file.path}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    }
  }

  Future<void> _refreshLogs() async {
    try {
      await KeyRecordRepository.refreshEventLogsFromFirestore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event log refreshed from Firestore.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: $error')),
      );
    }
  }

  Future<void> _clearLogs() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Event Log'),
          content: const Text('Delete all event logs? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    try {
      await KeyRecordRepository.clearEventLogs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event log cleared.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clear log failed: $error')),
      );
    }
  }

  Future<void> _clearFilteredLogs() async {
    final filtered = _sortEvents(_filterEvents(_latestEvents));
    if (filtered.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No filtered logs to clear.')),
      );
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Filtered Logs'),
          content: Text('Delete ${filtered.length} filtered log(s)? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Filtered'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    try {
      await KeyRecordRepository.clearFilteredEventLogs(filtered);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${filtered.length} filtered log(s) cleared.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clear filtered logs failed: $error')),
      );
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  String _formatDateTime(DateTime value) {
    return '${_formatDate(value)} ${_formatTime(value)}';
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}${value.minute.toString().padLeft(2, '0')}hrs';
  }

  String _displayKey(EventLog event) {
    final category = event.category.trim().toLowerCase();
    final rollerNo = event.metadata['rollerNumber']?.toString().trim() ?? '';
    final rollerLevelNo = event.metadata['rollerLevelNo']?.toString().trim() ?? '';

    if (category == 'roller shutter' || rollerNo.isNotEmpty || rollerLevelNo.isNotEmpty) {
      var level = event.metadata['level']?.toString().trim() ?? '';
      var number = rollerNo;

      if ((level.isEmpty || number.isEmpty) && rollerLevelNo.contains('/')) {
        final parts = rollerLevelNo.split('/');
        if (parts.isNotEmpty && level.isEmpty) {
          level = parts.first.trim();
        }
        if (parts.length > 1 && number.isEmpty) {
          number = parts[1].trim();
        }
      }

      if (level.isNotEmpty && number.isNotEmpty) {
        return 'Roller Shutter $level/$number';
      }
      if (number.isNotEmpty) {
        return 'Roller Shutter $number';
      }
      if (level.isNotEmpty) {
        return 'Roller Shutter $level';
      }
    }

    final level = event.metadata['level']?.toString().trim() ?? '';
    final zone = event.metadata['zone']?.toString().trim() ?? '';
    if (level.isNotEmpty && zone.isNotEmpty) {
      return '$level/$zone';
    }
    return event.keyId.isNotEmpty ? event.keyId : event.keyName;
  }

  String _buildSimpleMessage(EventLog event) {
    final key = _displayKey(event).toUpperCase();
    final actor = event.actor.trim().isEmpty ? 'member' : event.actor;

    if (event.action == 'New Key Registered') {
      return 'New Key added: $key by "$actor".';
    }

    if (event.status == 'In Use' || event.action.contains('Taken')) {
      final borrower = event.borrowerName.trim().isEmpty ? 'member' : event.borrowerName;
      return 'Key $key borrowed by "$borrower".';
    }

    if (event.status == 'Lost' || event.action == 'Lost') {
      return 'Heads up: key $key is now marked as Lost.';
    }

    if (event.status == 'Returned' || event.action == 'Returned') {
      return 'Nice, key $key has been returned.';
    }

    return '${event.action} - key $key by "$actor".';
  }
}
