import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/models.dart';

void main() {
  group('ReadingDirection', () {
    test('displayName returns "Left to Right" for leftToRight', () {
      expect(ReadingDirection.leftToRight.displayName, 'Left to Right');
    });
    test('displayName returns "Right to Left" for rightToLeft', () {
      expect(ReadingDirection.rightToLeft.displayName, 'Right to Left');
    });
    test('fromString returns leftToRight for "leftToRight"', () {
      expect(ReadingDirection.fromString('leftToRight'), ReadingDirection.leftToRight);
    });
    test('fromString returns rightToLeft for "rightToLeft"', () {
      expect(ReadingDirection.fromString('rightToLeft'), ReadingDirection.rightToLeft);
    });
    test('fromString returns leftToRight for unknown string', () {
      expect(ReadingDirection.fromString('unknown'), ReadingDirection.leftToRight);
    });
    test('fromString returns leftToRight for empty string', () {
      expect(ReadingDirection.fromString(''), ReadingDirection.leftToRight);
    });
  });

  group('Entry', () {
    test('toJson returns correct map', () {
      final entry = Entry(source: 'hello', target: 'hola');
      expect(entry.toJson(), {'source': 'hello', 'target': 'hola'});
    });
    test('fromJson creates correct Entry', () {
      final json = {'source': 'hello', 'target': 'hola'};
      final entry = Entry.fromJson(json);
      expect(entry.source, 'hello');
      expect(entry.target, 'hola');
    });
  });
} 