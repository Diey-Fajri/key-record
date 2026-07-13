// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_record/screen/home/home_screen.dart';

void main() {
  testWidgets('Home screen shows key record dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Key Record'), findsOneWidget);
    expect(find.text('Keys Currently In Use'), findsOneWidget);
    
    // Verify the UI structure is present - check for search functionality and navigation
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('Unit Kawalan CCTV'), findsOneWidget);
  });
}
