import 'package:flutter/material.dart';

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
                  _ReadOnlyField(label: 'Key ID', value: _currentRecord.keyId),
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
                  if (_readMetadata('staffName').isNotEmpty)
                    _ReadOnlyField(label: 'Name Staff', value: _readMetadata('staffName')),
                  if (_readMetadata('department').isNotEmpty)
                    _ReadOnlyField(label: 'Department', value: _readMetadata('department')),
                  if (_readMetadata('tenantName').isNotEmpty)
                    _ReadOnlyField(label: 'Tenant\'s Name', value: _readMetadata('tenantName')),
                  if (_readMetadata('purpose').isNotEmpty)
                    _ReadOnlyField(label: 'Purpose', value: _readMetadata('purpose')),
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
                          const PopupMenuItem(value: 'Replaced', child: Text('New key replaced')),
                          const PopupMenuItem(value: 'Hand Over', child: Text('Hand Over')),
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
      await KeyRecordRepository.markHandOver(_currentRecord);
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
    final statusController = TextEditingController(text: _currentRecord.status);
    final staffNameController = TextEditingController(text: _readMetadata('staffName'));
    final departmentController = TextEditingController(text: _readMetadata('department'));
    final tenantNameController = TextEditingController(text: _readMetadata('tenantName'));
    final purposeController = TextEditingController(text: _readMetadata('purpose'));
    final dateController = TextEditingController(text: _readMetadata('date'));
    final timeController = TextEditingController(text: _readMetadata('time'));
    final remarksController = TextEditingController(text: _readMetadata('remarks'));

    Future<void> save() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      final metadata = <String, dynamic>{
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
        'staffName': staffNameController.text.trim(),
        'department': departmentController.text.trim(),
        'tenantName': tenantNameController.text.trim(),
        'purpose': purposeController.text.trim(),
        'date': dateController.text.trim(),
        'time': timeController.text.trim(),
        'remarks': remarksController.text.trim(),
      };

      final effectiveZone = zoneController.text.trim().isEmpty ? _currentRecord.zone : zoneController.text.trim();
      final actor = AuthService.activeUser.isEmpty ? 'Security Admin' : AuthService.activeUser;

      try {
        await KeyRecordRepository.updateRegisteredKeyDetails(
          keyId: _currentRecord.keyId,
          zone: effectiveZone,
          keyName: keyNameController.text.trim(),
          category: category,
          status: statusController.text.trim(),
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
          content: SizedBox(
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
                    _EditableField(controller: statusController, label: 'Status', requiredField: true),
                    _EditableField(controller: staffNameController, label: 'Name Staff'),
                    _EditableField(controller: departmentController, label: 'Department'),
                    _EditableField(controller: tenantNameController, label: 'Tenant\'s Name'),
                    _EditableField(controller: purposeController, label: 'Purpose'),
                    _EditableField(controller: dateController, label: 'Date'),
                    _EditableField(controller: timeController, label: 'Time'),
                    _EditableField(controller: remarksController, label: 'Remarks', maxLines: 3),
                  ],
                ),
              ),
            ),
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
    statusController.dispose();
    staffNameController.dispose();
    departmentController.dispose();
    tenantNameController.dispose();
    purposeController.dispose();
    dateController.dispose();
    timeController.dispose();
    remarksController.dispose();
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
  });

  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              }
            : null,
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

