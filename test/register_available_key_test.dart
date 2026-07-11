import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/register/register.dart';

void main() {
  group('AvailableKey compact display', () {
    test('shows level and zone as the primary title for zone keys', () {
      final key = AvailableKey(
        docId: 'doc-1',
        keyId: 'key-1',
        zone: 'L2 / Zone A',
        name: 'Front Desk',
        status: 'Available',
        category: 'Zone',
        metadata: {'level': 'L2', 'zone': 'Zone A'},
      );

      expect(key.primaryTitle, 'L2 / Zone A');
      expect(key.secondaryTitle, 'Front Desk');
    });

    test('shows master key label for master key records', () {
      final key = AvailableKey(
        docId: 'doc-2',
        keyId: 'key-2',
        zone: 'L3',
        name: 'Executive',
        status: 'Available',
        category: 'Master Key',
        metadata: {'level': 'L3', 'masterKey': 'MASTER KEY KA01'},
      );

      expect(key.primaryTitle, 'Master Key KA01');
      expect(key.secondaryTitle, 'Executive');
    });

    test('shows lot label for lot records', () {
      final key = AvailableKey(
        docId: 'doc-3',
        keyId: 'key-3',
        zone: 'L1',
        name: 'Lot 01',
        status: 'Available',
        category: 'Lot',
        metadata: {'level': 'L1', 'lotKey': '18'},
      );

      expect(key.primaryTitle, 'Lot Level 1 / 18');
      expect(key.secondaryTitle, '');
    });

    test('shows roller shutter label for roller shutter records', () {
      final key = AvailableKey(
        docId: 'doc-4',
        keyId: 'key-4',
        zone: 'L4',
        name: 'Roller 04',
        status: 'Available',
        category: 'Roller Shutter',
        metadata: {'level': 'L4', 'rollerLevelNo': 'B2', 'rollerNumber': '282'},
      );

      expect(key.primaryTitle, 'Roller Shutter B2 / 282');
      expect(key.secondaryTitle, '');
    });

    test('uses the key name as the primary title for high-risk and other records', () {
      final key = AvailableKey(
        docId: 'doc-5',
        keyId: 'key-5',
        zone: 'Other',
        name: 'High Risk Key',
        status: 'Available',
        category: 'High Risk',
        metadata: {},
      );

      expect(key.primaryTitle, 'High Risk Key');
      expect(key.secondaryTitle, '');
    });
  });
}
