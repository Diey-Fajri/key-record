import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/key_repository.dart';

class SavedPersonsScreen extends StatefulWidget {
  const SavedPersonsScreen({super.key});

  @override
  State<SavedPersonsScreen> createState() => _SavedPersonsScreenState();
}

class _SavedPersonsScreenState extends State<SavedPersonsScreen> {
  Future<void> _showPersonDetails(BuildContext context, Borrower person) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(person.name.isNotEmpty ? person.name : 'Saved Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Name', value: person.name),
              _DetailRow(label: 'IC / Passport', value: person.icPassport),
              _DetailRow(label: 'Phone', value: person.phone),
              _DetailRow(label: 'Company', value: person.company),
              _DetailRow(label: 'Department', value: person.department),
            ],
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
      ),
      recordedBy: AuthService.activeUser,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved person updated.')),
      );
    }

    nameController.dispose();
    icController.dispose();
    phoneController.dispose();
    companyController.dispose();
    departmentController.dispose();
  }

  Future<void> _confirmDeletePerson(BuildContext context, Borrower person) async {
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved person deleted.')),
      );
    }
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

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: persons.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final person = persons[index];
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
                    subtitle: Text(
                      [
                        if (person.department.trim().isNotEmpty) person.department.trim(),
                        if (person.phone.trim().isNotEmpty) person.phone.trim(),
                        if (person.company.trim().isNotEmpty) person.company.trim(),
                      ].join(' • '),
                    ),
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
