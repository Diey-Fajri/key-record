import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/login/setup_account_screen.dart';

void main() {
  testWidgets('setup account screen does not require password fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SetupAccountScreen()));

    expect(find.text('Member username'), findsOneWidget);
    expect(find.text('Approved member email'), findsOneWidget);
    expect(find.text('6-digit password'), findsOneWidget);
    expect(find.text('Confirm 6-digit password'), findsOneWidget);
  });
}
