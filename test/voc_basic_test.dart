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
      targetReadingDirection: ReadingDirection.leftToRight,
      entries: entryList,
    );
    test('contents', () {
      expect(vocab.name, 'TestName');
      expect(vocab.sourceLanguage, 'English');
      expect(vocab.targetLanguage, 'Spanish');
      expect(vocab.sourceReadingDirection, ReadingDirection.leftToRight);
      expect(vocab.targetReadingDirection, ReadingDirection.leftToRight);
      expect(vocab.entries.length, entryList.length);
      expect(vocab.entries[0].source, 'cat');
      expect(vocab.entries[0].target, 'gato');
      expect(vocab.entries[1].source, 'dog');
      expect(vocab.entries[1].target, 'perro');
    });
  });
} 