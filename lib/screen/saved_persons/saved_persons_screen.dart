import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/key_repository.dart';

class SavedPersonsScreen extends StatefulWidget {
  const SavedPersonsScreen({super.key});

  @override
  State<SavedPersonsScreen> createState() => _SavedPersonsScreenState();
}

class _DetailField {
  const _DetailField(this.label, this.value);

  final String label;
  final String value;
}

class _SavedPersonsScreenState extends State<SavedPersonsScreen> {
  static const List<String> _staffFromOptions = [
    'Mall',
    'Office Tower',
    'Hotel',
    'Service Apartment',
  ];

  String _inferBorrowerCategory(Borrower person) {
    if (person.staffFrom.trim().isNotEmpty) {
      return 'Staff';
    }
    if (person.icPassport.trim().isNotEmpty || person.company.trim().isNotEmpty) {
      return 'Others';
    }
    return 'Unknown';
  }

  List<_DetailField> _detailFieldsFor(Borrower person) {
    final category = _inferBorrowerCategory(person);
    final fields = <_DetailField>[];

    if (person.name.trim().isNotEmpty) {
      fields.add(_DetailField('Name', person.name));
    }

    if (category == 'Staff') {
      if (person.department.trim().isNotEmpty) {
        fields.add(_DetailField('Department', person.department));
      }
      if (person.phone.trim().isNotEmpty) {
        fields.add(_DetailField('Phone', person.phone));
      }
      if (person.staffFrom.trim().isNotEmpty) {
        fields.add(_DetailField('Staff From', person.staffFrom));
      }
    } else if (category == 'Others') {
      if (person.icPassport.trim().isNotEmpty) {
        fields.add(_DetailField('IC / Passport', person.icPassport));
      }
      if (person.phone.trim().isNotEmpty) {
        fields.add(_DetailField('Phone', person.phone));
      }
      if (person.company.trim().isNotEmpty) {
        fields.add(_DetailField('Company', person.company));
      }
      if (person.department.trim().isNotEmpty) {
        fields.add(_DetailField('Department', person.department));
      }
    } else {
      if (person.icPassport.trim().isNotEmpty) {
        fields.add(_DetailField('IC / Passport', person.icPassport));
      }
      if (person.phone.trim().isNotEmpty) {
        fields.add(_DetailField('Phone', person.phone));
      }
      if (person.company.trim().isNotEmpty) {
        fields.add(_DetailField('Company', person.company));
      }
      if (person.department.trim().isNotEmpty) {
        fields.add(_DetailField('Department', person.department));
      }
      if (person.staffFrom.trim().isNotEmpty) {
        fields.add(_DetailField('Staff From', person.staffFrom));
      }
    }

    return fields;
  }

  Future<void> _showPersonDetails(BuildContext context, Borrower person) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final detailFields = _detailFieldsFor(person);

        return AlertDialog(
          title: Text(person.name.isNotEmpty ? person.name : 'Saved Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detailFields.map((field) => _DetailRow(label: field.label, value: field.value)).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _editPerson(context, person);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _confirmDeletePerson(context, person);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPerson(BuildContext context, Borrower person) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: person.name);
    final icController = TextEditingController(text: person.icPassport);
    final phoneController = TextEditingController(text: person.phone);
    final companyController = TextEditingController(text: person.company);
    final departmentController = TextEditingController(text: person.department);
    final staffFromController = TextEditingController(text: person.staffFrom);
    String? selectedStaffFrom = person.staffFrom.trim().isEmpty ? null : person.staffFrom.trim();

    final messenger = ScaffoldMessenger.maybeOf(context);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Saved Person'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EditableField(controller: nameController, label: 'Name', requiredField: true),
                  _EditableField(controller: icController, label: 'IC / Passport'),
                  _EditableField(controller: phoneController, label: 'Phone'),
                  _EditableField(controller: companyController, label: 'Company'),
                  _EditableField(controller: departmentController, label: 'Department'),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return DropdownButtonFormField<String>(
                        initialValue: selectedStaffFrom,
                        decoration: InputDecoration(
                          labelText: 'Staff From',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _staffFromOptions
                            .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStaffFrom = value;
                            staffFromController.text = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (person.staffFrom.trim().isNotEmpty && (value == null || value.trim().isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      );
                    },
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
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      return;
    }

    await KeyRecordRepository.updateSavedBorrowerProfile(
      original: person,
      updated: Borrower(
        name: nameController.text.trim(),
        icPassport: icController.text.trim(),
        phone: phoneController.text.trim(),
        company: companyController.text.trim(),
        department: departmentController.text.trim(),
        staffFrom: staffFromController.text.trim(),
      ),
      recordedBy: AuthService.activeUser,
    );

    if (!mounted || messenger == null) {
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Saved person updated.')),
    );

    nameController.dispose();
    icController.dispose();
    phoneController.dispose();
    companyController.dispose();
    departmentController.dispose();
    staffFromController.dispose();
  }

  Future<void> _confirmDeletePerson(BuildContext context, Borrower person) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Saved Person'),
          content: Text('Delete "${person.name}" from saved persons?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await KeyRecordRepository.deleteSavedBorrowerProfile(person);

    if (!mounted || messenger == null) {
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Saved person deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Saved Persons'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Borrower>>(
          stream: KeyRecordRepository.watchSavedBorrowers(),
          builder: (context, snapshot) {
            final persons = snapshot.data ?? const <Borrower>[];

            if (snapshot.connectionState == ConnectionState.waiting && persons.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (persons.isEmpty) {
              return const Center(child: Text('No saved persons yet.'));
            }

            final staffCount = persons.where((person) => _inferBorrowerCategory(person) == 'Staff').length;
            final othersCount = persons.where((person) => _inferBorrowerCategory(person) == 'Others').length;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: persons.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E5E8)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Staff',
                            count: staffCount,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Others',
                            count: othersCount,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final person = persons[index - 1];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E5E8)),
                  ),
                  child: ListTile(
                    onTap: () => _showPersonDetails(context, person),
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(person.name),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value.isNotEmpty ? value : '—'),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller,
    required this.label,
    this.requiredField = false,
  });

  final TextEditingController controller;
  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
