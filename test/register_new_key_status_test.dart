import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/register_new_key/register_new_key_screen.dart';

void main() {
  testWidgets(
    'Register new key screen offers Not Available as a status option',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterNewKeyScreen()));
      await tester.pumpAndSettle();

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsWidgets);

      await tester.tap(dropdowns.last);
      await tester.pumpAndSettle();

      expect(find.text('Not Available'), findsOneWidget);
    },
  );
}
