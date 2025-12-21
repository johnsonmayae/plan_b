// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plan_b_2nd_best/main.dart';
import 'package:plan_b_2nd_best/screens/home_screen.dart';

void main() {
  testWidgets('Home screen shows title and play button', (WidgetTester tester) async {
    // Set a larger test window size to avoid layout overflow.
    final binding = tester.binding;
    binding.window.physicalSizeTestValue = const Size(1200, 1200);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    // Build only the HomeScreen inside a MaterialApp to keep the test focused.
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Verify that the main title and primary action exist.
    expect(find.text('PLAN B'), findsOneWidget);
    expect(find.text('PLAY LOCAL'), findsOneWidget);
  });
}
