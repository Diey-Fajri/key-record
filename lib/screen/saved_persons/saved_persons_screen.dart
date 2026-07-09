import 'package:flutter/material.dart';

import '../../services/key_repository.dart';

class SavedPersonsScreen extends StatelessWidget {
  const SavedPersonsScreen({super.key});

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
