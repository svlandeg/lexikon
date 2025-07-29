import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/vocabulary.dart';
import 'package:flutter/material.dart';

void main() {
  group('Entry', () {
    test('toJson', () {
      final entry = TextEntry(source: 'hello', target: 'hola');
      expect(entry.toJson(), {
        'type': 'text',
        'source': 'hello',
        'target': 'hola'
      });
    });
    test('fromJson', () {
      final json = {
        'type': 'text',
        'source': 'hello',
        'target': 'hola'
      };
      final entry2 = TextEntry.fromJson(json);
      expect(entry2.source, 'hello');
      expect(entry2.target, 'hola');
    });
  });

  group('Vocabulary', () {
    final entryList = [TextEntry(source: 'cat', target: 'gato'), TextEntry(source: 'dog', target: 'perro')];
    final vocab = TextVocabulary(
      id: '1',
      name: 'TestName',
      sourceLanguage: 'English',
      targetLanguage: 'Spanish',
      sourceReadingDirection: TextDirection.ltr,
      targetReadingDirection: TextDirection.rtl,
      entries: entryList,
    );
    test('toJson', () {
      final json = vocab.toJson();
      expect(json['id'], vocab.id);
      expect(json['name'], 'TestName');
      expect(json['sourceLanguage'], 'English');
      expect(json['targetLanguage'], 'Spanish');
      expect(json['sourceReadingDirection'], TextDirection.ltr.name);
      expect(json['targetReadingDirection'], TextDirection.rtl.name);
      expect(json['entries'], isA<List<dynamic>>());
      expect(json['entries'][0]['source'], 'cat');
      expect(json['entries'][0]['target'], 'gato');
      expect(json['entries'][1]['source'], 'dog');
      expect(json['entries'][1]['target'], 'perro');
    });
    test('fromJson', () {
      final json = vocab.toJson();
      final vocab2 = vocabularyFromJson(json);
      expect(vocab2.id, vocab.id);
      expect(vocab2.name, vocab.name);
      expect(vocab2.sourceLanguage, vocab.sourceLanguage);
      expect(vocab2.targetLanguage, vocab.targetLanguage);
      expect(vocab2.sourceReadingDirection, vocab.sourceReadingDirection);
      expect(vocab2.targetReadingDirection, vocab.targetReadingDirection);
      expect(vocab2.entries.length, vocab.entries.length);
      expect((vocab2.entries[0] as TextEntry).source, (vocab.entries[0] as TextEntry).source);
      expect(vocab2.entries[0].target, vocab.entries[0].target);
      expect((vocab2.entries[1] as TextEntry).source, (vocab.entries[1] as TextEntry).source);
      expect(vocab2.entries[1].target, vocab.entries[1].target);
    });
  });
} 