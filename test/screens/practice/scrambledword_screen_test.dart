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
  });
} 