import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:public_file_saver/public_file_saver.dart';

import '../../core/app_action_theme.dart';
import '../../services/auth_service.dart';
import '../../services/key_repository.dart';
import '../../widget/beautiful_submit_button.dart';

class ReceivedKeyScreen extends StatefulWidget {
  const ReceivedKeyScreen({super.key});

  @override
  State<ReceivedKeyScreen> createState() => _ReceivedKeyScreenState();
}

class _ReceivedKeyScreenState extends State<ReceivedKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _receivedFromController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _witnessByController = TextEditingController();
  final _documentNoController = TextEditingController();
  String _selectedLevel = 'All';
  String? _selectedKeyId;
  bool _isExporting = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _receivedByController.text = AuthService.activeUser;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _receivedFromController.dispose();
    _receivedByController.dispose();
    _witnessByController.dispose();
    _documentNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Received Key'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isExporting ? null : _exportExcel,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download),
            tooltip: 'Download Excel',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: _buildFormCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Form(
        key: _formKey,
        child: StreamBuilder<List<KeyRecord>>(
          stream: KeyRecordRepository.watchAllKeys(),
          builder: (context, snapshot) {
            final allKeys = snapshot.data ?? const [];
            final receivableKeys = allKeys
                .where((key) => key.status == 'Hand Over' || key.status == 'In Use')
                .toList(growable: false)
              ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

            if (_selectedKeyId != null && receivableKeys.every((key) => key.keyId != _selectedKeyId)) {
              _selectedKeyId = null;
            }

            final levelOptions = _buildLevelOptions(receivableKeys);
            if (!levelOptions.contains(_selectedLevel)) {
              _selectedLevel = 'All';
            }

            final filteredKeys = receivableKeys.where((key) {
              final levelMatches = _selectedLevel == 'All' || _resolveLevel(key) == _selectedLevel;
              final searchMatches = _matchesSearch(key, _searchController.text.trim());
              return levelMatches && searchMatches;
            }).toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: _inputDecoration('Level', Icons.stairs_outlined),
                  items: levelOptions
                      .map((level) => DropdownMenuItem(value: level, child: Text(_levelDisplayLabel(level))))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedLevel = value);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        decoration: _inputDecoration('Search key', Icons.search),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(100, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppActionTheme.buttonRadius),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedKeyId == null ? 'No key selected yet.' : 'Selected key: $_selectedKeyId',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E5E8)),
                  ),
                  child: filteredKeys.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No keys found for selected level/search.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredKeys.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final key = filteredKeys[index];
                            final selected = key.keyId == _selectedKeyId;
                            return ListTile(
                              dense: true,
                              title: Text('${_resolveLevel(key)} • ${key.keyId}'),
                              subtitle: Text(key.keyName),
                              trailing: IconButton(
                                tooltip: 'Add key',
                                onPressed: () {
                                  setState(() {
                                    _selectedKeyId = key.keyId;
                                    if (_receivedFromController.text.trim().isEmpty) {
                                      _receivedFromController.text = key.borrowerName;
                                    }
                                  });
                                },
                                icon: Icon(
                                  selected ? Icons.check_circle : Icons.add_circle_outline,
                                  color: selected ? const Color(0xFF2E7D32) : null,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _receivedFromController,
                  decoration: _inputDecoration('Received from', Icons.person_outline),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _receivedByController,
                  decoration: _inputDecoration('Received by', Icons.person_add_alt_1_outlined),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _witnessByController,
                  decoration: _inputDecoration('Withness by', Icons.groups_outlined),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _documentNoController,
                  decoration: _inputDecoration('Document No.', Icons.receipt_long),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                BeautifulSubmitButton(
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                  idleLabel: 'Save Received Key',
                  loadingLabel: 'Saving received key...',
                  icon: Icons.assignment_turned_in_outlined,
                  backgroundColor: AppActionTheme.success,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final key = await _resolveSelectedReceivableKey();
    if (key == null) {
      _showMessage('Please add/select a key first.');
      return;
    }

    final actor = AuthService.activeUser;
    setState(() => _isSubmitting = true);
    try {
      await KeyRecordRepository.receiveKeyWithDetails(
        key,
        actor: actor,
        metadata: {
          'receivedFrom': _receivedFromController.text.trim(),
          'receivedBy': _receivedByController.text.trim(),
          'withnessBy': _witnessByController.text.trim(),
          'documentNo': _documentNoController.text.trim(),
        },
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Failed to save received key: $error');
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) {
      return;
    }

    _witnessByController.clear();
    _documentNoController.clear();
    _showMessage('Received key saved.');
  }

  Future<KeyRecord?> _resolveSelectedReceivableKey() async {
    final selectedKeyId = _selectedKeyId;
    if (selectedKeyId == null || selectedKeyId.isEmpty) {
      return null;
    }

    final keys = await KeyRecordRepository.watchAllKeys().first;
    final eligible = keys
        .where(
          (key) =>
              (key.status == 'Hand Over' || key.status == 'In Use') &&
              key.keyId == selectedKeyId,
        )
        .toList(growable: false);
    if (eligible.isEmpty) {
      return null;
    }
    return eligible.first;
  }

  List<String> _buildLevelOptions(List<KeyRecord> keys) {
    final levels = <String>{'All'};
    for (final key in keys) {
      levels.add(_resolveLevel(key));
    }
    final sorted = levels.toList(growable: false);
    sorted.sort((a, b) {
      if (a == 'All') {
        return -1;
      }
      if (b == 'All') {
        return 1;
      }
      return a.compareTo(b);
    });
    return sorted;
  }

  String _resolveLevel(KeyRecord key) {
    final metadataLevel = key.metadata['level']?.toString().trim() ?? '';
    if (metadataLevel.isNotEmpty) {
      return metadataLevel;
    }

    final zone = key.zone.toUpperCase();
    final match = RegExp(r'B2|B1|L\d{1,2}|LEVEL\s*\d{1,2}').firstMatch(zone);
    if (match == null) {
      return 'Unknown';
    }

    final raw = match.group(0) ?? 'Unknown';
    return raw.replaceAll('LEVEL ', 'L');
  }
  
  String _levelDisplayLabel(String level) {
    if (level == 'B2' || level == 'B1') {
      return 'Level $level';
    }
    return level;
  }

  bool _matchesSearch(KeyRecord key, String query) {
    if (query.isEmpty) {
      return true;
    }

    final normalized = query.toLowerCase();
    final level = _resolveLevel(key).toLowerCase();
    return key.keyId.toLowerCase().contains(normalized) ||
        key.keyName.toLowerCase().contains(normalized) ||
        key.zone.toLowerCase().contains(normalized) ||
        level.contains(normalized);
  }

  List<EventLog> _receivedEvents(List<EventLog> events) {
    final filtered = events.where((event) => event.action == 'Receive Key').toList();
    filtered.sort((a, b) => b.dateTimeTaken.compareTo(a.dateTimeTaken));
    return filtered;
  }

  Future<void> _exportExcel() async {
    if (_isExporting) {
      return;
    }

    setState(() => _isExporting = true);
    try {
      final events = _receivedEvents(await KeyRecordRepository.watchEventLogs().first);
      final workbook = xls.Excel.createExcel();
      final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
      workbook.rename(sheetName, 'Received Key');
      workbook.appendRow(
        'Received Key',
        <xls.CellValue>[
          xls.TextCellValue('Key ID'),
          xls.TextCellValue('Key Name'),
          xls.TextCellValue('Received from'),
          xls.TextCellValue('Received by'),
          xls.TextCellValue('Withness by'),
          xls.TextCellValue('Document No.'),
          xls.TextCellValue('Date Time'),
        ],
      );

      for (final event in events) {
        workbook.appendRow(
          'Received Key',
          <xls.CellValue>[
            xls.TextCellValue(event.keyId),
            xls.TextCellValue(event.keyName),
            xls.TextCellValue(event.metadata['receivedFrom']?.toString() ?? ''),
            xls.TextCellValue(event.metadata['receivedBy']?.toString() ?? ''),
            xls.TextCellValue(event.metadata['withnessBy']?.toString() ?? ''),
            xls.TextCellValue(event.metadata['documentNo']?.toString() ?? ''),
            xls.TextCellValue(_formatDateTime(event.dateTimeTaken)),
          ],
        );
      }

      final bytes = workbook.encode();
      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }
      final filename = 'received_key_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final fileBytes = Uint8List.fromList(bytes);

      if (Platform.isAndroid) {
        final result = await PublicFileSaver().saveBytes(
          bytes: fileBytes,
          fileName: filename,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        if (result == null || !result.isSuccess) {
          throw Exception('Failed to save Excel file to Downloads');
        }
      } else if (Platform.isIOS) {
        final result = await PublicFileSaver().saveBytesWithDialog(
          bytes: fileBytes,
          fileName: filename,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        if (result == null || !result.isSuccess) {
          throw Exception('Failed to save Excel file');
        }
      } else {
        final directory = await _resolveExportDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(fileBytes);
      }

      if (!mounted) {
        return;
      }
      _showMessage('Excel downloaded successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Export failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime value) {
    return '${_formatDate(value)} ${_formatTime(value)}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
