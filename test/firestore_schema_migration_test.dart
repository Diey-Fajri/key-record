import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/services/key_repository.dart';

void main() {
  group('Firestore schema migration helpers', () {
    test('normalizes Others category and derives labelNo', () {
      final payload = KeyRecordRepository.buildNormalizedKeyFirestorePayload(
        data: {
          'category': 'Others',
          'keyName': 'Test Key',
          'metadata': {'level': '12', 'zone': 'A1'},
        },
        keyName: 'Test Key',
      );

      expect(payload['category'], 'Others Key');
      expect(payload['metadata']['labelNo'], 'Test Key');
      expect(payload['metadata']['level'], isNull);
      expect(payload['metadata']['zone'], 'A1');
    });
  });
}
