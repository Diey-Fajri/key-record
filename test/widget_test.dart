// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

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

    // Open detail for one key in use.
    final detailButton = find.text('Detail').first;
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    // Verify take-key detail information is visible.
    expect(find.text('Take Key Details'), findsOneWidget);
    expect(find.text('IC / Passport'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });
}
