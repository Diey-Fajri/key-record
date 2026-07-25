import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/all_keys/all_keys_screen.dart';

void main() {
  group('allKeysFolderOrder', () {
    test('places non-zone categories before zone folders', () {
      expect(allKeysFolderOrder('High Risk'), lessThan(allKeysFolderOrder('Zone A')));
      expect(allKeysFolderOrder('Master Key'), lessThan(allKeysFolderOrder('Zone A')));
      expect(allKeysFolderOrder('Others Key'), lessThan(allKeysFolderOrder('Zone A')));
    });

    test('keeps the requested category priority', () {
      expect(allKeysFolderOrder('High Risk'), lessThan(allKeysFolderOrder('Master Key')));
      expect(allKeysFolderOrder('Master Key'), lessThan(allKeysFolderOrder('Others Key')));
    });
  });
}
