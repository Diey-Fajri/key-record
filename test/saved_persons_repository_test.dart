import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/services/key_repository.dart';

void main() {
  test('updateSavedBorrowerProfile replaces the cached saved person', () async {
    await KeyRecordRepository.saveBorrowerProfile(
      Borrower(
        name: 'Ali',
        icPassport: '900101-01-0001',
        phone: '0123456789',
        company: 'ABC',
        department: 'Ops',
      ),
    );

    final original = (await KeyRecordRepository.watchSavedBorrowers().first)
        .firstWhere((person) => person.name == 'Ali');

    await KeyRecordRepository.updateSavedBorrowerProfile(
      original: original,
      updated: Borrower(
        name: 'Ali Ahmad',
        icPassport: '900101-01-0001',
        phone: '0123456789',
        company: 'ABC',
        department: 'Ops',
      ),
    );

    final updatedPersons = await KeyRecordRepository.watchSavedBorrowers().first;
    expect(updatedPersons.any((person) => person.name == 'Ali Ahmad'), isTrue);
    expect(updatedPersons.any((person) => person.name == 'Ali'), isFalse);
  });

  test('deleteSavedBorrowerProfile removes the saved person from the cache', () async {
    await KeyRecordRepository.saveBorrowerProfile(
      Borrower(
        name: 'Siti',
        icPassport: '820202-02-2222',
        phone: '0133334444',
        company: 'XYZ',
        department: 'HR',
      ),
    );

    final person = (await KeyRecordRepository.watchSavedBorrowers().first)
        .firstWhere((item) => item.name == 'Siti');

    await KeyRecordRepository.deleteSavedBorrowerProfile(person);

    final remaining = await KeyRecordRepository.watchSavedBorrowers().first;
    expect(remaining.any((item) => item.name == 'Siti'), isFalse);
  });
}
