import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:public_file_saver/public_file_saver.dart';

import '../../services/auth_service.dart';
import '../../services/key_repository.dart';
import '../../core/app_action_theme.dart';
import '../../widget/beautiful_submit_button.dart';

class HandOverKeyScreen extends StatefulWidget {
  const HandOverKeyScreen({super.key});

  @override
  State<HandOverKeyScreen> createState() => _HandOverKeyScreenState();
}

class _HandOverKeyScreenState extends State<HandOverKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNoController = TextEditingController();
  final _handoverByController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _witnessesByController = TextEditingController();
  final List<_HandOverKeySelectionRow> _keyRows = [];
  bool _isExporting = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _handoverByController.text = AuthService.activeUser;
    _keyRows.add(_HandOverKeySelectionRow());
  }

  @override
  void dispose() {
    _documentNoController.dispose();
    _handoverByController.dispose();
    _receivedByController.dispose();
    _witnessesByController.dispose();
    for (final row in _keyRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Hand Over Key'),
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
            child: Column(
              children: [
                _buildFormCard(),
                const SizedBox(height: 12),
                _buildAllRecordsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllRecordsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: StreamBuilder<List<KeyRecord>>(
        stream: KeyRecordRepository.watchAllKeys(),
        builder: (context, snapshot) {
          final records = List<KeyRecord>.from(snapshot.data ?? const [])
            ..sort((a, b) {
              final byLabel = _naturalCompare(_keyListLabel(a), _keyListLabel(b));
              if (byLabel != 0) {
                return byLabel;
              }
              return _naturalCompare(a.keyId, b.keyId);
            });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All records',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting && records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No records found.'),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: records.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          _keyListLabel(record),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _keyListSubtitle(record),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _StatusPill(status: record.status),
                      );
                    },
                  ),
                ),
            ],
          );
        },
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
            final selectableKeys = List<KeyRecord>.from(allKeys)
              ..sort((a, b) {
                final byLabel = _naturalCompare(_keyListLabel(a), _keyListLabel(b));
                if (byLabel != 0) {
                  return byLabel;
                }
                return _naturalCompare(a.keyId, b.keyId);
              });

            for (final row in _keyRows) {
              if (row.selectedKeyId != null && selectableKeys.every((key) => key.keyId != row.selectedKeyId)) {
                row.selectedKeyId = null;
                row.displayController.clear();
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 8,
                  spacing: 8,
                  children: [
                    Text(
                      'List key',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addEmptyKeyRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add key selected'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppActionTheme.buttonRadius),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_keyRows.length, (index) {
                  final row = _keyRows[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: row.displayController,
                            readOnly: true,
                            decoration: _inputDecoration('Key selected', Icons.vpn_key).copyWith(
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            onTap: () => _openKeyPicker(
                              row: row,
                              selectableKeys: selectableKeys,
                            ),
                            validator: (_) {
                              if (row.selectedKeyId == null || row.selectedKeyId!.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 110,
                          child: TextFormField(
                            controller: row.qtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: _inputDecoration('Qty key', Icons.numbers),
                            validator: _qtyValidator,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Remove row',
                          onPressed: _keyRows.length == 1
                              ? null
                              : () {
                                  setState(() {
                                    final removed = _keyRows.removeAt(index);
                                    removed.dispose();
                                  });
                                },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _documentNoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: _inputDecoration('Document No.', Icons.receipt_long),
                  validator: _documentNoValidator,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _handoverByController,
                  readOnly: true,
                  decoration: _inputDecoration('Handover by', Icons.person_outline),
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
                  controller: _witnessesByController,
                  decoration: _inputDecoration('Witnesses by', Icons.groups_outlined),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                BeautifulSubmitButton(
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                  idleLabel: 'Submit',
                  loadingLabel: 'Saving handover...',
                  icon: Icons.save_outlined,
                  backgroundColor: AppActionTheme.info,
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

    final selectedItems = await _resolveSelectedItems();
    if (selectedItems.isEmpty) {
      _showMessage('Please add/select a key first.');
      return;
    }

    if (!mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Confirm Hand Over'),
              content: Text('Submit hand over for ${selectedItems.length} selected key(s)?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(98, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppActionTheme.buttonRadius),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _isSubmitting = true);
    final actor = AuthService.activeUser;
    final now = DateTime.now();
    try {
      for (final item in selectedItems) {
        await KeyRecordRepository.markHandOverWithDetails(
          item.key,
          actor: actor,
          metadata: {
            'documentReportNo': _documentNoController.text.trim(),
            'qtyKey': item.qtyKey,
            'handoverBy': _handoverByController.text.trim(),
            'receivedBy': _receivedByController.text.trim(),
            'witnessesBy': _witnessesByController.text.trim(),
            'handoverDate': _formatDate(now),
            'handoverTime': _formatTime(now),
          },
        );
      }

      try {
        await KeyRecordRepository.refreshKeysFromFirestore();
      } catch (_) {
        // Keep local update if Firestore refresh fails.
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Failed to save hand over: $error');
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

    _documentNoController.clear();
    _receivedByController.clear();
    _witnessesByController.clear();
    setState(() {
      for (final row in _keyRows) {
        row.dispose();
      }
      _keyRows
        ..clear()
        ..add(_HandOverKeySelectionRow());
    });
    _showMessage('Hand over saved for ${selectedItems.length} key(s).');
  }

  Future<List<_SelectedHandOverItem>> _resolveSelectedItems() async {
    final selectedRows = _keyRows
        .where((row) => (row.selectedKeyId?.trim().isNotEmpty ?? false))
        .toList(growable: false);
    if (selectedRows.isEmpty) {
      return const <_SelectedHandOverItem>[];
    }

    final selectedIds = selectedRows
        .map((row) => row.selectedKeyId!.trim())
        .toSet();

    final keys = await KeyRecordRepository.watchAllKeys().first;
    final keyById = <String, KeyRecord>{
      for (final key in keys)
        key.keyId: key,
    };

    final selectedItems = <_SelectedHandOverItem>[];
    for (final row in selectedRows) {
      final keyId = row.selectedKeyId!.trim();
      if (!selectedIds.contains(keyId)) {
        continue;
      }
      final key = keyById[keyId];
      if (key == null) {
        continue;
      }
      selectedItems.add(
        _SelectedHandOverItem(
          key: key,
          qtyKey: row.qtyController.text.trim(),
        ),
      );
    }

    return selectedItems;
  }

  void _addEmptyKeyRow() {
    setState(() {
      _keyRows.add(_HandOverKeySelectionRow());
    });
  }

  Future<void> _openKeyPicker({
    required _HandOverKeySelectionRow row,
    required List<KeyRecord> selectableKeys,
  }) async {
    var query = '';
    final selectedIds = _keyRows
        .map((item) => item.selectedKeyId)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = selectableKeys.where((key) {
              final selectedByAnotherRow =
                  selectedIds.contains(key.keyId) && key.keyId != row.selectedKeyId;
              if (selectedByAnotherRow) {
                return false;
              }
              if (query.isEmpty) {
                return true;
              }
              final normalized = query.toLowerCase();
              final searchable = _searchableKeyText(key);
              return searchable.contains(normalized);
            }).toList(growable: false);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Key',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: _inputDecoration('Search key', Icons.search),
                      onChanged: (value) => setModalState(() => query = value.trim()),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('No keys found.'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final key = filtered[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    _keyListLabel(key),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    _keyListSubtitle(key),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      row.selectedKeyId = key.keyId;
                                      row.displayController.text = _keyListLabel(key);
                                      if (row.qtyController.text.trim().isEmpty) {
                                        final fallbackQty = key.metadata['qty']?.toString().trim() ?? '';
                                        row.qtyController.text = fallbackQty.isEmpty ? '1' : fallbackQty;
                                      }
                                    });
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _searchableKeyText(KeyRecord key) {
    final metadata = key.metadata;
    final values = <String>[
      key.keyId,
      key.keyName,
      key.zone,
      key.category,
      key.status,
      metadata['level']?.toString() ?? '',
      metadata['zone']?.toString() ?? '',
      metadata['location']?.toString() ?? '',
      metadata['position']?.toString() ?? '',
      metadata['doorId']?.toString() ?? '',
      metadata['rollerNumber']?.toString() ?? '',
      metadata['rollerLevelNo']?.toString() ?? '',
      metadata['lotKey']?.toString() ?? '',
      metadata['masterKey']?.toString() ?? '',
      metadata['tenantName']?.toString() ?? '',
      metadata['frs']?.toString() ?? '',
      metadata['remarks']?.toString() ?? '',
    ];

    return values
        .where((value) => value.trim().isNotEmpty)
        .map((value) => value.toLowerCase())
        .join(' ');
  }

  String _keyListSubtitle(KeyRecord key) {
    final level = key.metadata['level']?.toString().trim() ?? '';
    final zone = (key.metadata['zone']?.toString().trim().isNotEmpty ?? false)
        ? key.metadata['zone'].toString().trim()
        : key.zone;
    final lotNo = key.metadata['lotKey']?.toString().trim() ?? '';
    final masterKey = key.metadata['masterKey']?.toString().trim() ?? '';
    final rollerNo = key.metadata['rollerNumber']?.toString().trim() ?? '';
    final name = key.keyName.trim();

    if (key.category == 'Zone') {
      final parts = <String>[];
      if (level.isNotEmpty) {
        parts.add(level);
      }
      if (zone.trim().isNotEmpty) {
        parts.add(zone);
      }
      return parts.isEmpty ? name : parts.join(' / ');
    }

    if (key.category == 'Master Key') {
      final parts = <String>[];
      if (level.isNotEmpty) {
        parts.add(level);
      }
      parts.add(masterKey.isNotEmpty ? masterKey : 'Master key');
      return parts.join(' / ');
    }

    if (key.category == 'Lot') {
      final parts = <String>[];
      if (level.isNotEmpty) {
        parts.add(level);
      }
      parts.add(lotNo.isNotEmpty ? lotNo : 'No. Lot Key');
      return parts.join(' / ');
    }

    if (key.category == 'Roller Shutter') {
      final parts = <String>[];
      if (level.isNotEmpty) {
        parts.add(level);
      }
      parts.add(rollerNo.isNotEmpty ? rollerNo : 'No. Roller shutter');
      return parts.join(' / ');
    }

    if (key.category == 'High Risk' || key.category == 'Others') {
      return '';
    }

    return name.isNotEmpty ? name : key.keyId;
  }

  String _keyListLabel(KeyRecord key) {
    final metadata = key.metadata;
    final candidates = <String>[
      metadata['lotKey']?.toString() ?? '',
      metadata['masterKey']?.toString() ?? '',
      metadata['rollerLevelNo']?.toString() ?? '',
      metadata['rollerNumber']?.toString() ?? '',
      metadata['position']?.toString() ?? '',
      metadata['doorId']?.toString() ?? '',
      key.keyName,
      key.keyId,
    ];

    final selected = candidates.firstWhere(
      (value) => value.trim().isNotEmpty,
      orElse: () => key.keyId,
    );
    return selected.trim().toUpperCase();
  }

  int _naturalCompare(String a, String b) {
    final partsA = _splitNaturalParts(a);
    final partsB = _splitNaturalParts(b);
    final minLength = partsA.length < partsB.length ? partsA.length : partsB.length;

    for (var i = 0; i < minLength; i++) {
      final left = partsA[i];
      final right = partsB[i];

      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      if (leftNumber != null && rightNumber != null) {
        final numberCompare = leftNumber.compareTo(rightNumber);
        if (numberCompare != 0) {
          return numberCompare;
        }
        continue;
      }

      final textCompare = left.toUpperCase().compareTo(right.toUpperCase());
      if (textCompare != 0) {
        return textCompare;
      }
    }

    return partsA.length.compareTo(partsB.length);
  }

  List<String> _splitNaturalParts(String input) {
    final matches = RegExp(r'\d+|[A-Za-z]+').allMatches(input);
    if (matches.isEmpty) {
      final fallback = input.trim();
      return fallback.isEmpty ? const <String>[] : <String>[fallback];
    }
    return matches.map((match) => match.group(0) ?? '').toList(growable: false);
  }

  List<EventLog> _handOverEvents(List<EventLog> events) {
    final filtered = events.where((event) {
      return event.status == 'Hand Over' ||
          event.action == 'Hand Over' ||
          event.action == 'Key Handed Over';
    }).toList();
    filtered.sort((a, b) => b.dateTimeTaken.compareTo(a.dateTimeTaken));
    return filtered;
  }

  Future<void> _exportExcel() async {
    if (_isExporting) {
      return;
    }

    setState(() => _isExporting = true);
    try {
      final events = _handOverEvents(await KeyRecordRepository.watchEventLogs().first);
      final workbook = xls.Excel.createExcel();
      final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';
      workbook.rename(sheetName, 'Hand Over Key');
      workbook.appendRow(
        'Hand Over Key',
        <xls.CellValue>[
          xls.TextCellValue('Key ID'),
          xls.TextCellValue('Key Name'),
          xls.TextCellValue('Document No.'),
          xls.TextCellValue('Handover by'),
          xls.TextCellValue('Received by'),
          xls.TextCellValue('Witnesses by'),
          xls.TextCellValue('Date Time'),
        ],
      );

      for (final event in events) {
        workbook.appendRow(
          'Hand Over Key',
          <xls.CellValue>[
            xls.TextCellValue(event.keyId),
            xls.TextCellValue(event.keyName),
            xls.TextCellValue(event.metadata['documentReportNo']?.toString() ?? ''),
            xls.TextCellValue(event.metadata['handoverBy']?.toString() ?? ''),
            xls.TextCellValue(event.metadata['receivedBy']?.toString() ?? ''),
            xls.TextCellValue(event.metadata['witnessesBy']?.toString() ?? ''),
            xls.TextCellValue(_formatDateTime(event.dateTimeTaken)),
          ],
        );
      }

      final bytes = workbook.encode();
      if (bytes == null) {
        throw Exception('Failed to generate Excel file');
      }
      final filename = 'hand_over_key_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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

  String? _documentNoValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Required';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(normalized)) {
      return 'Document No. must be exactly 4 digits';
    }
    return null;
  }

  String? _qtyValidator(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'Must be > 0';
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

class _HandOverKeySelectionRow {
  _HandOverKeySelectionRow()
      : displayController = TextEditingController(),
        qtyController = TextEditingController(text: '1');

  String? selectedKeyId;
  final TextEditingController displayController;
  final TextEditingController qtyController;

  void dispose() {
    displayController.dispose();
    qtyController.dispose();
  }
}

class _SelectedHandOverItem {
  const _SelectedHandOverItem({required this.key, required this.qtyKey});

  final KeyRecord key;
  final String qtyKey;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final isAvailable = normalized == 'available';
    final isHandOver = normalized == 'hand over';
    final background = isAvailable
        ? const Color(0xFFE7F5EA)
        : isHandOver
            ? const Color(0xFFE9EEF6)
            : const Color(0xFFFFF2E0);
    final foreground = isAvailable
        ? const Color(0xFF2E7D32)
        : isHandOver
            ? const Color(0xFF1E3A5F)
            : const Color(0xFFEF6C00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
