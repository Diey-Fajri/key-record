import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/key_repository.dart' as repository;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialKeyId});

  final String? initialKeyId;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _keySearchFieldController;
  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _departmentController = TextEditingController();
  final _purposeController = TextEditingController();
  final _remarksController = TextEditingController();
  final _documentReportNoController = TextEditingController();
  final _handoverByController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _witnessesByController = TextEditingController();
  final _handoverDateController = TextEditingController();
  final _handoverTimeController = TextEditingController();
  final _handoverDialogFormKey = GlobalKey<FormState>();
  final List<AvailableKey> _selectedKeys = [];
  final List<Borrower> _savedBorrowers = List<Borrower>.from(
    _savedBorrowerStore,
  );
  late DateTime _now;
  late Timer _clockTimer;
  bool _saveBorrower = true;
  AvailableKey? _selectedKeyFromSearch;
  bool _initialKeyHandled = false;
  String _borrowerCategory = 'Staff';
  String _takeStatus = 'In Use';
  static const List<String> _borrowerCategories = [
    'Staff',
    'Others',
  ];

  static const List<String> _takeStatuses = [
    'In Use',
    'Hand Over',
  ];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _handoverByController.text =
        AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin';
    _handoverDateController.text = _formatDateOnly(_now);
    _handoverTimeController.text = _formatTimeOnly(_now);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _nameController.dispose();
    _icController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _departmentController.dispose();
    _purposeController.dispose();
    _remarksController.dispose();
    _documentReportNoController.dispose();
    _handoverByController.dispose();
    _receivedByController.dispose();
    _witnessesByController.dispose();
    _handoverDateController.dispose();
    _handoverTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Take A Key'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Select Key',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<List<repository.KeyRecord>>(
                      stream: repository.KeyRecordRepository.watchAllKeys(),
                      builder: (context, snapshot) {
                        final allKeys = snapshot.data ?? const [];
                        final selectedIds = _selectedKeys.map((item) => item.keyId).toSet();
                        final availableKeys = allKeys
                            .where((key) => key.status == 'Available' && !selectedIds.contains(key.keyId))
                            .map((record) => AvailableKey(
                                  keyId: record.keyId,
                                  zone: _keyLevelZone(record),
                                  name: record.keyName,
                                  status: record.status,
                                ))
                            .toList();

                        _tryAutoAddInitialKey(availableKeys);

                        return Autocomplete<AvailableKey>(
                          displayStringForOption: (key) =>
                              key.zone,
                          optionsBuilder: (value) {
                            final query = value.text.trim().toLowerCase();
                            if (query.isEmpty) {
                              return availableKeys;
                            }

                            return availableKeys.where((key) {
                              final label =
                                  '${key.keyId} ${key.zone} ${key.name} ${key.status}'
                                      .toLowerCase();
                              return label.contains(query);
                            });
                          },
                          onSelected: (key) {
                            _selectedKeyFromSearch = key;
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, onSubmitted) {
                            _keySearchFieldController = controller;

                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: _inputDecoration(
                                'Search key by zone, name, or key ID',
                                Icons.search,
                                hint: 'Type key ID, level, zone, or name',
                              ),
                              onChanged: (_) => _selectedKeyFromSearch = null,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 260,
                                    maxWidth: 520,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final key = options.elementAt(index);
                                      return ListTile(
                                        title: Text(key.zone),
                                        subtitle: Text(key.name),
                                        trailing: _AvailabilityTag(
                                          status: key.status,
                                        ),
                                        onTap: () => onSelected(key),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _addSelectedKey,
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
                    ),
                    const SizedBox(height: 12),
                    if (_selectedKeys.isEmpty)
                      const _EmptySelection()
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedKeys.map((key) {
                          return InputChip(
                            avatar: const Icon(Icons.vpn_key_outlined),
                            label: Text('${key.zone} ${key.name}'),
                            onDeleted: () {
                              setState(() => _selectedKeys.remove(key));
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'Borrower Info',
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _borrowerCategory,
                      decoration: _inputDecoration(
                        'Category',
                        Icons.account_circle_outlined,
                      ),
                      items: _borrowerCategories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _borrowerCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<Borrower>(
                      displayStringForOption: (option) => option.name,
                      optionsBuilder: (value) {
                        final query = value.text.trim().toLowerCase();
                        if (query.isEmpty) {
                          return const Iterable<Borrower>.empty();
                        }
                        return _savedBorrowers.where((borrower) {
                          return borrower.name.toLowerCase().contains(query);
                        });
                      },
                      onSelected: _selectBorrower,
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        if (_nameController.text.isNotEmpty && controller.text != _nameController.text) {
                          controller.text = _nameController.text;
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            _borrowerCategory == 'Staff' ? 'Staff Name' : 'Name',
                            Icons.badge_outlined,
                            hint: _borrowerCategory == 'Staff'
                                ? 'Start typing staff name'
                                : 'Start typing name',
                          ),
                          validator: _required,
                          onChanged: (value) {
                            _nameController.text = value;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_borrowerCategory == 'Others') ...[
                      TextFormField(
                        controller: _icController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'IC / Passport No.',
                          Icons.credit_card,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_borrowerCategory == 'Staff') ...[
                      TextFormField(
                        controller: _departmentController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'Department',
                          Icons.apartment,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        'Phone No.',
                        Icons.phone_outlined,
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    if (_borrowerCategory == 'Others') ...[
                      TextFormField(
                        controller: _companyController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'Company',
                          Icons.business_outlined,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _purposeController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Purpose',
                        Icons.assignment_outlined,
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _remarksController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Remarks',
                        Icons.message_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _takeStatus,
                      decoration: _inputDecoration('Status', Icons.info_outline),
                      items: _takeStatuses
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _takeStatus = value);
                          if (value == 'Hand Over') {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _openHandoverDetailsDialog();
                              }
                            });
                          }
                        }
                      },
                    ),
                    if (_takeStatus == 'Hand Over') ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openHandoverDetailsDialog,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Enter handover details'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _documentReportNoController.text.trim().isEmpty
                            ? 'No handover details entered yet.'
                            : 'Handover details captured.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _saveBorrower,
                      onChanged: (value) {
                        setState(() => _saveBorrower = value ?? true);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Save this person for next time'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: _inputDecoration(
                        'Date / Time Taken',
                        Icons.schedule,
                        hint: _formatDateTime(_now),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('Submit'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSelectedKey() {
    final selected = _selectedKeyFromSearch;

    if (selected == null) {
      _showMessage('Please select a key from the search list first.');
      return;
    }

    if (selected.status.toLowerCase() != 'available') {
      _showMessage('Key must be Available before it can be taken.');
      return;
    }

    if (_selectedKeys.any((key) => key.keyId == selected.keyId)) {
      _showMessage('This key is already added.');
      return;
    }

    setState(() {
      _selectedKeys.add(selected);
      _selectedKeyFromSearch = null;
      _keySearchFieldController?.clear();
    });
  }

  void _tryAutoAddInitialKey(List<AvailableKey> availableKeys) {
    final initialKeyId = widget.initialKeyId;
    if (_initialKeyHandled || initialKeyId == null || initialKeyId.trim().isEmpty) {
      return;
    }

    final index = availableKeys.indexWhere((key) => key.keyId == initialKeyId);
    if (index == -1) {
      return;
    }

    _initialKeyHandled = true;
    final key = availableKeys[index];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_selectedKeys.any((selected) => selected.keyId == key.keyId)) {
        return;
      }
      setState(() {
        _selectedKeys.add(key);
        _selectedKeyFromSearch = null;
        _keySearchFieldController?.clear();
      });
    });
  }

  void _selectBorrower(Borrower borrower) {
    setState(() {
      _nameController.text = borrower.name;
      _icController.text = borrower.icPassport;
      _phoneController.text = borrower.phone;
      _companyController.text = borrower.company;
      _departmentController.text = borrower.department;
    });
  }

  Future<void> _submit() async {
    if (_selectedKeys.isEmpty) {
      _showMessage('Please add at least one available key.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final borrowerName = _nameController.text.trim();
    final takenAt = _takeStatus == 'Hand Over' ? _parseHandoverDateTime() : _now;
    if (takenAt == null) {
      _showMessage('Please enter a valid handover date and time.');
      return;
    }
    final selectedRecords = _selectedKeys
        .map((selected) => repository.KeyRecordRepository.searchKeys(selected.keyId)
            .where((record) => record.keyId == selected.keyId)
            .toList())
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList();
    if (selectedRecords.length != _selectedKeys.length) {
      _showMessage('One or more selected keys are no longer available. Please reselect keys.');
      return;
    }
    final borrower = repository.Borrower(
      name: borrowerName,
      icPassport: _icController.text.trim(),
      phone: _phoneController.text.trim(),
      company: _companyController.text.trim(),
      department: _departmentController.text.trim(),
    );
    final savedBorrower = _saveBorrowerIfNeeded();
    final keyLabels = selectedRecords.map((record) => '${record.zone}/${record.keyName}').join(', ');
    final isHandOver = _takeStatus == 'Hand Over';
    final recordedBy = AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin';

    if (isHandOver && !_validateHandoverDetails()) {
      _showMessage('Please complete the handover popup details first.');
      return;
    }

    await repository.KeyRecordRepository.takeKeys(
      selectedRecords,
      borrower,
      takenAt,
      recordedBy: recordedBy,
      transactionStatus: _takeStatus,
      metadata: {
        'borrowerCategory': _borrowerCategory,
        'staffName': _borrowerCategory == 'Staff' ? borrowerName : '',
        'othersName': _borrowerCategory == 'Others' ? borrowerName : '',
        'department': _departmentController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'remarks': _remarksController.text.trim(),
        if (isHandOver) ...{
          'documentReportNo': _documentReportNoController.text.trim(),
          'handoverBy': _handoverByController.text.trim(),
          'receivedBy': _receivedByController.text.trim(),
          'witnessesBy': _witnessesByController.text.trim(),
          'handoverDate': _handoverDateController.text.trim(),
          'handoverTime': _handoverTimeController.text.trim(),
        },
      },
    );
    if (!mounted) return;

    final dialogLines = <String>[
      'Keys: $keyLabels',
      'Borrower: $borrowerName',
      'Status: $_takeStatus',
      if (_remarksController.text.trim().isNotEmpty)
        'Remarks: ${_remarksController.text.trim()}',
      if (isHandOver) ...[
        'Document report no.: ${_documentReportNoController.text.trim()}',
        'Handover by: ${_handoverByController.text.trim()}',
        'Received by: ${_receivedByController.text.trim()}',
        'Witnesses by: ${_witnessesByController.text.trim()}',
      ],
      'Time: ${_formatDateTime(takenAt)}',
      if (savedBorrower) 'Person saved for next time.',
    ];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isHandOver ? 'Key Handover' : 'Key Taken - In Use'),
          content: Text(dialogLines.join('\n')),
          actions: [
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

  Future<void> _openHandoverDetailsDialog() async {
    if (_takeStatus != 'Hand Over') {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Handover Details'),
          content: Form(
            key: _handoverDialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _documentReportNoController,
                    decoration: _inputDecoration('Document report no.', Icons.receipt_long),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _handoverByController,
                    readOnly: true,
                    decoration: _inputDecoration('Handover by', Icons.person_outline),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _handoverDateController,
                    decoration: _inputDecoration(
                      'Handover date',
                      Icons.calendar_today,
                      hint: 'YYYY-MM-DD',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _handoverTimeController,
                    decoration: _inputDecoration(
                      'Handover time',
                      Icons.schedule,
                      hint: 'HH:MM or HH:MM:SS',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _receivedByController,
                    decoration: _inputDecoration('Received by', Icons.person_add_alt_1_outlined),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _witnessesByController,
                    decoration: _inputDecoration('Witnesses by', Icons.groups_outlined),
                    validator: _required,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (_handoverDialogFormKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  bool _validateHandoverDetails() {
    return _documentReportNoController.text.trim().isNotEmpty &&
        _handoverDateController.text.trim().isNotEmpty &&
        _handoverTimeController.text.trim().isNotEmpty &&
        _receivedByController.text.trim().isNotEmpty &&
        _witnessesByController.text.trim().isNotEmpty;
  }

  DateTime? _parseHandoverDateTime() {
    final date = _handoverDateController.text.trim();
    final time = _handoverTimeController.text.trim();
    if (date.isEmpty || time.isEmpty) {
      return null;
    }

    final normalizedTime = time.length == 5 ? '$time:00' : time;
    return DateTime.tryParse('${date}T$normalizedTime');
  }

  bool _saveBorrowerIfNeeded() {
    if (!_saveBorrower) {
      return false;
    }

    final borrower = Borrower(
      name: _nameController.text.trim(),
      icPassport: _icController.text.trim(),
      phone: _phoneController.text.trim(),
      company: _companyController.text.trim(),
      department: _departmentController.text.trim(),
    );
    final existingIndex = _savedBorrowerStore.indexWhere(
      (saved) =>
          saved.icPassport.toLowerCase() == borrower.icPassport.toLowerCase() ||
          saved.name.toLowerCase() == borrower.name.toLowerCase(),
    );

    if (existingIndex == -1) {
      _savedBorrowerStore.add(borrower);
      _savedBorrowers.add(borrower);
      return true;
    }

    _savedBorrowerStore[existingIndex] = borrower;
    final localIndex = _savedBorrowers.indexWhere(
      (saved) =>
          saved.icPassport.toLowerCase() == borrower.icPassport.toLowerCase() ||
          saved.name.toLowerCase() == borrower.name.toLowerCase(),
    );
    if (localIndex == -1) {
      _savedBorrowers.add(borrower);
    } else {
      _savedBorrowers[localIndex] = borrower;
    }
    return false;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String _keyLevelZone(repository.KeyRecord record) {
    final level = record.metadata['level']?.toString().trim() ?? '';
    final zoneFromMetadata = record.metadata['zone']?.toString().trim() ?? '';
    if (level.isNotEmpty && zoneFromMetadata.isNotEmpty) {
      return '$level/$zoneFromMetadata';
    }

    final parsedFromZone = _parseLevelZonePair(record.zone);
    if (parsedFromZone != null) {
      return parsedFromZone;
    }

    final parsedFromKeyId = _parseZoneFromLegacyKeyId(record.keyId);
    if (parsedFromKeyId != null) {
      return parsedFromKeyId;
    }

    return record.zone.trim();
  }

  String? _parseLevelZonePair(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || !normalized.contains('/')) {
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

  String? _parseZoneFromLegacyKeyId(String keyId) {
    final normalized = keyId.trim();
    if (!normalized.toUpperCase().startsWith('ZONE-')) {
      return null;
    }

    final remainder = normalized.substring(5);
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

class _AvailabilityTag extends StatelessWidget {
  const _AvailabilityTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final available = status.toLowerCase() == 'available';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE7F5EA) : const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: available ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5E8)),
      ),
      child: const Text('No keys selected yet.'),
    );
  }
}

class AvailableKey {
  const AvailableKey({
    required this.keyId,
    required this.zone,
    required this.name,
    required this.status,
  });

  final String keyId;
  final String zone;
  final String name;
  final String status;
}

class Borrower {
  const Borrower({
    required this.name,
    required this.icPassport,
    required this.phone,
    required this.company,
    required this.department,
  });

  final String name;
  final String icPassport;
  final String phone;
  final String company;
  final String department;
}

final List<Borrower> _savedBorrowerStore = List<Borrower>.from(
  _defaultBorrowers,
);

const List<Borrower> _defaultBorrowers = [
  Borrower(
    name: 'Ali',
    icPassport: '900101-10-1234',
    phone: '0123456789',
    company: 'XYZ Contractor',
    department: 'Maintenance',
  ),
  Borrower(
    name: 'Nur Aisyah',
    icPassport: 'A12345678',
    phone: '0172223344',
    company: 'Network Ops',
    department: 'Operations',
  ),
  Borrower(
    name: 'Kumar Raj',
    icPassport: '850505-14-7788',
    phone: '0198881122',
    company: 'Logistics Partner',
    department: 'Logistics',
  ),
];

InputDecoration _inputDecoration(String label, IconData icon, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint ?? label,
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

String _formatDateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _formatTimeOnly(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDateTime(DateTime value) {
  final date =
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
  return '$date $time';
}
