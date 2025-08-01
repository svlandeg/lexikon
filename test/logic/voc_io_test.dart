import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/voc/vocabulary.dart';
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

  group('Entry Error Handling', () {
    test('entryFromJson throws error when type is null', () {
      final json = {
        'source': 'hello',
        'target': 'hola'
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('entryFromJson throws error when target is null', () {
      final json = {
        'type': 'text',
        'source': 'hello'
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('entryFromJson throws error when source is null for text entry', () {
      final json = {
        'type': 'text',
        'target': 'hola'
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('entryFromJson throws error when imagePath is null for image entry', () {
      final json = {
        'type': 'image',
        'target': 'gato'
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('entryFromJson throws error for unknown entry type', () {
      final json = {
        'type': 'unknown',
        'target': 'test'
      };
      expect(() => entryFromJson(json), throwsArgumentError);
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

  group('Vocabulary Error Handling', () {
    test('vocabularyFromJson throws error when type is null', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'entries': []
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('vocabularyFromJson throws error when id is null', () {
      final json = {
        'type': 'text',
        'name': 'Test',
        'entries': []
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('vocabularyFromJson throws error when name is null', () {
      final json = {
        'type': 'text',
        'id': '1',
        'entries': []
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('vocabularyFromJson throws error when entries is null', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test'
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('vocabularyFromJson throws error when sourceLanguage is null for text vocabulary', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'targetLanguage': 'Spanish',
        'entries': []
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('vocabularyFromJson throws error when targetLanguage is null for text vocabulary', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'entries': []
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('vocabularyFromJson throws error when targetLanguage is null for image vocabulary', () {
      final json = {
        'type': 'image',
        'id': '1',
        'name': 'Test',
        'entries': []
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('vocabularyFromJson throws error for unknown vocabulary type', () {
      final json = {
        'type': 'unknown',
        'id': '1',
        'name': 'Test',
        'entries': []
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('vocabularyFromJson handles missing reading direction fields gracefully', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'entries': []
      };
      final vocab = vocabularyFromJson(json);
      expect(vocab.sourceReadingDirection, TextDirection.ltr);
      expect(vocab.targetReadingDirection, TextDirection.ltr);
    });
  });
} 