import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/scrambledword_screen.dart';
import 'package:lexikon/vocabulary.dart';

void main() {
  group('ScrambledWordScreen', () {
    testWidgets('shows source word and scrambled chips', (WidgetTester tester) async {
      final vocab = Vocabulary(
        id: '1',
        name: 'TestVocab',
        sourceLanguage: 'English',
        targetLanguage: 'Spanish',
        sourceReadingDirection: TextDirection.ltr,
        targetReadingDirection: TextDirection.ltr,
        entries: [Entry(source: 'cat', target: 'gato')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScrambledWordScreen(vocabulary: vocab, count: 1),
        ),
      );

      // Source word is shown
      expect(find.text('English:'), findsOneWidget);
      expect(find.text('cat'), findsOneWidget);

      // Target language label is shown
      expect(find.text('Spanish:'), findsOneWidget);

      // Chips for each letter in 'gato' are shown
      for (final letter in 'tgao'.split('')) {
        expect(find.text(letter), findsWidgets); // could be more than one if scrambled
      }
      
      // The 'Correct!' message should not be shown initially
      expect(find.text('Correct!'), findsNothing);

      // Simulate dragging chips to correct order
      // Find all chips
      final chipFinder = find.byType(Chip);
      expect(chipFinder, findsNWidgets(4));

      // Drag and reorder chips to spell 'gato'
      // This is a bit tricky in tests, so we can skip the drag and just check the initial state for now
      // (A more advanced test could simulate the drag-and-drop)

    });
  });
} 