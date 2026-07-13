import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/services/key_repository.dart' as repository;

void main() {
  group('KeyRecordRepository identity matching', () {
    test('resolves actor from the signed-in user without falling back to Security Admin', () {
      expect(repository.KeyRecordRepository.resolveActor(''), isEmpty);
      expect(repository.KeyRecordRepository.resolveActor('Alice'), 'Alice');
    });

    test('matches records by logical identity when doc IDs differ', () {
      final source = repository.KeyRecord(
        docId: '',
        keyId: 'KA01',
        zone: 'L3',
        keyName: 'Master Key KA01',
        borrowerName: '',
        icPassport: '',
        phoneNumber: '',
        company: '',
        purpose: '',
        status: 'Available',
        takenAt: DateTime(2026, 7, 1),
        category: 'Master Key',
        metadata: {'masterKey': 'KA01', 'level': 'L3'},
      );

      final target = repository.KeyRecord(
        docId: 'firestore-doc-id',
        keyId: 'KA01',
        zone: 'L3',
        keyName: 'Master Key KA01',
        borrowerName: '',
        icPassport: '',
        phoneNumber: '',
        company: '',
        purpose: '',
        status: 'Available',
        takenAt: DateTime(2026, 7, 2),
        category: 'Master Key',
        metadata: {'masterKey': 'KA01', 'level': 'L3'},
      );

      expect(repository.KeyRecordRepository.recordsMatch(source, target), isTrue);
    });
  });
}
