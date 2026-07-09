import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/key_repository.dart';
import '../event_log/event_log_screen.dart';
import '../register/register.dart';

class SmartDetailScreen extends StatefulWidget {
  const SmartDetailScreen({required this.record, super.key});

  final KeyRecord record;

  @override
  State<SmartDetailScreen> createState() => _SmartDetailScreenState();
}

class _SmartDetailScreenState extends State<SmartDetailScreen> {
  late KeyRecord _currentRecord;

  static const List<String> _statusOptions = [
    'Available',
    'In Use',
    'No Return',
    'At Maintenance',
    'Lost',
    'Hand Over',
    'Damaged',
    'Replaced',
    'High Risk',
  ];

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.record;
  }

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
                          _currentRecord.keyName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      _StatusTag(status: _currentRecord.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentRecord.zone,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  _ReadOnlyField(label: 'Key Name', value: _currentRecord.keyName),
                  _ReadOnlyField(label: 'Category', value: _currentRecord.category),
                  _ReadOnlyField(label: 'Location', value: _readMetadata('location')),
                  _ReadOnlyField(label: 'Level', value: _readMetadata('level')),
                  if (_currentRecord.category == 'Zone' || _currentRecord.category == 'Others')
                    _ReadOnlyField(label: 'Zone', value: _readMetadata('zone', fallback: _currentRecord.zone)),
                  if (_currentRecord.category == 'Master Key')
                    _ReadOnlyField(label: 'Master Key', value: _readMetadata('masterKey', fallback: _currentRecord.keyName)),
                  if (_currentRecord.category == 'Lot')
                    _ReadOnlyField(label: 'No. Lot Key', value: _readMetadata('lotKey', fallback: _currentRecord.keyName)),
                  if (_currentRecord.category == 'Roller Shutter') ...[
                    _ReadOnlyField(label: 'Level / No.', value: _readMetadata('rollerLevelNo')),
                    _ReadOnlyField(label: 'FRS', value: _readMetadata('frs')),
                    _ReadOnlyField(label: 'No. Roller Shutter', value: _readMetadata('rollerNumber')),
                  ],
                  _ReadOnlyField(label: 'Qty', value: _readMetadata('qty')),
                  if (_currentRecord.category != 'Roller Shutter')
                    _ReadOnlyField(label: 'Door ID', value: _readMetadata('doorId')),
                  _ReadOnlyField(label: 'Status', value: _currentRecord.status),
                  if (_currentRecord.status != 'Available' && _readMetadata('staffName').isNotEmpty)
                    _ReadOnlyField(label: 'Name Staff', value: _readMetadata('staffName')),
                  if (_currentRecord.status != 'Available' && _readMetadata('department').isNotEmpty)
                    _ReadOnlyField(label: 'Department', value: _readMetadata('department')),
                  if (_currentRecord.status != 'Available' && _readMetadata('tenantName').isNotEmpty)
                    _ReadOnlyField(label: 'Tenant\'s Name', value: _readMetadata('tenantName')),
                  if (_currentRecord.status != 'Available' && _readMetadata('purpose').isNotEmpty)
                    _ReadOnlyField(label: 'Purpose', value: _readMetadata('purpose')),
                  if (_currentRecord.status == 'Hand Over' && _readMetadata('documentReportNo').isNotEmpty)
                    _ReadOnlyField(label: 'Document report no.', value: _readMetadata('documentReportNo')),
                  if (_currentRecord.status == 'Hand Over' && _readMetadata('handoverBy').isNotEmpty)
                    _ReadOnlyField(label: 'Handover by', value: _readMetadata('handoverBy')),
                  if (_currentRecord.status == 'Hand Over' && _readMetadata('receivedBy').isNotEmpty)
                    _ReadOnlyField(label: 'Received by', value: _readMetadata('receivedBy')),
                  if (_currentRecord.status == 'Hand Over' && _readMetadata('witnessesBy').isNotEmpty)
                    _ReadOnlyField(label: 'Witnesses by', value: _readMetadata('witnessesBy')),
                  if (_currentRecord.status == 'Hand Over' && _readMetadata('handoverDate').isNotEmpty)
                    _ReadOnlyField(label: 'Handover date', value: _readMetadata('handoverDate')),
                  if (_currentRecord.status == 'Hand Over' && _readMetadata('handoverTime').isNotEmpty)
                    _ReadOnlyField(label: 'Handover time', value: _readMetadata('handoverTime')),
                  if (_readMetadata('date').isNotEmpty)
                    _ReadOnlyField(label: 'Date', value: _readMetadata('date')),
                  if (_readMetadata('time').isNotEmpty)
                    _ReadOnlyField(label: 'Time', value: _readMetadata('time')),
                  if (_readMetadata('remarks').isNotEmpty)
                    _ReadOnlyField(label: 'Remarks', value: _readMetadata('remarks')),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          await _openEditDialog(context);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Details'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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
                                builder: (_) => RegisterScreen(initialKeyId: _currentRecord.keyId),
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
                          if (value == 'Delete Key') {
                            await _confirmDeleteKey(context);
                            return;
                          }
                          await _handleAction(context, value);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Lost', child: Text('Lost')),
                          const PopupMenuItem(value: 'Replaced', child: Text('Replaced')),
                          if (_currentRecord.status == 'In Use')
                            const PopupMenuItem(value: 'Hand Over', child: Text('Hand Over')),
                          if (_currentRecord.status == 'Hand Over')
                            const PopupMenuItem(value: 'Receive Key', child: Text('Receive Key')),
                          const PopupMenuItem(value: 'Damaged', child: Text('Damaged')),
                          const PopupMenuItem(
                            value: 'Delete Key',
                            child: Text(
                              'Delete Key',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          if (_currentRecord.status == 'Lost')
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

  bool get _canAddKey => _currentRecord.status == 'Available';

  bool get _canReturn => _currentRecord.status == 'In Use' || _currentRecord.status == 'Hand Over';

  Future<void> _handleAction(BuildContext context, String action) async {
    if (action == 'Returned') {
      await KeyRecordRepository.returnKey(_currentRecord);
    } else if (action == 'Found') {
      await KeyRecordRepository.returnKey(_currentRecord);
    } else if (action == 'Lost') {
      await KeyRecordRepository.markLost(_currentRecord);
    } else if (action == 'Replaced') {
      await KeyRecordRepository.markReplaced(_currentRecord);
    } else if (action == 'Hand Over') {
      if (_currentRecord.status != 'In Use') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hand Over is only available for In Use keys.')),
          );
        }
        return;
      }
      final saved = await _openHandoverDialog(context);
      if (!saved) {
        return;
      }
    } else if (action == 'Receive Key') {
      if (_currentRecord.status != 'Hand Over') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receive Key is only available for Hand Over keys.')),
          );
        }
        return;
      }
      final saved = await _openReceiveKeyDialog(context);
      if (!saved) {
        return;
      }
    } else if (action == 'Damaged') {
      await KeyRecordRepository.markDamaged(_currentRecord);
    }

    final latest = KeyRecordRepository.searchKeys(_currentRecord.keyId)
        .where((item) => item.keyId == _currentRecord.keyId)
        .toList();
    if (latest.isNotEmpty && mounted) {
      setState(() => _currentRecord = latest.first);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action updated.'),
          action: SnackBarAction(
            label: 'Event Log',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EventLogScreen(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<bool> _openHandoverDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final documentReportNoController = TextEditingController();
    final handoverByController = TextEditingController(
      text: AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin',
    );
    final handoverDateController = TextEditingController(text: _formatDate(DateTime.now()));
    final handoverTimeController = TextEditingController(text: _formatTime(DateTime.now()));
    final receivedByController = TextEditingController();
    final witnessesByController = TextEditingController();

    try {
      final saved = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Handover Details'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _EditableField(
                          controller: documentReportNoController,
                          label: 'Document report no.',
                          requiredField: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            final normalized = value?.trim() ?? '';
                            if (normalized.isEmpty) {
                              return 'Required';
                            }
                            if (!RegExp(r'^\d{4}$').hasMatch(normalized)) {
                              return 'Document report no. must be exactly 4 digits';
                            }
                            return null;
                          },
                        ),
                        _EditableField(
                          controller: handoverByController,
                          label: 'Handover by',
                          requiredField: true,
                          readOnly: true,
                        ),
                        _EditableField(
                          controller: handoverDateController,
                          label: 'Handover date',
                          requiredField: true,
                        ),
                        _EditableField(
                          controller: handoverTimeController,
                          label: 'Handover time',
                          requiredField: true,
                        ),
                        _EditableField(
                          controller: receivedByController,
                          label: 'Received by',
                          requiredField: true,
                        ),
                        _EditableField(
                          controller: witnessesByController,
                          label: 'Witnesses by',
                          requiredField: true,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }

                      final actor = AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin';
                      await KeyRecordRepository.markHandOverWithDetails(
                        _currentRecord,
                        actor: actor,
                        metadata: {
                          'documentReportNo': documentReportNoController.text.trim(),
                          'handoverBy': handoverByController.text.trim(),
                          'handoverDate': handoverDateController.text.trim(),
                          'handoverTime': handoverTimeController.text.trim(),
                          'receivedBy': receivedByController.text.trim(),
                          'witnessesBy': witnessesByController.text.trim(),
                        },
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!saved || !mounted) {
        return false;
      }

      final latest = KeyRecordRepository.searchKeys(_currentRecord.keyId)
          .where((item) => item.keyId == _currentRecord.keyId)
          .toList();
      if (latest.isNotEmpty) {
        setState(() => _currentRecord = latest.first);
      }

      return true;
    } finally {
      documentReportNoController.dispose();
      handoverByController.dispose();
      handoverDateController.dispose();
      handoverTimeController.dispose();
      receivedByController.dispose();
      witnessesByController.dispose();
    }
  }

  Future<bool> _openReceiveKeyDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final receivedFromController = TextEditingController(
      text: _readMetadata('staffName').isNotEmpty ? _readMetadata('staffName') : _currentRecord.borrowerName,
    );
    final receivedByController = TextEditingController(
      text: AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin',
    );
    final witnessByController = TextEditingController();
    final documentNoController = TextEditingController();

    try {
      final saved = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Receive Key Details'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _EditableField(
                          controller: receivedFromController,
                          label: 'Received from',
                          requiredField: true,
                        ),
                        _EditableField(
                          controller: receivedByController,
                          label: 'Received by',
                          requiredField: true,
                        ),
                        _EditableField(
                          controller: witnessByController,
                          label: 'Withness by',
                          requiredField: true,
                        ),
                        _EditableField(
                          controller: documentNoController,
                          label: 'Document No.',
                          requiredField: true,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }

                      final actor = AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin';
                      await KeyRecordRepository.receiveKeyWithDetails(
                        _currentRecord,
                        actor: actor,
                        metadata: {
                          'receivedFrom': receivedFromController.text.trim(),
                          'receivedBy': receivedByController.text.trim(),
                          'withnessBy': witnessByController.text.trim(),
                          'documentNo': documentNoController.text.trim(),
                        },
                      );

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!saved || !mounted) {
        return false;
      }

      final latest = KeyRecordRepository.searchKeys(_currentRecord.keyId)
          .where((item) => item.keyId == _currentRecord.keyId)
          .toList();
      if (latest.isNotEmpty) {
        setState(() => _currentRecord = latest.first);
      }

      return true;
    } finally {
      receivedFromController.dispose();
      receivedByController.dispose();
      witnessByController.dispose();
      documentNoController.dispose();
    }
  }

  Future<void> _confirmDeleteKey(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete Key'),
              content: Text(
                'Are you sure you want to delete key "${_currentRecord.keyName}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    final actor = AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin';

    await KeyRecordRepository.deleteKey(_currentRecord, recordedBy: actor);

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Key deleted successfully.')),
    );
    navigator.pop();
  }

  String _readMetadata(String key, {String fallback = ''}) {
    final value = _currentRecord.metadata[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();

    final category = _currentRecord.category;
    final keyNameController = TextEditingController(text: _currentRecord.keyName);
    final locationController = TextEditingController(text: _readMetadata('location'));
    final levelController = TextEditingController(text: _readMetadata('level'));
    final zoneController = TextEditingController(text: _readMetadata('zone', fallback: _currentRecord.zone));
    final masterKeyController = TextEditingController(text: _readMetadata('masterKey', fallback: _currentRecord.keyName));
    final lotKeyController = TextEditingController(text: _readMetadata('lotKey', fallback: _currentRecord.keyName));
    final rollerLevelNoController = TextEditingController(text: _readMetadata('rollerLevelNo'));
    final frsController = TextEditingController(text: _readMetadata('frs'));
    final rollerNumberController = TextEditingController(text: _readMetadata('rollerNumber'));
    final qtyController = TextEditingController(text: _readMetadata('qty'));
    final doorIdController = TextEditingController(text: _readMetadata('doorId'));
    var selectedStatus = _statusOptions.contains(_currentRecord.status)
      ? _currentRecord.status
      : 'Available';
    final remarksController = TextEditingController(text: _readMetadata('remarks'));

    Future<void> save() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      final metadata = Map<String, dynamic>.from(_currentRecord.metadata)
        ..addAll({
          'location': locationController.text.trim(),
          'level': levelController.text.trim(),
          'zone': zoneController.text.trim(),
          'masterKey': masterKeyController.text.trim(),
          'lotKey': lotKeyController.text.trim(),
          'rollerLevelNo': rollerLevelNoController.text.trim(),
          'frs': frsController.text.trim(),
          'rollerNumber': rollerNumberController.text.trim(),
          'qty': qtyController.text.trim(),
          'doorId': doorIdController.text.trim(),
          'remarks': remarksController.text.trim(),
        });

      final effectiveZone = zoneController.text.trim().isEmpty ? _currentRecord.zone : zoneController.text.trim();
      final actor = AuthService.activeUser.isEmpty ? 'Security Admin' : AuthService.activeUser;

      try {
        await KeyRecordRepository.updateRegisteredKeyDetails(
          keyId: _currentRecord.keyId,
          zone: effectiveZone,
          keyName: keyNameController.text.trim(),
          category: category,
          status: selectedStatus,
          recordedBy: actor,
          metadata: metadata,
        );

        if (!mounted) {
          return;
        }

        navigator.pop();

        final latest = KeyRecordRepository.searchKeys(_currentRecord.keyId)
            .where((item) => item.keyId == _currentRecord.keyId)
            .toList();
        if (latest.isNotEmpty) {
          setState(() => _currentRecord = latest.first);
        }

        messenger.showSnackBar(
          const SnackBar(content: Text('Key details updated.')),
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(
          SnackBar(content: Text('Save failed: $error')),
        );
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Key Details'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _EditableField(controller: keyNameController, label: 'Key Name', requiredField: true),
                        _EditableField(controller: locationController, label: 'Location'),
                        _EditableField(controller: levelController, label: 'Level'),
                        if (category == 'Zone' || category == 'Others')
                          _EditableField(controller: zoneController, label: 'Zone', requiredField: true),
                        if (category == 'Master Key')
                          _EditableField(controller: masterKeyController, label: 'Master Key', requiredField: true),
                        if (category == 'Lot')
                          _EditableField(controller: lotKeyController, label: 'No. Lot Key', requiredField: true),
                        if (category == 'Roller Shutter') ...[
                          _EditableField(controller: rollerLevelNoController, label: 'Level / No.', requiredField: true),
                          _EditableField(controller: frsController, label: 'FRS', requiredField: true),
                          _EditableField(controller: rollerNumberController, label: 'No. Roller Shutter', requiredField: true),
                        ],
                        _EditableField(controller: qtyController, label: 'Qty'),
                        if (category != 'Roller Shutter')
                          _EditableField(controller: doorIdController, label: 'Door ID'),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              filled: true,
                              fillColor: const Color(0xFFF9FBFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: _statusOptions
                                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setDialogState(() => selectedStatus = value);
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        _EditableField(controller: remarksController, label: 'Remarks', maxLines: 3),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: save,
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    keyNameController.dispose();
    locationController.dispose();
    levelController.dispose();
    zoneController.dispose();
    masterKeyController.dispose();
    lotKeyController.dispose();
    rollerLevelNoController.dispose();
    frsController.dispose();
    rollerNumberController.dispose();
    qtyController.dispose();
    doorIdController.dispose();
    remarksController.dispose();
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
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

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller,
    required this.label,
    this.requiredField = false,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator ??
            (requiredField
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  }
                : null),
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

