import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/vocabulary_screen.dart';
import 'package:lexikon/vocabulary.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('VocabularyListScreen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows empty state when no vocabularies', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      expect(find.text('No vocabularies yet'), findsOneWidget);
      expect(find.text('Create your first vocabulary to get started'), findsOneWidget);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
    });

    testWidgets('can add a vocabulary', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Vocab');
      await tester.enterText(find.byType(TextFormField).at(1), 'English');
      await tester.enterText(find.byType(TextFormField).at(2), 'Spanish');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
      await tester.pumpAndSettle();
      expect(find.text('Test Vocab'), findsOneWidget);
      expect(find.text('English → Spanish (0 entries)'), findsOneWidget);
    });

    testWidgets('can delete a vocabulary', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          jsonEncode(Vocabulary(
            id: '1',
            name: 'ToDelete',
            sourceLanguage: 'English',
            targetLanguage: 'Spanish',
            entries: [],
          ).toJson()),
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('ToDelete'), findsOneWidget);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete));
      await tester.pumpAndSettle();
      expect(find.text('Delete Vocabulary'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('ToDelete'), findsNothing);
    });

    testWidgets('can navigate to vocabulary detail', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          jsonEncode(Vocabulary(
            id: '2',
            name: 'DetailTest',
            sourceLanguage: 'English',
            targetLanguage: 'French',
            entries: [],
          ).toJson()),
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DetailTest'));
      await tester.pumpAndSettle();
      expect(find.text('DetailTest'), findsWidgets); // AppBar and detail
      expect(find.text('No words yet'), findsOneWidget);
    });

    testWidgets('can edit a vocabulary', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          jsonEncode(Vocabulary(
            id: '3',
            name: 'EditMe',
            sourceLanguage: 'English',
            targetLanguage: 'German',
            entries: [],
          ).toJson()),
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'EditedName');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('EditedName'), findsOneWidget);
      expect(find.text('EditMe'), findsNothing);
    });
  });
} 