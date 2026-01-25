// Basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lexikon/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LexikonApp());

    // Verify that the app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('App starts directly on Practice screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LexikonApp());
    await tester.pumpAndSettle();
    // Should show empty practice text when no vocabularies exist
    expect(find.text('No vocabularies available'), findsOneWidget);
    expect(find.text('Create a vocabulary first to start practicing'), findsOneWidget);
    // AppBar title
    expect(find.text('LexiKon - Practice'), findsOneWidget);
    // BottomNavigationBar should be present
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    // Practice tab should be selected (index 0)
    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.currentIndex, 0);
  });

  testWidgets('MainScreen switches to Vocabulary tab', (WidgetTester tester) async {
    await tester.pumpWidget(const LexikonApp());
    await tester.pumpAndSettle();
    // Tap the Vocabularies tab
    await tester.tap(find.byIcon(Icons.book));
    await tester.pumpAndSettle();
    // Should show empty vocabularies text
    expect(find.text('No vocabularies yet'), findsOneWidget);
    expect(find.text('Create your first vocabulary to get started'), findsOneWidget);
    // AppBar title
    expect(find.text('LexiKon - Vocabularies'), findsOneWidget);
  });
}
