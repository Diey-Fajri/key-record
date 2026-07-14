import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/register/take_key_detail_screen.dart';
import 'package:key_record/services/key_repository.dart';

void main() {
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
}
