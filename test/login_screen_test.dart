import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/login/login_screen.dart';

void main() {
  testWidgets('login screen asks for email first and hides password field', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Member email'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });
}
