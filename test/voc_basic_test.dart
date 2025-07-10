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

  group('Entry', () {
    test('toJson', () {
      final entry = Entry(source: 'hello', target: 'hola');
      expect(entry.toJson(), {'source': 'hello', 'target': 'hola'});
    });
    test('fromJson', () {
      final json = {'source': 'hello', 'target': 'hola'};
      final entry = Entry.fromJson(json);
      expect(entry.source, 'hello');
      expect(entry.target, 'hola');
    });
  });
} 