import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/vocabulary.dart';
import 'package:flutter/material.dart';

void main() {
  group('Vocabulary Inheritance', () {
    test('TextVocabulary can be created with TextEntry list', () {
      final entries = [
        TextEntry(source: 'cat', target: 'قطة'),
        TextEntry(source: 'dog', target: 'كلب'),
      ];
      
      final vocab = TextVocabulary(
        id: '1',
        name: 'Arabic Animals',
        sourceLanguage: 'English',
        targetLanguage: 'Arabic',
        entries: entries,
      );
      
      expect(vocab, isA<TextVocabulary>());
      expect(vocab.entries.length, 2);
      expect(vocab.textEntries.length, 2);
      expect(vocab.textEntries[0].source, 'cat');
      expect(vocab.textEntries[0].target, 'قطة');
    });

    test('ImageVocabulary can be created with ImageEntry list', () {
      final entries = [
        ImageEntry(imagePath: 'assets/images/vocabulary/cat.png', target: 'قطة'),
        ImageEntry(imagePath: 'assets/images/vocabulary/dog.png', target: 'كلب'),
      ];
      
      final vocab = ImageVocabulary(
        id: '2',
        name: 'Arabic Animals Images',
        sourceLanguage: 'Images',
        targetLanguage: 'Arabic',
        entries: entries,
      );
      
      expect(vocab, isA<ImageVocabulary>());
      expect(vocab.entries.length, 2);
      expect(vocab.imageEntries.length, 2);
      expect(vocab.imageEntries[0].imagePath, 'assets/images/vocabulary/cat.png');
      expect(vocab.imageEntries[0].target, 'قطة');
    });

    test('TextVocabulary toJson includes type field', () {
      final vocab = TextVocabulary(
        id: '1',
        name: 'Test',
        sourceLanguage: 'English',
        targetLanguage: 'Spanish',
        entries: [TextEntry(source: 'hello', target: 'hola')],
      );
      
      final json = vocab.toJson();
      expect(json['type'], 'text');
      expect(json['entries'][0]['type'], 'text');
      expect(json['entries'][0]['source'], 'hello');
      expect(json['entries'][0]['target'], 'hola');
    });

    test('ImageVocabulary toJson includes type field', () {
      final vocab = ImageVocabulary(
        id: '1',
        name: 'Test',
        sourceLanguage: 'Images',
        targetLanguage: 'Spanish',
        entries: [ImageEntry(imagePath: 'assets/images/cat.png', target: 'gato')],
      );
      
      final json = vocab.toJson();
      expect(json['type'], 'image');
      expect(json['entries'][0]['type'], 'image');
      expect(json['entries'][0]['imagePath'], 'assets/images/cat.png');
      expect(json['entries'][0]['target'], 'gato');
    });

    test('vocabularyFromJson creates TextVocabulary from JSON', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'sourceReadingDirection': 'ltr',
        'targetReadingDirection': 'ltr',
        'entries': [
          {
            'type': 'text',
            'source': 'hello',
            'target': 'hola',
          }
        ],
      };
      
      final vocab = vocabularyFromJson(json);
      expect(vocab, isA<TextVocabulary>());
      expect(vocab.entries.length, 1);
      expect(vocab.entries[0], isA<TextEntry>());
      expect((vocab.entries[0] as TextEntry).source, 'hello');
    });

    test('vocabularyFromJson creates ImageVocabulary from JSON', () {
      final json = {
        'type': 'image',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'Images',
        'targetLanguage': 'Spanish',
        'sourceReadingDirection': 'ltr',
        'targetReadingDirection': 'ltr',
        'entries': [
          {
            'type': 'image',
            'imagePath': 'assets/images/cat.png',
            'target': 'gato',
          }
        ],
      };
      
      final vocab = vocabularyFromJson(json);
      expect(vocab, isA<ImageVocabulary>());
      expect(vocab.entries.length, 1);
      expect(vocab.entries[0], isA<ImageEntry>());
      expect((vocab.entries[0] as ImageEntry).imagePath, 'assets/images/cat.png');
    });

    test('entryFromJson creates TextEntry from JSON', () {
      final json = {
        'type': 'text',
        'source': 'hello',
        'target': 'hola',
      };
      
      final entry = entryFromJson(json);
      expect(entry, isA<TextEntry>());
      expect(entry.target, 'hola');
      expect((entry as TextEntry).source, 'hello');
    });

    test('entryFromJson creates ImageEntry from JSON', () {
      final json = {
        'type': 'image',
        'imagePath': 'assets/images/cat.png',
        'target': 'gato',
      };
      
      final entry = entryFromJson(json);
      expect(entry, isA<ImageEntry>());
      expect(entry.target, 'gato');
      expect((entry as ImageEntry).imagePath, 'assets/images/cat.png');
    });

    test('TextVocabulary copyWith returns TextVocabulary', () {
      final vocab = TextVocabulary(
        id: '1',
        name: 'Test',
        sourceLanguage: 'English',
        targetLanguage: 'Spanish',
        entries: [TextEntry(source: 'hello', target: 'hola')],
      );
      
      final updated = vocab.copyWith(name: 'Updated');
      expect(updated, isA<TextVocabulary>());
      expect(updated.name, 'Updated');
      expect(updated.entries.length, 1);
      expect(updated.entries[0], isA<TextEntry>());
    });

    test('ImageVocabulary copyWith returns ImageVocabulary', () {
      final vocab = ImageVocabulary(
        id: '1',
        name: 'Test',
        sourceLanguage: 'Images',
        targetLanguage: 'Spanish',
        entries: [ImageEntry(imagePath: 'assets/images/cat.png', target: 'gato')],
      );
      
      final updated = vocab.copyWith(name: 'Updated');
      expect(updated, isA<ImageVocabulary>());
      expect(updated.name, 'Updated');
      expect(updated.entries.length, 1);
      expect(updated.entries[0], isA<ImageEntry>());
    });
  });
} 