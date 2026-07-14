import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:public_file_saver/public_file_saver.dart';

import '../../services/key_repository.dart';

class _ExportTransactionRow {
  _ExportTransactionRow({
    required this.date,
    required this.borrowerName,
    required this.icPassport,
    required this.phoneNumber,
    required this.departmentCompany,
    required this.staffFrom,
    required this.keyName,
    required this.purpose,
    required this.takenAt,
  });

  final DateTime date;
  final String borrowerName;
  final String icPassport;
  final String phoneNumber;
  final String departmentCompany;
  final String staffFrom;
  final String keyName;
  final String purpose;
  final DateTime? takenAt;
  DateTime? returnedAt;
}

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
  bool _isExporting = false;

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
            onPressed: _refreshLogs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from Firestore',
          ),
          IconButton(
            onPressed: _isExporting ? null : _exportExcel,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            tooltip: 'Export Excel',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<List<EventLog>>(
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
            if (_isExporting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Downloading record...',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please wait while the Excel file is prepared and saved.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.4,
                ),
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
                      height: 1.4,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportExcel() async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await KeyRecordRepository.refreshEventLogsFromFirestore();
      if (!mounted) return;
    } catch (_) {
      // Keep exporting from the latest cached data when refresh fails.
    }

    final latestFromRepository = await KeyRecordRepository.watchEventLogs().first;
    if (!mounted) return;

    final events = _sortEvents(_filterEvents(latestFromRepository));
    final exportRows = _buildExportRows(events);
    final workbook = xls.Excel.createExcel();
    final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
    workbook.rename(sheetName, 'Event Log');
    workbook.appendRow(
      'Event Log',
      <xls.CellValue>[
        xls.TextCellValue('Name Borrower'),
        xls.TextCellValue('IC/Passport No.'),
        xls.TextCellValue('Phone No.'),
        xls.TextCellValue('Company / Department'),
        xls.TextCellValue('Staff From'),
        xls.TextCellValue('Keys'),
        xls.TextCellValue('Purpose'),
        xls.TextCellValue('In Use Time'),
        xls.TextCellValue('Date Taken'),
        xls.TextCellValue('Returned Time'),
        xls.TextCellValue('Date Returned'),
      ],
    );

    for (final rowData in exportRows) {
      workbook.appendRow(
        'Event Log',
        <xls.CellValue>[
          xls.TextCellValue(rowData.borrowerName),
          xls.TextCellValue(rowData.icPassport),
          xls.TextCellValue(rowData.phoneNumber),
          xls.TextCellValue(rowData.departmentCompany),
          xls.TextCellValue(rowData.staffFrom),
          xls.TextCellValue(rowData.keyName),
          xls.TextCellValue(rowData.purpose),
          xls.TextCellValue(rowData.takenAt == null ? '' : _formatTime(rowData.takenAt!)),
          xls.TextCellValue(rowData.takenAt == null ? '' : _formatDate(rowData.takenAt!)),
          xls.TextCellValue(rowData.returnedAt == null ? '' : _formatTime(rowData.returnedAt!)),
          xls.TextCellValue(rowData.returnedAt == null ? '' : _formatDate(rowData.returnedAt!)),
        ],
      );
    }

    try {
      final filename = 'event_log_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final workbookBytes = workbook.encode();
      if (workbookBytes == null) {
        throw Exception('Failed to generate Excel file');
      }
      final fileBytes = Uint8List.fromList(workbookBytes);
      if (Platform.isAndroid) {
        final result = await PublicFileSaver().saveBytes(
          bytes: fileBytes,
          fileName: filename,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        if (result == null || !result.isSuccess) {
          throw Exception('Failed to save Excel file to Downloads');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file saved to Downloads.')),
        );
        return;
      }

      if (Platform.isIOS) {
        final result = await PublicFileSaver().saveBytesWithDialog(
          bytes: fileBytes,
          fileName: filename,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        if (result == null || !result.isSuccess) {
          throw Exception('Failed to save Excel file');
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file saved successfully.')),
        );
        return;
      }

      final directory = await _resolveExportDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(fileBytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel exported to ${file.path}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<Directory> _resolveExportDirectory() async {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory != null) {
        return downloadsDirectory;
      }
    }

    return getApplicationDocumentsDirectory();
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
          content: Text(
            'Remove ${filtered.length} filtered log(s) from this app only?',
          ),
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
        SnackBar(content: Text('${filtered.length} filtered log(s) removed from app.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clear filtered logs failed: $error')),
      );
    }
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

  List<_ExportTransactionRow> _buildExportRows(List<EventLog> events) {
    final orderedEvents = List<EventLog>.from(events)
      ..sort((a, b) => a.dateTimeTaken.compareTo(b.dateTimeTaken));
    final rows = <_ExportTransactionRow>[];
    final rowsByTransaction = <String, _ExportTransactionRow>{};
    final openRowsByBaseKey = <String, List<_ExportTransactionRow>>{};

    for (final event in orderedEvents) {
      if (_isReturnEvent(event)) {
        final baseKey = _exportBaseKey(event);
        final candidates = openRowsByBaseKey[baseKey];
        var matchedCandidate = false;
        if (candidates != null) {
          for (var index = candidates.length - 1; index >= 0; index -= 1) {
            final candidate = candidates[index];
            final takenAt = candidate.takenAt;
            if (candidate.returnedAt != null) {
              continue;
            }
            if (takenAt != null && takenAt.isAfter(event.dateTimeReturned ?? event.dateTimeTaken)) {
              continue;
            }
            candidate.returnedAt = event.dateTimeReturned ?? event.dateTimeTaken;
            matchedCandidate = true;
            break;
          }
        }

        if (!matchedCandidate && _hasExportIdentity(event)) {
          rows.add(_createExportRow(event, takenAt: null, returnedAt: event.dateTimeReturned ?? event.dateTimeTaken));
        }
        continue;
      }

      if (!_shouldExportEvent(event)) {
        continue;
      }

      final transactionKey = _exportTransactionKey(event);
      final existingRow = rowsByTransaction[transactionKey];
      if (existingRow != null) {
        continue;
      }

      final row = _createExportRow(event, takenAt: event.dateTimeTaken);
      rowsByTransaction[transactionKey] = row;
      rows.add(row);

      openRowsByBaseKey.putIfAbsent(_exportBaseKey(event), () => <_ExportTransactionRow>[]).add(row);
    }

    return rows.reversed.toList();
  }

  bool _shouldExportEvent(EventLog event) {
    return !_isReturnEvent(event) && _hasExportIdentity(event);
  }

  bool _isReturnEvent(EventLog event) {
    return event.action == 'Returned' || event.status == 'Returned';
  }

  String _exportBaseKey(EventLog event) {
    return [
      event.keyId.trim(),
      _displayKey(event).trim(),
      event.borrowerName.trim(),
      event.icPassport.trim(),
      event.phoneNumber.trim(),
      event.company.trim(),
      event.purpose.trim(),
    ].join('|');
  }

  String _exportTransactionKey(EventLog event) {
    return '${_exportBaseKey(event)}|${event.dateTimeTaken.toIso8601String()}';
  }

  bool _hasExportIdentity(EventLog event) {
    return event.borrowerName.trim().isNotEmpty && _displayKey(event).trim().isNotEmpty;
  }

  _ExportTransactionRow _createExportRow(
    EventLog event, {
    required DateTime? takenAt,
    DateTime? returnedAt,
  }) {
    final effectiveDate = returnedAt ?? takenAt ?? event.dateTimeReturned ?? event.dateTimeTaken;
    final row = _ExportTransactionRow(
      date: effectiveDate,
      borrowerName: event.borrowerName,
      icPassport: _exportIcPassport(event),
      phoneNumber: event.phoneNumber,
      departmentCompany: _departmentCompany(event),
      staffFrom: _staffFromForExport(event),
      keyName: _keyForTable(event),
      purpose: _purposeForExport(event),
      takenAt: takenAt,
    );
    row.returnedAt = returnedAt;
    return row;
  }

  String _exportIcPassport(EventLog event) {
    final borrowerCategory = event.metadata['borrowerCategory']?.toString().trim().toLowerCase() ?? '';
    final icPassport = event.icPassport.trim();

    if (borrowerCategory == 'staff') {
      return 'staff';
    }

    return icPassport;
  }

  String _purposeForExport(EventLog event) {
    final purposeFromMetadata = event.metadata['purpose']?.toString().trim() ?? '';
    if (purposeFromMetadata.isNotEmpty) {
      return purposeFromMetadata;
    }

    return event.purpose.trim();
  }

  String _departmentCompany(EventLog event) {
    final borrowerCategory = event.metadata['borrowerCategory']?.toString().trim().toLowerCase() ?? '';
    final department = event.metadata['department']?.toString().trim() ?? '';
    final company = event.company.trim();

    if (borrowerCategory == 'staff') {
      return department.isNotEmpty ? 'Department $department' : 'Department';
    }

    if (company.isNotEmpty) {
      return 'Company $company';
    }

    return department.isNotEmpty ? 'Department $department' : '';
  }

  String _staffFromForExport(EventLog event) {
    final staffFrom = event.staffFrom.trim();
    if (staffFrom.isNotEmpty) {
      return staffFrom;
    }

    return event.metadata['staffFrom']?.toString().trim() ?? '';
  }

  String _keyForTable(EventLog event) {
    final category = event.category.trim().toLowerCase();
    final level = event.metadata['level']?.toString().trim() ?? '';
    final zone = event.metadata['zone']?.toString().trim() ?? '';
    final rollerNo = event.metadata['rollerNumber']?.toString().trim() ?? '';
    final lotNo = event.metadata['lotKey']?.toString().trim() ?? '';
    final masterKey = event.metadata['masterKey']?.toString().trim() ?? '';
    final keyName = event.keyName.trim();

    if (category == 'zone') {
      return _joinLevelWithValue(level, zone);
    }

    if (category == 'roller shutter') {
      var normalizedLevel = level;
      var normalizedRollerNo = rollerNo;
      final rollerLevelNo = event.metadata['rollerLevelNo']?.toString().trim() ?? '';
      if ((normalizedLevel.isEmpty || normalizedRollerNo.isEmpty) && rollerLevelNo.contains('/')) {
        final parts = rollerLevelNo.split('/');
        if (parts.isNotEmpty && normalizedLevel.isEmpty) {
          normalizedLevel = parts.first.trim();
        }
        if (parts.length > 1 && normalizedRollerNo.isEmpty) {
          normalizedRollerNo = parts[1].trim();
        }
      }
      return _joinLevelWithValue(normalizedLevel, normalizedRollerNo);
    }

    if (category == 'master key') {
      final masterKeyValue = masterKey.isNotEmpty ? masterKey : keyName;
      return _joinLevelWithValue(level, masterKeyValue);
    }

    if (category == 'lot') {
      final lotValue = lotNo.isNotEmpty ? lotNo : keyName;
      return _joinLevelWithValue(level, lotValue);
    }

    if (category == 'high risk' || category == 'others') {
      return _joinLevelWithValue(level, keyName);
    }

    return _displayKey(event);
  }

  String _joinLevelWithValue(String level, String value) {
    final safeLevel = level.trim();
    final safeValue = value.trim();
    if (safeLevel.isNotEmpty && safeValue.isNotEmpty) {
      return '$safeLevel/$safeValue';
    }
    if (safeValue.isNotEmpty) {
      return safeValue;
    }
    return safeLevel;
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
    final key = _keyForTable(event).trim().isEmpty ? _displayKey(event) : _keyForTable(event);
    final actor = event.actor.trim().isEmpty ? 'member' : event.actor;

    if (event.action == 'New Key Registered') {
      return 'New key registered by "$actor": $key.';
    }

    if (event.status == 'In Use' || event.action.contains('Taken')) {
      final borrower = event.borrowerName.trim().isEmpty ? 'member' : event.borrowerName;
      final takenKey = _takenKeyLabel(event, fallback: key);
      final purpose = _takenPurpose(event);
      return 'key $takenKey has been taken by "$borrower"\npurpose for : $purpose';
    }

    if (event.status == 'Lost' || event.action == 'Lost') {
      return 'Key $key has been marked as Lost.';
    }

    if (event.status == 'Returned' || event.action == 'Returned') {
      return 'Key $key has been returned.';
    }

    return '${event.action}: key $key by "$actor".';
  }

  String _takenKeyLabel(EventLog event, {required String fallback}) {
    final level = event.metadata['level']?.toString().trim() ?? '';
    final zone = event.metadata['zone']?.toString().trim() ?? '';
    if (level.isNotEmpty && zone.isNotEmpty) {
      return _joinLevelWithValue(level, zone);
    }

    final parsedFromKeyId = _parseZoneFromLegacyKeyId(event.keyId);
    if (parsedFromKeyId != null) {
      return parsedFromKeyId;
    }

    final parsedFromDisplay = _parseLevelZonePair(event.keyName);
    if (parsedFromDisplay != null) {
      return parsedFromDisplay;
    }

    final fallbackFromDisplay = _parseLevelZonePair(fallback);
    if (fallbackFromDisplay != null) {
      return fallbackFromDisplay;
    }

    return event.keyName.trim().isNotEmpty ? event.keyName.trim() : fallback;
  }

  String? _parseZoneFromLegacyKeyId(String keyId) {
    final normalized = keyId.trim();
    if (!normalized.toUpperCase().startsWith('ZONE-')) {
      return null;
    }

    final remainder = normalized.substring(5);
    if (remainder.isEmpty) {
      return null;
    }

    final parts = remainder.split('-').where((part) => part.trim().isNotEmpty).toList();
    if (parts.length < 2) {
      return null;
    }

    final level = parts.first.trim();
    final zone = parts[1].trim();
    if (level.isEmpty || zone.isEmpty) {
      return null;
    }

    return '$level/$zone';
  }

  String? _parseLevelZonePair(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (!normalized.contains('/')) {
      return null;
    }

    final parts = normalized.split('/');
    if (parts.length < 2) {
      return null;
    }

    final level = parts[0].trim();
    final zone = parts[1].trim();
    if (level.isEmpty || zone.isEmpty) {
      return null;
    }

    return '$level/$zone';
  }

  String _takenPurpose(EventLog event) {
    final purposeFromMetadata = event.metadata['purpose']?.toString().trim() ?? '';
    if (purposeFromMetadata.isNotEmpty) {
      return purposeFromMetadata;
    }

    final purpose = event.purpose.trim();
    if (purpose.isNotEmpty) {
      return purpose;
    }

    return 'N/A';
  }
}
