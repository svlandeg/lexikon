import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/vocabulary.dart';

void main() {
  group('ReadingDirection', () {
    test('printed correctly', () {
      expect(ReadingDirection.leftToRight.displayName, 'Left to Right');
      expect(ReadingDirection.rightToLeft.displayName, 'Right to Left');
    });
    test('parsed correctly', () {
      expect(ReadingDirection.fromString('leftToRight'), ReadingDirection.leftToRight);
      expect(ReadingDirection.fromString('left to right'), ReadingDirection.leftToRight);
      expect(ReadingDirection.fromString('rightToLeft'), ReadingDirection.rightToLeft);
      expect(ReadingDirection.fromString('right to left'), ReadingDirection.rightToLeft);
      expect(ReadingDirection.fromString('unknown'), ReadingDirection.leftToRight);
      expect(ReadingDirection.fromString(''), ReadingDirection.leftToRight);
    });
  });

  group('Vocabulary', () {
    final entryList = [Entry(source: 'cat', target: 'gato'), Entry(source: 'dog', target: 'perro')];
    final vocab = Vocabulary(
      id: '1',
      name: 'TestName',
      sourceLanguage: 'English',
      targetLanguage: 'Spanish',
      sourceReadingDirection: ReadingDirection.leftToRight,
      // while Spanish is LTR, setting it to RTL here just for testing
      targetReadingDirection: ReadingDirection.rightToLeft,
      entries: entryList,
    );
    test('contents', () {
      expect(vocab.name, 'TestName');
      expect(vocab.sourceLanguage, 'English');
      expect(vocab.targetLanguage, 'Spanish');
      expect(vocab.sourceReadingDirection, ReadingDirection.leftToRight);
      expect(vocab.targetReadingDirection, ReadingDirection.rightToLeft);
      expect(vocab.entries.length, entryList.length);
      expect(vocab.entries[0].source, 'cat');
      expect(vocab.entries[0].target, 'gato');
      expect(vocab.entries[1].source, 'dog');
      expect(vocab.entries[1].target, 'perro');
    });

    test('copyWith functionality', () {
      final updated1 = vocab.copyWith(name: 'Updated', entries: []);
      expect(updated1.name, 'Updated');
      expect(updated1.entries, isEmpty);
      expect(updated1.id, vocab.id);

      final updated2 = vocab.copyWith(sourceLanguage: 'French', targetLanguage: 'German');
      expect(updated2.sourceLanguage, 'French');
      expect(updated2.targetLanguage, 'German');

      final updated3 = vocab.copyWith(
        sourceReadingDirection: ReadingDirection.rightToLeft,
        targetReadingDirection: ReadingDirection.leftToRight,
      );
      expect(updated3.sourceReadingDirection, ReadingDirection.rightToLeft);
      expect(updated3.targetReadingDirection, ReadingDirection.leftToRight);
    });
  });
} 