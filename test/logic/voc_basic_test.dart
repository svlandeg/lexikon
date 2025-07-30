import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/vocabulary.dart';
import 'package:flutter/material.dart';

void main() {
  group('Vocabulary', () {
    final entryList = [TextEntry(source: 'cat', target: 'gato'), TextEntry(source: 'dog', target: 'perro')];
    final vocab = TextVocabulary(
      id: '1',
      name: 'TestName',
      sourceLanguage: 'English',
      targetLanguage: 'Spanish',
      sourceReadingDirection: TextDirection.ltr,
      // while Spanish is LTR, setting it to RTL here just for testing
      targetReadingDirection: TextDirection.rtl,
      entries: entryList,
    );
    test('contents', () {
      expect(vocab.name, 'TestName');
      expect(vocab.sourceLanguage, 'English');
      expect(vocab.targetLanguage, 'Spanish');
      expect(vocab.sourceReadingDirection, TextDirection.ltr);
      expect(vocab.targetReadingDirection, TextDirection.rtl);
      expect(vocab.entries.length, entryList.length);
      expect((vocab.entries[0] as TextEntry).source, 'cat');
      expect(vocab.entries[0].target, 'gato');
      expect((vocab.entries[1] as TextEntry).source, 'dog');
      expect(vocab.entries[1].target, 'perro');
    });

    test('copyWith functionality', () {
      final updated1 = vocab.copyWith(name: 'Updated', entries: <TextEntry>[]);
      expect(updated1.name, 'Updated');
      expect(updated1.entries, isEmpty);
      expect(updated1.id, vocab.id);

      final updated2 = vocab.copyWith(sourceLanguage: 'French', targetLanguage: 'German');
      expect(updated2.sourceLanguage, 'French');
      expect(updated2.targetLanguage, 'German');

      final updated3 = vocab.copyWith(
        sourceReadingDirection: TextDirection.rtl,
        targetReadingDirection: TextDirection.ltr,
      );
      expect(updated3.sourceReadingDirection, TextDirection.rtl);
      expect(updated3.targetReadingDirection, TextDirection.ltr);
    });
  });
} 