import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_record/screen/register_new_key/register_new_key_screen.dart';

void main() {
  testWidgets('hides level dropdown when category is Others', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterNewKeyScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Others').last);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration?.labelText == 'Level',
      ),
      findsNothing,
    );
  });
}
