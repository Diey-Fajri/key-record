import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/key_repository.dart' as repository;
import '../../widget/beautiful_submit_button.dart';

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
  final List<repository.Borrower> _savedBorrowers = <repository.Borrower>[];
  StreamSubscription<List<repository.Borrower>>? _savedBorrowersSubscription;
  late DateTime _now;
  late Timer _clockTimer;
  bool _saveBorrower = true;
  bool _initialKeyHandled = false;
  bool _isSubmitting = false;
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

    _savedBorrowersSubscription = repository.KeyRecordRepository.watchSavedBorrowers().listen((items) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savedBorrowers
          ..clear()
          ..addAll(items);
      });
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _savedBorrowersSubscription?.cancel();
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
                        final selectedIds = _selectedKeys.map((item) => item.docId).toSet();
                        final availableKeys = allKeys
                            .where((key) => key.status == 'Available' && !selectedIds.contains(key.docId ?? key.keyId))
                            .map((record) => AvailableKey(
                                  docId: record.docId ?? record.keyId,
                                  keyId: record.keyId,
                                  zone: _keyLevelZone(record),
                                  name: record.keyName,
                                  status: record.status,
                                ))
                            .toList();

                        _tryAutoAddInitialKey(availableKeys);

                        return Autocomplete<AvailableKey>(
                          displayStringForOption: (key) =>
                              key.searchLabel,
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
                            _commitSelectedKey(key);
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
                                        leading: const Icon(Icons.vpn_key_outlined),
                                        title: Text(key.displayLabel),
                                        subtitle: Text('ID: ${key.keyId}'),
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
                    if (_selectedKeys.isEmpty)
                      const _EmptySelection()
                    else
                      _SelectedKeysPanel(
                        keys: _selectedKeys,
                        onRemove: (key) {
                          setState(() => _selectedKeys.remove(key));
                        },
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
                            if (value == 'Staff') {
                              _icController.clear();
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<repository.Borrower>(
                      displayStringForOption: (option) => option.name,
                      optionsBuilder: (value) {
                        final query = value.text.trim().toLowerCase();
                        if (query.isEmpty) {
                          return const Iterable<repository.Borrower>.empty();
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
                        decoration: _inputDecoration('IC / Passport No.', Icons.credit_card),
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
              BeautifulSubmitButton(
                isLoading: _isSubmitting,
                onPressed: _submit,
                idleLabel: 'Submit',
                loadingLabel: 'Submitting...',
                icon: Icons.assignment_turned_in_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _commitSelectedKey(AvailableKey selected) {
    if (!mounted) {
      return;
    }

    if (selected.status.toLowerCase() != 'available') {
      _showMessage('Key must be Available before it can be taken.');
      return;
    }

    if (_selectedKeys.any((key) => key.docId == selected.docId)) {
      _showMessage('This key is already added.');
      return;
    }

    setState(() {
      _selectedKeys.add(selected);
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
      if (_selectedKeys.any((selected) => selected.docId == key.docId)) {
        return;
      }
      setState(() {
        _selectedKeys.add(key);
        _keySearchFieldController?.clear();
      });
    });
  }

  void _selectBorrower(repository.Borrower borrower) {
    setState(() {
      _nameController.text = borrower.name;
      _icController.text = borrower.icPassport;
      _phoneController.text = borrower.phone;
      _companyController.text = borrower.company;
      _departmentController.text = borrower.department;
    });
  }

  Future<void> _submit() async { // Orchestrator
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Validate inputs
      final takenAt = _getTakenAt();
      final selectedRecords = await _validateAndGetSelectedRecords();
      if (selectedRecords == null || takenAt == null || !_validateForm()) {
        return;
      }

      // 2. Prepare data
      final borrower = _buildBorrower();
      final metadata = _buildTransactionMetadata(borrower.name);
      final recordedBy = AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin';

      // 3. Execute transaction
      await repository.KeyRecordRepository.takeKeys(
        selectedRecords,
        borrower,
        takenAt,
        recordedBy: recordedBy,
        transactionStatus: _takeStatus,
        metadata: metadata,
      );

      // 4. Handle post-submission tasks
      final wasBorrowerSaved = await _saveBorrowerIfNeeded();
      if (mounted) {
        await _showSuccessDialog(selectedRecords, borrower, takenAt, wasBorrowerSaved);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Failed to update all keys. Please retry. ($error)');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _validateForm() {
    if (_selectedKeys.isEmpty) {
      _showMessage('Please add at least one available key.');
      return false;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (_takeStatus == 'Hand Over' && !_validateHandoverDetails()) {
      _showMessage('Please complete the handover popup details first.');
      return false;
    }

    return true;
  }

  Future<List<repository.KeyRecord>?> _validateAndGetSelectedRecords() async {
    final allKeys = await repository.KeyRecordRepository.watchAllKeys().first;
    final keyByDocId = {
      for (final key in allKeys)
        if (key.docId?.trim().isNotEmpty ?? false) key.docId!.trim(): key,
    };

    final selectedRecords = _selectedKeys
        .map((selected) => keyByDocId[selected.docId])
        .whereType<repository.KeyRecord>()
        .toList();

    if (selectedRecords.length != _selectedKeys.length) {
      _showMessage('One or more selected keys are no longer available. Please reselect keys.');
      return null;
    }
    return selectedRecords;
  }

  Future<void> _showSuccessDialog(
    List<repository.KeyRecord> records,
    repository.Borrower borrower,
    DateTime takenAt,
    bool wasBorrowerSaved,
  ) async {
    final keyLabels = records.map((r) => '${r.zone}/${r.keyName}').join(', ');
    final isHandOver = _takeStatus == 'Hand Over';
    final dialogLines = <String>[
      'Keys: $keyLabels',
      'Borrower: ${borrower.name}',
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
      if (wasBorrowerSaved) 'Person saved for next time.',
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

  repository.Borrower _buildBorrower() {
    return repository.Borrower(
      name: _nameController.text.trim(),
      icPassport: _borrowerCategory == 'Others' ? _icController.text.trim() : '',
      phone: _phoneController.text.trim(),
      company: _companyController.text.trim(),
      department: _departmentController.text.trim(),
    );
  }

  Map<String, dynamic> _buildTransactionMetadata(String borrowerName) {
    final isHandOver = _takeStatus == 'Hand Over';
    return {
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
    };
  }

  DateTime? _getTakenAt() {
    final takenAt = _takeStatus == 'Hand Over' ? _parseHandoverDateTime() : _now;
    if (takenAt == null) _showMessage('Please enter a valid handover date and time.');
    return takenAt;
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

  Future<bool> _saveBorrowerIfNeeded() async {
    if (!_saveBorrower) {
      return false;
    }

    final borrower = repository.Borrower(
      name: _nameController.text.trim(),
      icPassport: _icController.text.trim(),
      phone: _phoneController.text.trim(),
      company: _companyController.text.trim(),
      department: _departmentController.text.trim(),
    );
    return await repository.KeyRecordRepository.saveBorrowerProfile(
      borrower,
      recordedBy: AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin',
    );
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

class _SelectedKeysPanel extends StatelessWidget {
  const _SelectedKeysPanel({
    required this.keys,
    required this.onRemove,
  });

  final List<AvailableKey> keys;
  final ValueChanged<AvailableKey> onRemove;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected keys (${keys.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ...keys.map((key) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDCE4E8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key_outlined, color: Color(0xFF00695C)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            key.displayLabel,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Key ID: ${key.keyId}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove key',
                      onPressed: () => onRemove(key),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AvailableKey {
  const AvailableKey({
    required this.docId,
    required this.keyId,
    required this.zone,
    required this.name,
    required this.status,
  });

  final String docId;
  final String keyId;
  final String zone;
  final String name;
  final String status;

  String get displayLabel => '$zone • $name';

  String get searchLabel => '$keyId $zone $name';
}

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
