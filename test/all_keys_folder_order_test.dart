import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/all_keys/all_keys_screen.dart';
import 'package:key_record/services/key_repository.dart';

void main() {
  group('allKeysFolderOrder', () {
    test('keeps High Risk out of the special folder order and treats it like level-based content', () {
      expect(allKeysFolderOrder('High Risk'), greaterThan(allKeysFolderOrder('Master Key')));
      expect(allKeysFolderOrder('High Risk'), greaterThan(allKeysFolderOrder('Others Key')));
      expect(allKeysFolderOrder('High Risk'), allKeysFolderOrder('L1'));
    });

    test('accepts the new master keys label', () {
      expect(allKeysFolderOrder('Master Keys'), allKeysFolderOrder('Master Key'));
    });

    test('does not treat High Risk status alone as a special folder category', () {
      final record = KeyRecord(
        keyId: 'K1',
        zone: 'L2',
        keyName: 'High Risk Key',
        borrowerName: '',
        icPassport: '',
        phoneNumber: '',
        company: '',
        purpose: '',
        status: 'High Risk',
        takenAt: DateTime.now(),
      );

      expect(shouldUseSpecialFolderForRecord(record), isFalse);
    });

    test('orders Zone before Lot before Roller Shutter in folder display', () {
      expect(allKeysFolderOrder('Zone A'), lessThan(allKeysFolderOrder('Lot')));
      expect(allKeysFolderOrder('Lot'), lessThan(allKeysFolderOrder('Roller Shutter')));
    });
  });
}
