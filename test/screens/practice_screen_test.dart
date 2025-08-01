import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/screens/practice_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PracticeScreen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows empty state when no vocabularies', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      expect(find.text('No vocabularies available'), findsOneWidget);
      expect(find.text('Create a vocabulary first to start practicing'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    });

    testWidgets('shows vocabulary selector and practice options', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          '{"type":"text","id":"1","name":"TestVocab","sourceLanguage":"English","targetLanguage":"Spanish","entries":[{"type":"text","source":"hello","target":"hola"}],"sourceReadingDirection":"ltr","targetReadingDirection":"ltr"}'
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Select Vocabulary:'), findsOneWidget);
      expect(find.text('TestVocab (1 entries)'), findsOneWidget);
      expect(find.text('Practice Options:'), findsOneWidget);
      expect(find.text('Flashcards'), findsOneWidget);
      expect(find.text('Word Search'), findsOneWidget);
    });

    testWidgets('disables practice options for an empty vocabulary', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          '{"type":"text","id":"2","name":"EmptyVocab","sourceLanguage":"English","targetLanguage":"French","entries":[],"sourceReadingDirection":"ltr","targetReadingDirection":"ltr"}'
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('EmptyVocab (0 entries)'), findsOneWidget);
      expect(find.text('This vocabulary has no words yet'), findsOneWidget);
      expect(find.text('Add some words to start practicing'), findsOneWidget);
      expect(find.text('Flashcards'), findsNothing);
      expect(find.text('Word Search'), findsNothing);
    });

    testWidgets('navigates to FlashcardScreen with a single-entry vocabulary', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          '{"type":"text","id":"3","name":"NavVocab","sourceLanguage":"English","targetLanguage":"German","entries":[{"type":"text","source":"cat","target":"Katze"}],"sourceReadingDirection":"ltr","targetReadingDirection":"ltr"}'
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flashcards'));
      await tester.pumpAndSettle();
      // Should show single-word dialog
      expect(find.text('There is only one word in this vocabulary.'), findsOneWidget);
      // Confirm start (simulate tapping 'Start')
      await tester.tap(find.widgetWithText(TextButton, 'Start'));
      await tester.pumpAndSettle();
      // Should navigate to FlashcardScreen (AppBar title)
      expect(find.text('Flashcards'), findsOneWidget);
    });

    testWidgets('navigates to FlashcardScreen with a multi-entry vocabulary', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          '{"type":"text","id":"4","name":"NavVocabMulti","sourceLanguage":"English","targetLanguage":"German","entries":[{"type":"text","source":"cat","target":"Katze"},{"type":"text","source":"dog","target":"Hund"}],"sourceReadingDirection":"ltr","targetReadingDirection":"ltr"}'
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flashcards'));
      await tester.pumpAndSettle();
      // Should show dialog for word count selection
      expect(find.text('How many words to practice?'), findsOneWidget);
      // Confirm start (simulate tapping 'Start')
      await tester.tap(find.widgetWithText(TextButton, 'Start'));
      await tester.pumpAndSettle();
      // Should navigate to FlashcardScreen (AppBar title)
      expect(find.text('Flashcards'), findsOneWidget);
    });

    testWidgets('navigates to WordSearchScreen', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          '{"type":"text","id":"4","name":"NavVocab2","sourceLanguage":"English","targetLanguage":"Italian","entries":[{"type":"text","source":"dog","target":"cane"}],"sourceReadingDirection":"ltr","targetReadingDirection":"ltr"}'
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: PracticeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Word Search'));
      await tester.pumpAndSettle();
      // Should navigate to WordSearchScreen (AppBar title)
      expect(find.text('Word Search'), findsOneWidget);
    });
  });
} 