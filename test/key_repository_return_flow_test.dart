import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/services/key_repository.dart' as repository;

void main() {
  group('KeyRecordRepository return flow', () {
    test('uses the incoming Firestore doc id when building the returned key record', () {
      final existing = repository.KeyRecord(
        docId: 'old-doc',
        keyId: 'K1',
        zone: 'Zone',
        keyName: 'Key',
        borrowerName: 'kim',
        icPassport: '123',
        phoneNumber: '012',
        company: 'ABC',
        purpose: 'test',
        status: 'In Use',
        takenAt: DateTime(2025, 1, 1),
        category: 'Zone',
      );

      final incoming = repository.KeyRecord(
        docId: 'new-doc',
        keyId: 'K1',
        zone: 'Zone',
        keyName: 'Key',
        borrowerName: 'kim',
        icPassport: '123',
        phoneNumber: '012',
        company: 'ABC',
        purpose: 'test',
        status: 'In Use',
        takenAt: DateTime(2025, 1, 1),
        category: 'Zone',
      );

      final returned = repository.KeyRecordRepository.buildReturnedKeyRecord(
        existing,
        incoming,
      );

      expect(returned.docId, 'new-doc');
      expect(returned.status, 'Available');
      expect(returned.borrowerName, isEmpty);
      expect(returned.icPassport, isEmpty);
      expect(returned.phoneNumber, isEmpty);
      expect(returned.company, isEmpty);
      expect(returned.purpose, isEmpty);
    });
  });
}
