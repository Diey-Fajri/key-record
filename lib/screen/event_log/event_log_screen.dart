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
  String _statusFilter = 'All';
  int? _sortColumnIndex;
  bool _sortAscending = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  List<EventLog> _latestEvents = const [];

  static const List<String> _statusOptions = [
    'All',
    'In Use',
    'Still Out',
    'Returned',
    'Lost',
    'No Return',
    'At Maintenance',
    'Hand Over',
    'Damaged',
    'Replaced',
    'New Key Registered',
  ];

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
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: const Text('Event Log'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StreamBuilder<List<EventLog>>(
                stream: KeyRecordRepository.watchEventLogs(),
                builder: (context, snapshot) {
                  final events = snapshot.data ?? const [];
                  _latestEvents = events;
                  return _buildProgressCard(events);
                },
              ),
              const SizedBox(height: 12),
              _buildFilterRow(context),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<EventLog>>(
                  stream: KeyRecordRepository.watchEventLogs(),
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? const [];
                    _latestEvents = events;
                    if (snapshot.connectionState == ConnectionState.waiting && events.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredEvents = _filterEvents(events);
                    final sortedEvents = _sortEvents(filteredEvents);

                    if (sortedEvents.isEmpty) {
                      return const Center(child: Text('No matching event logs found.'));
                    }

                    return _buildPaginatedTable(sortedEvents);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() {
    Future<void>.microtask(() {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  Widget _buildFilterRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by key, name, IC, company, or date',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
                  ),
                ),
                onChanged: (_) => setState(() {}),
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
      ],
    );
  }

  Widget _buildProgressCard(List<EventLog> events) {
    final total = events.length;
    final inUse = events.where((event) => event.status == 'In Use').length;
    final returned = events.where((event) => event.status == 'Returned').length;
    final lost = events.where((event) => event.status == 'Lost').length;
    final noReturn = events.where((event) => event.status == 'No Return').length;
    final maintenance = events.where((event) => event.status == 'At Maintenance').length;
    final handOver = events.where((event) => event.status == 'Hand Over').length;
    final damaged = events.where((event) => event.status == 'Damaged').length;
    final replaced = events.where((event) => event.status == 'Replaced').length;
    final latestAction = events.isEmpty ? 'No reports yet' : events.first.action;

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
            'Report Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Live progression from Firestore event log records.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryChip(label: 'Total', value: total.toString()),
              _SummaryChip(label: 'In Use', value: inUse.toString()),
              _SummaryChip(label: 'Returned', value: returned.toString()),
              _SummaryChip(label: 'Lost', value: lost.toString()),
              _SummaryChip(label: 'No Return', value: noReturn.toString()),
              _SummaryChip(label: 'At Maintenance', value: maintenance.toString()),
              _SummaryChip(label: 'Hand Over', value: handOver.toString()),
              _SummaryChip(label: 'Damaged', value: damaged.toString()),
              _SummaryChip(label: 'Replaced', value: replaced.toString()),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Latest update: $latestAction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  List<EventLog> _filterEvents(List<EventLog> events) {
    final query = _searchController.text.trim().toLowerCase();
    return events.where((event) {
      if (_statusFilter != 'All') {
        final statusMatch = _matchesStatusFilter(event);
        if (!statusMatch) return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final tokens = <String>[
        event.action,
        event.keyId,
        event.keyName,
        event.borrowerName,
        event.icPassport,
        event.company,
        event.purpose,
        _formatDateTime(event.dateTimeTaken),
        event.dateTimeReturned == null ? '' : _formatDateTime(event.dateTimeReturned!),
      ];
      return tokens.any((token) => token.toLowerCase().contains(query));
    }).toList();
  }

  bool _matchesStatusFilter(EventLog event) {
    switch (_statusFilter) {
      case 'Still Out':
        return event.status == 'In Use' ||
            event.status == 'No Return' ||
            event.status == 'At Maintenance';
      case 'In Use':
        return event.status == 'In Use';
      case 'Returned':
        return event.status == 'Returned';
      case 'Lost':
        return event.status == 'Lost';
      case 'No Return':
        return event.status == 'No Return';
      case 'At Maintenance':
        return event.status == 'At Maintenance';
      case 'Hand Over':
        return event.status == 'Hand Over';
      case 'Damaged':
        return event.status == 'Damaged';
      case 'Replaced':
        return event.status == 'Replaced';
      case 'New Key Registered':
        return event.action == 'New Key Registered';
      default:
        return true;
    }
  }

  List<EventLog> _sortEvents(List<EventLog> events) {
    if (_sortColumnIndex == null) {
      return events;
    }

    final sorted = List<EventLog>.from(events);
    sorted.sort((a, b) {
      int compare;
      switch (_sortColumnIndex) {
        case 0:
          compare = a.keyId.compareTo(b.keyId);
          break;
        case 1:
          compare = a.borrowerName.compareTo(b.borrowerName);
          break;
        case 2:
          compare = a.icPassport.compareTo(b.icPassport);
          break;
        case 3:
          compare = a.phoneNumber.compareTo(b.phoneNumber);
          break;
        case 4:
          compare = a.company.compareTo(b.company);
          break;
        case 5:
          compare = a.purpose.compareTo(b.purpose);
          break;
        case 6:
          compare = a.dateTimeTaken.compareTo(b.dateTimeTaken);
          break;
        case 7:
          compare = _safeDateTime(a.dateTimeReturned).compareTo(_safeDateTime(b.dateTimeReturned));
          break;
        case 8:
          compare = a.lose.toString().compareTo(b.lose.toString());
          break;
        case 9:
          compare = a.actor.compareTo(b.actor);
          break;
        default:
          compare = 0;
      }
      return _sortAscending ? compare : -compare;
    });
    return sorted;
  }

  DateTime _safeDateTime(DateTime? value) => value ?? DateTime.fromMillisecondsSinceEpoch(0);

  Widget _buildPaginatedTable(List<EventLog> events) {
    final columns = [
      _buildColumn('Key', 0),
      _buildColumn('Name', 1),
      _buildColumn('I/C', 2),
      _buildColumn('Phone No', 3),
      _buildColumn('Company', 4),
      _buildColumn('Purpose', 5),
      _buildColumn('Taken', 6),
      _buildColumn('Returned', 7),
      _buildColumn('Lose', 8),
      _buildColumn('Actor', 9),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1200),
        child: PaginatedDataTable(
          header: const Text('Filtered Event Log'),
          columns: columns,
          source: EventLogDataSource(events, _formatDateTime),
          rowsPerPage: _rowsPerPage,
          availableRowsPerPage: const [5, 10, 15, 20],
          onRowsPerPageChanged: (value) {
            if (value == null) return;
            setState(() => _rowsPerPage = value);
          },
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          showCheckboxColumn: false,
        ),
      ),
    );
  }

  DataColumn _buildColumn(String label, int columnIndex) {
    return DataColumn(
      label: Text(label),
      onSort: (index, ascending) => setState(() {
        _sortColumnIndex = columnIndex;
        _sortAscending = ascending;
      }),
    );
  }

  Future<void> _exportCsv() async {
    final events = _filterEvents(_latestEvents);
    final csvBuffer = StringBuffer();
    csvBuffer.writeln(
      'Key,Name,I/C,Phone No,Company,Purpose,Date/Time Taken,Date/Time Returned,Lose,Actor',
    );
    for (final event in _sortEvents(events)) {
      final row = [
        event.keyId,
        event.borrowerName,
        event.icPassport,
        event.phoneNumber,
        event.company,
        event.purpose,
        _formatDateTime(event.dateTimeTaken),
        event.dateTimeReturned == null ? '' : _formatDateTime(event.dateTimeReturned!),
        event.lose ? 'Yes' : 'No',
        event.actor,
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

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  String _formatDateTime(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class EventLogDataSource extends DataTableSource {
  EventLogDataSource(this.events, this.formatDateTime);

  final List<EventLog> events;
  final String Function(DateTime) formatDateTime;

  @override
  DataRow getRow(int index) {
    final event = events[index];
    return DataRow(cells: [
      DataCell(Text(event.keyId)),
      DataCell(Text(event.borrowerName)),
      DataCell(Text(event.icPassport)),
      DataCell(Text(event.phoneNumber)),
      DataCell(Text(event.company)),
      DataCell(Text(event.purpose)),
      DataCell(Text(formatDateTime(event.dateTimeTaken))),
      DataCell(Text(event.dateTimeReturned == null ? '-' : formatDateTime(event.dateTimeReturned!))),
      DataCell(Text(event.lose ? 'Yes' : 'No')),
      DataCell(Text(event.actor)),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => events.length;

  @override
  int get selectedRowCount => 0;
}
