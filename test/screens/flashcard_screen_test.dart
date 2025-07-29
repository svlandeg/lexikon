import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/flashcard_screen.dart';
import 'package:lexikon/vocabulary.dart';

void main() {
  group('FlashcardScreen', () {
    // Mock French vocabulary
    final frenchEntries = [
      TextEntry(source: 'cat', target: 'chat'),
      TextEntry(source: 'dog', target: 'chien'),
      TextEntry(source: 'fish', target: 'poisson'),
    ];
          final vocabulary = TextVocabulary(
      id: 'test-vocab-flash',
      name: 'Test French',
      entries: frenchEntries,
      sourceLanguage: 'English',
      targetLanguage: 'French',
      sourceReadingDirection: TextDirection.ltr,
      targetReadingDirection: TextDirection.ltr,
    );

    testWidgets('renders initial flashcard', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardScreen(
            vocabulary: vocabulary,
            count: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show source language label
      expect(find.text('English:'), findsOneWidget);
      // Should show one of the source words (order-independent)
      final shownWordFinder = find.byWidgetPredicate(
        (w) => w is Text && frenchEntries.map((e) => e.source).contains(w.data),
      );
      expect(shownWordFinder, findsOneWidget);
      final shownWord = (tester.widget<Text>(shownWordFinder)).data!;
      expect(frenchEntries.map((e) => e.source), contains(shownWord));
      // Should show input field and submit button
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Submit'), findsOneWidget);
      // Should show progress
      expect(find.textContaining('Progress:'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('properly handles correct answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardScreen(
            vocabulary: vocabulary,
            count: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the shown English word (order-independent)
      final shownWordFinder = find.byWidgetPredicate(
        (w) => w is Text && frenchEntries.map((e) => e.source).contains(w.data),
      );
      expect(shownWordFinder, findsOneWidget);
      final shownWord = (tester.widget<Text>(shownWordFinder)).data!;
      final correctFrench = frenchEntries.firstWhere((e) => e.source == shownWord).target;

      // Enter the correct French translation
      await tester.enterText(find.byType(TextField), correctFrench);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      // Should show green feedback with 'Correct!'
      final feedbackFinder = find.textContaining('Correct!');
      expect(feedbackFinder, findsOneWidget);
      final feedbackWidget = tester.widget<Text>(feedbackFinder);
      expect(feedbackWidget.style?.color, correctC);

      // Tap 'Next' to advance
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Progress should increase
      expect(find.textContaining('Progress: 2 /'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('properly handles incorrect answer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardScreen(
            vocabulary: vocabulary,
            count: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter an incorrect French translation
      await tester.enterText(find.byType(TextField), 'pasunepipe');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pumpAndSettle();

      // Should show red feedback with 'Incorrect.'
      final feedbackFinder = find.textContaining('Incorrect.');
      expect(feedbackFinder, findsOneWidget);
      final feedbackWidget = tester.widget<Text>(feedbackFinder);
      expect(feedbackWidget.style?.color, incorrectC);

      // Tap 'Next' to advance
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Progress should increase
      expect(find.textContaining('Progress: 2 /'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
} 