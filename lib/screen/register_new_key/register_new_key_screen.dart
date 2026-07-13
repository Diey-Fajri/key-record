import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/key_repository.dart';
import '../../widget/beautiful_submit_button.dart';
import '../event_log/event_log_screen.dart';

class RegisterNewKeyScreen extends StatefulWidget {
  const RegisterNewKeyScreen({super.key});

  @override
  State<RegisterNewKeyScreen> createState() => _RegisterNewKeyScreenState();
}

class _RegisterNewKeyScreenState extends State<RegisterNewKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _zoneController = TextEditingController();
  final _masterLevelController = TextEditingController();
  final _masterKeyController = TextEditingController();
  final _lotKeyController = TextEditingController();
  final _rollerLevelNoController = TextEditingController();
  final _frsController = TextEditingController();
  final _rollerNumberController = TextEditingController();
  final _qtyController = TextEditingController();
  final _doorIdController = TextEditingController();
  final _keyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _staffNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _tenantNameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _remarksController = TextEditingController();

  String _category = 'Zone';
  String _location = 'Mall';
  String _level = 'B2';
  String _status = 'Available';
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'Zone',
    'Master Key',
    'Lot',
    'Roller Shutter',
    'High Risk',
    'Others',
  ];

  static const List<String> _locations = [
    'Mall',
    'Office Tower',
    'Hotel',
    'Service Apartment',
    'Wellness',
  ];

  static const List<String> _zoneStatusOptions = [
    'At Management',
    'At Maintenance',
    'Available',
    'Lost',
    'Not Available',
    'High Risk',
    'Spare Key',
  ];

  static const List<String> _lotStatusOptions = [
    'At Management',
    'At Maintenance',
    'Available',
    'Lost',
    'Not Available',
    'Hand Over',
    'High Risk',
    'Spare Key',
  ];

  static const List<String> _detailStatusesZone = [
    'At Management',
    'At Maintenance',
    'Lost',
  ];

  static const List<String> _detailStatusesLot = [
    'At Management',
    'At Maintenance',
    'Lost',
    'Hand Over',
  ];

  @override
  void dispose() {
    _zoneController.dispose();
    _masterLevelController.dispose();
    _masterKeyController.dispose();
    _lotKeyController.dispose();
    _rollerLevelNoController.dispose();
    _frsController.dispose();
    _rollerNumberController.dispose();
    _qtyController.dispose();
    _doorIdController.dispose();
    _keyNameController.dispose();
    _descriptionController.dispose();
    _staffNameController.dispose();
    _departmentController.dispose();
    _tenantNameController.dispose();
    _purposeController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Register New Key'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(),
            const SizedBox(height: 16),
            _Section(
              title: 'New key details',
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: _inputDecoration('Category', Icons.category),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                            if (_category == 'High Risk') {
                              _status = 'High Risk';
                            } else {
                              _status =
                                  _category == 'Lot' ||
                                      _category == 'Roller Shutter'
                                  ? _lotStatusOptions.first
                                  : _zoneStatusOptions.first;
                            }
                            if (_category == 'Lot') {
                              _level = 'B2';
                            }
                            _clearFieldsForCategory(_category);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _location,
                      decoration: _inputDecoration(
                        'Location',
                        Icons.location_on,
                      ),
                      items: _locations
                          .map(
                            (location) => DropdownMenuItem(
                              value: location,
                              child: Text(location),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _location = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_category == 'Master Key')
                      TextFormField(
                        controller: _masterLevelController,
                        decoration: _inputDecoration(
                          'Level (Optional)',
                          Icons.stairs,
                        ),
                        validator: _optional,
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _level,
                        decoration: _inputDecoration('Level', Icons.stairs),
                        items: _getLevelOptions()
                            .map(
                              (level) => DropdownMenuItem(
                                value: level,
                                child: Text(_levelDisplayLabel(level)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _level = value);
                          }
                        },
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: _inputDecoration(
                        'Status',
                        Icons.info_outline,
                      ),
                      items: _getStatusOptions()
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_category == 'Zone') ...[
                      TextFormField(
                        controller: _zoneController,
                        decoration: _inputDecoration('Zone', Icons.map),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_category == 'High Risk' || _category == 'Others') ...[
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration(
                          'Description',
                          Icons.notes_outlined,
                        ),
                        validator: _optional,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_category == 'Master Key') ...[
                      TextFormField(
                        controller: _masterKeyController,
                        decoration: _inputDecoration(
                          'Master Key',
                          Icons.vpn_key,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_category == 'Lot') ...[
                      TextFormField(
                        controller: _lotKeyController,
                        decoration: _inputDecoration('No. Lot Key', Icons.key),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_category == 'Roller Shutter') ...[
                      TextFormField(
                        controller: _rollerLevelNoController,
                        decoration: _inputDecoration(
                          'Level / No. (e.g. L8 / 190)',
                          Icons.tune,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _frsController,
                        decoration: _inputDecoration('FRS', Icons.description),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rollerNumberController,
                        decoration: _inputDecoration(
                          'No. Roller Shutter',
                          Icons.numbers,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _qtyController,
                      decoration: _inputDecoration(
                        'Qty',
                        Icons.confirmation_num,
                      ),
                      keyboardType: TextInputType.number,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    if (_category != 'Roller Shutter') ...[
                      TextFormField(
                        controller: _doorIdController,
                        decoration: _inputDecoration(
                          'Door ID (Optional)',
                          Icons.door_front_door,
                        ),
                        validator: _optional,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_category != 'Roller Shutter') ...[
                      TextFormField(
                        controller: _keyNameController,
                        decoration: _inputDecoration(
                          _category == 'Lot'
                              ? 'Key Name (Optional)'
                              : 'Key Name',
                          Icons.key,
                        ),
                        validator: _category == 'Lot' ? _optional : _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    if (_statusRequiresDetails()) ...[
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Status details',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _staffNameController,
                        decoration: _inputDecoration(
                          'Name Staff',
                          Icons.person_outline,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _departmentController,
                        decoration: _inputDecoration(
                          'Department',
                          Icons.apartment,
                        ),
                        validator: _required,
                      ),
                      if (_status == 'Hand Over') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tenantNameController,
                          decoration: _inputDecoration(
                            'Tenant’s Name',
                            Icons.person_search,
                          ),
                          validator: _required,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _purposeController,
                        decoration: _inputDecoration('Purpose', Icons.note),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dateController,
                        decoration: _inputDecoration(
                          'Date',
                          Icons.calendar_today,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timeController,
                        decoration: _inputDecoration('Time', Icons.access_time),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _remarksController,
                        decoration: _inputDecoration('Remarks', Icons.message),
                        maxLines: 3,
                        validator: _required,
                      ),
                    ],
                    const SizedBox(height: 24),
                    BeautifulSubmitButton(
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                      idleLabel: 'Submit',
                      loadingLabel: 'Submitting...',
                      icon: Icons.save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getLevelOptions() {
    if (_category == 'Lot') {
      return [
        'B2',
        'B1',
        'Level 1',
        'Level 2',
        'Level 3',
        'Level 4',
        'Level 5',
        'Level 6',
        'Level 7',
        'Level 8',
      ];
    }
    return ['B2', 'B1', for (var i = 1; i <= 40; i++) 'Level $i'];
  }

  List<String> _getStatusOptions() {
    if (_category == 'High Risk') {
      return const ['High Risk'];
    }
    if (_category == 'Lot' || _category == 'Roller Shutter') {
      return _lotStatusOptions;
    }
    return _zoneStatusOptions;
  }

  bool _statusRequiresDetails() {
    if (_category == 'Lot' || _category == 'Roller Shutter') {
      return _detailStatusesLot.contains(_status);
    }
    return _detailStatusesZone.contains(_status);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _optional(String? value) {
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_statusRequiresDetails() && !_validateStatusDetails()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required status detail fields.'),
        ),
      );
      return;
    }

    final category = _cleanChoice(_category);
    final location = _cleanChoice(_location);
    final level = _effectiveLevel();
    final status = _cleanChoice(_status);
    final keyName = _resolveKeyName();
    final keyId = _generateKeyId();
    final metadata = <String, dynamic>{
      'location': location,
      'level': level,
      'doorId': _doorIdController.text.trim(),
      'zone': _resolvePrimaryZoneValue(),
      'description': _descriptionController.text.trim(),
      'masterKey': _masterKeyController.text.trim(),
      'lotKey': _lotKeyController.text.trim(),
      'rollerLevelNo': _rollerLevelNoController.text.trim(),
      'frs': _frsController.text.trim(),
      'rollerNumber': _rollerNumberController.text.trim(),
      'qty': _qtyController.text.trim(),
      'staffName': _staffNameController.text.trim(),
      'department': _departmentController.text.trim(),
      'tenantName': _tenantNameController.text.trim(),
      'purpose': _purposeController.text.trim(),
      'date': _dateController.text.trim(),
      'time': _timeController.text.trim(),
      'remarks': _remarksController.text.trim(),
    };

    final recordedBy = AuthService.activeUser;
    final finalStatus = status.isEmpty ? 'Available' : status;

    setState(() => _isSubmitting = true);
    try {
      await KeyRecordRepository.registerNewKey(
        keyId: keyId,
        zone: _resolvePrimaryZoneValue(),
        keyName: keyName,
        category: category,
        status: finalStatus,
        recordedBy: recordedBy,
        metadata: metadata,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit key registration: $error')),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Key Registered'),
          content: Text(
            'The key "$keyName" has been registered with status "$finalStatus".',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const EventLogScreen(),
                  ),
                );
              },
              child: const Text('View Event Log'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  String _generateKeyId() {
    final levelToken = _effectiveLevel()
        .replaceAll('Level ', 'L')
        .replaceAll(' ', '')
        .toUpperCase();
    final baseId =
        _category == 'Zone' || _category == 'Others' || _category == 'High Risk'
        ? [
            if (levelToken.isNotEmpty) levelToken,
            _zoneController.text.trim(),
          ].where((value) => value.isNotEmpty).join('-')
        : _category == 'Master Key'
        ? [
            if (levelToken.isNotEmpty) levelToken,
            _masterKeyController.text.trim(),
          ].where((value) => value.isNotEmpty).join('-')
        : _category == 'Lot'
        ? [
            if (levelToken.isNotEmpty) levelToken,
            _lotKeyController.text.trim(),
          ].where((value) => value.isNotEmpty).join('-')
        : _rollerLevelNoController.text.trim();

    final fallbackBase = baseId.isEmpty ? _location : baseId;
    final normalizedBase = fallbackBase.replaceAll(' ', '').toUpperCase();
    final normalizedName = _resolveKeyName().replaceAll(' ', '').toUpperCase();
    final normalizedCategory = _category.replaceAll(' ', '').toUpperCase();
    return '$normalizedCategory-$normalizedBase-$normalizedName';
  }

  String _resolveKeyName() {
    if (_category == 'Roller Shutter') {
      return _rollerNumberController.text.trim();
    }

    final typedName = _keyNameController.text.trim();
    if (_category == 'Lot' && typedName.isEmpty) {
      return _lotKeyController.text.trim();
    }

    return typedName;
  }

  String _cleanChoice(String value) {
    return value.trim();
  }

  String _resolvePrimaryZoneValue() {
    if (_category == 'High Risk' || _category == 'Others') {
      return _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : _location;
    }
    if (_category == 'Zone') {
      return _zoneController.text.trim().isEmpty
          ? _location
          : _zoneController.text.trim();
    }
    return _zoneController.text.trim().isEmpty
        ? _location
        : _zoneController.text.trim();
  }

  String _levelDisplayLabel(String level) {
    if (level == 'B2' || level == 'B1') {
      return 'Level $level';
    }
    return level;
  }

  String _effectiveLevel() {
    if (_category == 'Master Key') {
      return _masterLevelController.text.trim();
    }
    return _cleanChoice(_level);
  }

  void _clearFieldsForCategory(String category) {
    if (category != 'Zone') {
      _zoneController.clear();
    }
    if (category != 'High Risk' && category != 'Others') {
      _descriptionController.clear();
    }
    if (category != 'Master Key') {
      _masterKeyController.clear();
      _masterLevelController.clear();
    }
    if (category != 'Lot') {
      _lotKeyController.clear();
    }
    if (category != 'Roller Shutter') {
      _rollerLevelNoController.clear();
      _frsController.clear();
      _rollerNumberController.clear();
    }
  }

  bool _validateStatusDetails() {
    if (_staffNameController.text.trim().isEmpty ||
        _departmentController.text.trim().isEmpty) {
      return false;
    }
    if (_status == 'Hand Over' && _tenantNameController.text.trim().isEmpty) {
      return false;
    }
    if (_purposeController.text.trim().isEmpty ||
        _dateController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty ||
        _remarksController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'REGISTER NEW KEY',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          Text('Access:'),
          Text('- Any member can register.'),
          SizedBox(height: 12),
          Text('Category options:'),
          Text('- Zone, Master Key, Lot, Roller Shutter, Others'),
          SizedBox(height: 12),
          Text('Status options:'),
          Text(
            '- At Management, At Maintenance, Available, Lost, Not Available, High Risk, Spare Key, Hand Over',
          ),
          SizedBox(height: 12),
          Text(
            'Status details appear for management, maintenance, lost, not available, and hand over statuses.',
          ),
          SizedBox(height: 12),
          Text('Recorded By is set to the current logged-in user.'),
          Text(
            'Keys are saved to Firestore keys collection and event log is created.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E5E8)),
    ),
  );
}
