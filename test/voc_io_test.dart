import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/models.dart';

void main() {
  group('Entry JSON', () {
    final entry = Entry(source: 'hello', target: 'hola');
    test('toJson returns correct map', () {
      expect(entry.toJson(), {'source': 'hello', 'target': 'hola'});
    });
    test('fromJson creates correct Entry', () {
      final json = {'source': 'hello', 'target': 'hola'};
      final entry2 = Entry.fromJson(json);
      expect(entry2.source, 'hello');
      expect(entry2.target, 'hola');
    });
  });

  group('Vocabulary JSON', () {
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
    test('Vocab contents', () {
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
    test('Vocab toJson', () {
      final json = vocab.toJson();
      expect(json['id'], vocab.id);
      expect(json['name'], 'TestName');
      expect(json['sourceLanguage'], vocab.sourceLanguage);
      expect(json['targetLanguage'], vocab.targetLanguage);
      expect(json['sourceReadingDirection'], vocab.sourceReadingDirection.name);
      expect(json['targetReadingDirection'], vocab.targetReadingDirection.name);
      expect(json['entries'], isA<List<dynamic>>());
      // test content of entries
      expect(json['entries'][0]['source'], 'cat');
      expect(json['entries'][0]['target'], 'gato');
      expect(json['entries'][1]['source'], 'dog');
      expect(json['entries'][1]['target'], 'perro');
    });
    test('Vocab fromJson', () {
      final json = vocab.toJson();
      final vocab2 = Vocabulary.fromJson(json);
      expect(vocab2.id, vocab.id);
      expect(vocab2.name, vocab.name);
      expect(vocab2.sourceLanguage, vocab.sourceLanguage);
      expect(vocab2.targetLanguage, vocab.targetLanguage);
      expect(vocab2.sourceReadingDirection, vocab.sourceReadingDirection);
      expect(vocab2.targetReadingDirection, vocab.targetReadingDirection);
      expect(vocab2.entries.length, vocab.entries.length);
      expect(vocab2.entries[0].source, vocab.entries[0].source);
      expect(vocab2.entries[0].target, vocab.entries[0].target);
      expect(vocab2.entries[1].source, vocab.entries[1].source);
      expect(vocab2.entries[1].target, vocab.entries[1].target);
    });
  });

  group('copyWith functionality', () {
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
    test('Vocab copyWith updates name', () {
      final updated = vocab.copyWith(name: 'Updated');
      expect(updated.name, 'Updated');
      expect(updated.id, vocab.id);
    });
    test('Vocab copyWith updates entries', () {
      final updated = vocab.copyWith(entries: []);
      expect(updated.entries, isEmpty);
      expect(updated.id, vocab.id);
    });
    test('Vocab copyWith updates id', () {
      final updated = vocab.copyWith(id: '2');
      expect(updated.id, '2');
    });
    test('Vocab copyWith updates sourceLanguage', () {
      final updated = vocab.copyWith(sourceLanguage: 'French');
      expect(updated.sourceLanguage, 'French');
    });
    test('Vocab copyWith updates targetLanguage', () {
      final updated = vocab.copyWith(targetLanguage: 'German');
      expect(updated.targetLanguage, 'German');
    });
    test('Vocab copyWith updates sourceReadingDirection', () {
      final updated = vocab.copyWith(sourceReadingDirection: ReadingDirection.rightToLeft);
      expect(updated.sourceReadingDirection, ReadingDirection.rightToLeft);
    });
    test('Vocab copyWith updates targetReadingDirection', () {
      final updated = vocab.copyWith(targetReadingDirection: ReadingDirection.rightToLeft);
      expect(updated.targetReadingDirection, ReadingDirection.rightToLeft);
    });
  });
} 