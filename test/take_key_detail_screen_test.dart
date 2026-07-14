import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/home/home_screen.dart';
import 'package:key_record/screen/notifications/notifications_screen.dart';
import 'package:key_record/screen/register/take_key_detail_screen.dart';
import 'package:key_record/screen/smart_detail/smart_detail_screen.dart';
import 'package:key_record/services/key_repository.dart';

void main() {
  test('filterInUseKeysForDashboard removes completed return keys', () {
    final keys = <KeyRecord>[
      KeyRecord(
        keyId: 'K-001',
        zone: 'Zone',
        keyName: 'Test Key',
        borrowerName: 'Ali',
        icPassport: '123',
        phoneNumber: '012',
        company: 'ABC',
        purpose: 'Testing',
        status: 'In Use',
        takenAt: DateTime(2025, 1, 1),
        category: 'Zone',
      ),
      KeyRecord(
        keyId: 'K-002',
        zone: 'Zone',
        keyName: 'Test Key 2',
        borrowerName: 'Ali',
        icPassport: '123',
        phoneNumber: '012',
        company: 'ABC',
        purpose: 'Testing',
        status: 'In Use',
        takenAt: DateTime(2025, 1, 1),
        category: 'Zone',
      ),
    ];

    final filtered = filterInUseKeysForDashboard(
      keys,
      <String>{'K-001'.toUpperCase()},
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.keyId, 'K-002');
  });

  test('extractNotificationKeyId reads a key id from common payload names', () {
    expect(
      extractNotificationKeyId(<String, dynamic>{'keyId': 'K-001'}),
      'K-001',
    );
    expect(
      extractNotificationKeyId(<String, dynamic>{'data': {'key': 'K-002'}}),
      null,
    );
  });

  testWidgets('detail screen no longer shows a return action', (tester) async {
    final record = KeyRecord(
      keyId: 'K-001',
      zone: 'Zone',
      keyName: 'Test Key',
      borrowerName: 'Ali',
      icPassport: '123',
      phoneNumber: '012',
      company: 'ABC',
      purpose: 'Testing',
      status: 'In Use',
      takenAt: DateTime(2025, 1, 1),
      category: 'Zone',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TakeKeyDetailScreen(record: record),
      ),
    );

    expect(find.text('Return Key'), findsNothing);
    expect(find.text('Returning...'), findsNothing);
  });

  testWidgets('dashboard return button becomes disabled immediately after first tap', (tester) async {
    final group = BorrowerKeyGroup(
      borrowerName: 'Ali',
      borrowerCategory: 'Staff',
      keys: [
        KeyRecord(
          keyId: 'K-002',
          zone: 'Zone',
          keyName: 'Test Key 2',
          borrowerName: 'Ali',
          icPassport: '123',
          phoneNumber: '012',
          company: 'ABC',
          purpose: 'Testing',
          status: 'In Use',
          takenAt: DateTime(2025, 1, 1),
          category: 'Zone',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyInUseCard(
            group: group,
            onDetail: (_) {},
            onReturn: (_) {},
            onReturnAll: () {},
            returningIds: const {},
          ),
        ),
      ),
    );

    final button = find.widgetWithText(FilledButton, 'Return');
    expect(button, findsOneWidget);
  });

  testWidgets('read-only detail field updates when the value changes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadOnlyDetailField(label: 'Key Name', value: 'Old value'),
        ),
      ),
    );

    expect(find.text('Old value'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadOnlyDetailField(label: 'Key Name', value: 'New value'),
        ),
      ),
    );

    expect(find.text('New value'), findsOneWidget);
    expect(find.text('Old value'), findsNothing);
  });

  testWidgets('smart detail screen refreshes after repository update', (tester) async {
    final originalRecord = KeyRecordRepository.searchKeys('ADM-A01').firstWhere(
      (item) => item.keyId == 'ADM-A01',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SmartDetailScreen(record: originalRecord),
      ),
    );

    await tester.pump();

    final state = tester.state(find.byType(SmartDetailScreen));
    expect(state, isA<State<SmartDetailScreen>>());

    await KeyRecordRepository.updateRegisteredKeyDetails(
      keyId: originalRecord.keyId,
      zone: originalRecord.zone,
      keyName: '${originalRecord.keyName} Updated',
      category: originalRecord.category,
      status: originalRecord.status,
      recordedBy: 'tester',
      metadata: originalRecord.metadata,
    );

    await tester.pump();

    final currentState = tester.state(find.byType(SmartDetailScreen));
    expect(currentState, isA<State<SmartDetailScreen>>());

    await KeyRecordRepository.updateRegisteredKeyDetails(
      keyId: originalRecord.keyId,
      zone: originalRecord.zone,
      keyName: originalRecord.keyName,
      category: originalRecord.category,
      status: originalRecord.status,
      recordedBy: 'tester',
      metadata: originalRecord.metadata,
    );
  });
}
