import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/screens/practice/scrambledword_screen.dart';
import 'package:lexikon/voc/vocabulary.dart';
import 'package:lexikon/voc/entry.dart';

void main() {
  group('ScrambledWordScreen', () {
    testWidgets('shows source word and scrambled chips', (WidgetTester tester) async {
      final vocab = TextVocabulary(
        id: '1',
        name: 'TestVocab',
        sourceLanguage: 'English',
        targetLanguage: 'Spanish',
        sourceReadingDirection: TextDirection.ltr,
        targetReadingDirection: TextDirection.ltr,
        entries: [TextEntry(source: 'cat', target: 'gato')],
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

      // Chips for each letter in 'gato' are shown (in any order)
      for (final letter in 'tgao'.split('')) {
        expect(find.text(letter), findsWidgets); // could be more than one if scrambled
      }
      // The 'Correct!' message should not be shown initially
      expect(find.text('Correct!'), findsNothing);
    });

    testWidgets('scrambled word is never accidentally correct', (WidgetTester tester) async {
      final target_word = 'من';
      final target_length = target_word.length;
      
      final vocab = TextVocabulary(
        id: '1',
        name: 'TestVocab',
        sourceLanguage: 'English',
        targetLanguage: 'Arabic',
        sourceReadingDirection: TextDirection.ltr,
        targetReadingDirection: TextDirection.rtl,
        entries: [TextEntry(source: 'who', target: target_word)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScrambledWordScreen(vocabulary: vocab, count: 1),
        ),
      );

      // Wait for the widget to fully build
      await tester.pumpAndSettle();

      // The 'Correct!' message should not be shown initially
      expect(find.text('Correct!'), findsNothing);

      // Get all the letter chips
      final letterChips = find.byType(Chip);
      expect(letterChips, findsNWidgets(target_length)); 

      // Extract the text from each chip
      final List<String> displayedLetters = [];
      for (int i = 0; i < target_length; i++) {
        final chip = tester.widget<Chip>(letterChips.at(i));
        final text = (chip.label as Text).data!;
        displayedLetters.add(text);
      }
      
      // Verify all letters from the target word are present
      final targetLetters = target_word.split('')..sort();
      final displayedLettersSorted = displayedLetters..sort();
      expect(displayedLettersSorted, equals(targetLetters),
          reason: 'All letters from target word should be present');

      // For RTL text, the visual order is reversed from the logical order
      // So we need to reverse the displayed letters to get the actual word
      final actualWord = vocab.targetReadingDirection == TextDirection.rtl 
          ? displayedLetters.reversed.join()
          : displayedLetters.join();

      // Verify the displayed letters don't spell the correct word
      expect(actualWord, isNot(target_word), 
          reason: 'Scrambled word should not be correct');
    });
  });
} 