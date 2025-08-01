import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/voc/vocabulary.dart';
import 'package:flutter/material.dart';

void main() {
  group('JSON Corruption Tests', () {
    test('handles completely empty JSON object', () {
      final json = <String, dynamic>{};
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('handles JSON with null values', () {
      final json = {
        'type': null,
        'id': null,
        'name': null,
        'entries': null,
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('handles malformed entry JSON', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'entries': [
          {
            'type': null, // Missing type
            'source': 'hello',
            'target': 'hola',
          }
        ],
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('handles entry with missing required fields', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'entries': [
          {
            'type': 'text',
            // Missing source
            'target': 'hola',
          }
        ],
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('handles corrupted vocabulary type', () {
      final json = {
        'type': 'corrupted_type',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'entries': [],
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('handles corrupted entry type', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'entries': [
          {
            'type': 'corrupted_entry_type',
            'source': 'hello',
            'target': 'hola',
          }
        ],
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('handles missing reading direction with fallback', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        // Missing reading direction fields
        'entries': [],
      };
      final vocab = vocabularyFromJson(json);
      expect(vocab.sourceReadingDirection, TextDirection.ltr);
      expect(vocab.targetReadingDirection, TextDirection.ltr);
    });

    test('handles null reading direction with fallback', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'sourceReadingDirection': null,
        'targetReadingDirection': null,
        'entries': [],
      };
      final vocab = vocabularyFromJson(json);
      expect(vocab.sourceReadingDirection, TextDirection.ltr);
      expect(vocab.targetReadingDirection, TextDirection.ltr);
    });

    test('handles invalid reading direction enum value', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'sourceReadingDirection': 'invalid_direction',
        'targetReadingDirection': 'invalid_direction',
        'entries': [],
      };
      final vocab = vocabularyFromJson(json);
      expect(vocab.sourceReadingDirection, TextDirection.ltr);
      expect(vocab.targetReadingDirection, TextDirection.ltr);
    });

    test('handles image vocabulary with missing targetLanguage', () {
      final json = {
        'type': 'image',
        'id': '1',
        'name': 'Test',
        // Missing targetLanguage
        'entries': [],
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('handles image vocabulary with missing imagePath in entries', () {
      final json = {
        'type': 'image',
        'id': '1',
        'name': 'Test',
        'targetLanguage': 'Spanish',
        'entries': [
          {
            'type': 'image',
            // Missing imagePath
            'target': 'gato',
          }
        ],
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });

    test('handles mixed valid and invalid entries gracefully', () {
      final json = {
        'type': 'text',
        'id': '1',
        'name': 'Test',
        'sourceLanguage': 'English',
        'targetLanguage': 'Spanish',
        'entries': [
          {
            'type': 'text',
            'source': 'hello',
            'target': 'hola',
          },
          {
            'type': 'text',
            // Missing source - should cause error
            'target': 'adios',
          }
        ],
      };
      expect(() => vocabularyFromJson(json), throwsArgumentError);
    });
  });

  group('Entry JSON Corruption Tests', () {
    test('handles empty entry JSON', () {
      final json = <String, dynamic>{};
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('handles entry with null type', () {
      final json = {
        'type': null,
        'source': 'hello',
        'target': 'hola',
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('handles entry with null target', () {
      final json = {
        'type': 'text',
        'source': 'hello',
        'target': null,
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('handles text entry with null source', () {
      final json = {
        'type': 'text',
        'source': null,
        'target': 'hola',
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('handles image entry with null imagePath', () {
      final json = {
        'type': 'image',
        'imagePath': null,
        'target': 'gato',
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });

    test('handles entry with unknown type', () {
      final json = {
        'type': 'unknown_type',
        'source': 'hello',
        'target': 'hola',
      };
      expect(() => entryFromJson(json), throwsArgumentError);
    });
  });
} 