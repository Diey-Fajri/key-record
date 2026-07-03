// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_record/app.dart';

void main() {
  testWidgets('Home screen shows key record dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the dashboard is rendered.
    expect(find.text('Key Record'), findsOneWidget);
    expect(find.text('Keys Currently In Use'), findsOneWidget);
    expect(find.text('Master Key A-01'), findsOneWidget);
    expect(find.text('In Use'), findsWidgets);

    // Open Smart Detail for one in-use key.
    final detailButton = find.byKey(
      const ValueKey('smart-detail-Master Key A-01'),
    );

    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    // Verify smart detail information is visible.
    expect(find.text('Smart Detail'), findsOneWidget);
    expect(find.text('Borrower Name'), findsOneWidget);
    expect(find.text('Returned'), findsOneWidget);
  });
}
