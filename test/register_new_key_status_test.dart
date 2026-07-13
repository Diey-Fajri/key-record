import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_record/screen/register_new_key/register_new_key_screen.dart';

void main() {
  testWidgets(
    'Register new key screen offers Not Available as a status option',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: RegisterNewKeyScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final statusDropdownFinder = find.byWidgetPredicate((widget) {
        if (widget is! DropdownButtonFormField<String>) {
          return false;
        }
        final decoration = widget.decoration;
        return decoration.labelText == 'Status';
      });
      expect(statusDropdownFinder, findsOneWidget);

      await tester.tap(statusDropdownFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Not Available'), findsOneWidget);
    },
  );
}
