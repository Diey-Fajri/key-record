import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/key_repository.dart' as repository;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keySearchController = TextEditingController();
  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _departmentController = TextEditingController();
  final _purposeController = TextEditingController();
  final _documentReportNoController = TextEditingController();
  final _handoverByController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _witnessesByController = TextEditingController();
  final _handoverDialogFormKey = GlobalKey<FormState>();
  final List<AvailableKey> _selectedKeys = [];
  final List<Borrower> _savedBorrowers = List<Borrower>.from(
    _savedBorrowerStore,
  );
  late DateTime _timeTaken;
  late Timer _clockTimer;
  bool _saveBorrower = true;
  Borrower? _selectedBorrower;
  AvailableKey? _selectedKeyFromSearch;
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
    _timeTaken = DateTime.now();
    _handoverByController.text =
        AuthService.activeUser.isNotEmpty ? AuthService.activeUser : 'Security Admin';
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _timeTaken = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _keySearchController.dispose();
    _nameController.dispose();
    _icController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _purposeController.dispose();
    _documentReportNoController.dispose();
    _handoverByController.dispose();
    _receivedByController.dispose();
    _witnessesByController.dispose();
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
                        final availableKeys = allKeys
                            .where((key) => key.status == 'Available')
                            .map((record) => AvailableKey(
                                  keyId: record.keyId,
                                  zone: record.zone,
                                  name: record.keyName,
                                  status: record.status,
                                ))
                            .toList();

                        return Autocomplete<AvailableKey>(
                          displayStringForOption: (key) =>
                              '${key.zone} / ${key.name}',
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
                            _keySearchController.text = '${key.zone} / ${key.name}';
                          },
                          fieldViewBuilder:
                              (context, controller, focusNode, onSubmitted) {
                            if (_keySearchController.text.isNotEmpty &&
                                controller.text != _keySearchController.text) {
                              controller.text = _keySearchController.text;
                            }

                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: _inputDecoration(
                                'Search key by zone, name, or key ID',
                                Icons.search,
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
                                        title: Text('${key.zone} / ${key.name}'),
                                        subtitle: Text(key.keyId),
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
                            label: Text('${key.zone} / ${key.name}'),
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
                            _selectedBorrower = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Borrower>(
                      initialValue: _selectedBorrower,
                      decoration: _inputDecoration(
                        _borrowerCategory == 'Staff'
                            ? 'Staff Name dropdown (optional)'
                            : 'Name dropdown (optional)',
                        Icons.person_outline,
                      ),
                      items: _savedBorrowers.map((borrower) {
                        return DropdownMenuItem(
                          value: borrower,
                          child: Text(borrower.name),
                        );
                      }).toList(),
                      onChanged: _selectBorrower,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        _borrowerCategory == 'Staff' ? 'Staff Name' : 'Name',
                        Icons.badge_outlined,
                      ),
                      validator: _required,
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
                      ).copyWith(hintText: _formatDateTime(_timeTaken)),
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
      _keySearchController.clear();
    });
  }

  void _selectBorrower(Borrower? borrower) {
    setState(() {
      _selectedBorrower = borrower;
      if (borrower != null) {
        _nameController.text = borrower.name;
        _icController.text = borrower.icPassport;
        _phoneController.text = borrower.phone;
        _companyController.text = borrower.company;
        _departmentController.text = borrower.department;
      }
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
    final selectedRecords = _selectedKeys
        .map((selected) => repository.KeyRecordRepository.availableKeys
            .firstWhere((record) => record.keyId == selected.keyId))
        .toList();
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
      _timeTaken,
      recordedBy: recordedBy,
      transactionStatus: _takeStatus,
      metadata: isHandOver
          ? {
              'documentReportNo': _documentReportNoController.text.trim(),
              'handoverBy': _handoverByController.text.trim(),
              'receivedBy': _receivedByController.text.trim(),
              'witnessesBy': _witnessesByController.text.trim(),
            }
          : const {},
    );
    if (!mounted) return;

    final dialogLines = <String>[
      'Keys: $keyLabels',
      'Borrower: $borrowerName',
      'Status: $_takeStatus',
      if (isHandOver) ...[
        'Document report no.: ${_documentReportNoController.text.trim()}',
        'Handover by: ${_handoverByController.text.trim()}',
        'Received by: ${_receivedByController.text.trim()}',
        'Witnesses by: ${_witnessesByController.text.trim()}',
      ],
      'Time: ${_formatDateTime(_timeTaken)}',
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
        _receivedByController.text.trim().isNotEmpty &&
        _witnessesByController.text.trim().isNotEmpty;
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

String _formatDateTime(DateTime value) {
  final date =
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
  return '$date $time';
}
