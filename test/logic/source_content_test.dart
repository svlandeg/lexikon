import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/vocabulary.dart';

void main() {
  group('SourceContent', () {
    test('text constructor creates text content', () {
      final content = SourceContent.text('hello');
      expect(content.isImage, false);
      expect(content.text, 'hello');
      expect(content.imagePath, null);
      expect(content.displayValue, 'hello');
    });

    test('image constructor creates image content', () {
      final content = SourceContent.image('assets/images/cat.png');
      expect(content.isImage, true);
      expect(content.text, null);
      expect(content.imagePath, 'assets/images/cat.png');
      expect(content.displayValue, 'assets/images/cat.png');
    });

    test('toJson for text content', () {
      final content = SourceContent.text('hello');
      final json = content.toJson();
      expect(json['isImage'], false);
      expect(json['text'], 'hello');
      expect(json.containsKey('imagePath'), false);
    });

    test('toJson for image content', () {
      final content = SourceContent.image('assets/images/cat.png');
      final json = content.toJson();
      expect(json['isImage'], true);
      expect(json['imagePath'], 'assets/images/cat.png');
      expect(json.containsKey('text'), false);
    });

    test('fromJson for text content', () {
      final json = {'isImage': false, 'text': 'hello'};
      final content = SourceContent.fromJson(json);
      expect(content.isImage, false);
      expect(content.text, 'hello');
      expect(content.imagePath, null);
    });

    test('fromJson for image content', () {
      final json = {'isImage': true, 'imagePath': 'assets/images/cat.png'};
      final content = SourceContent.fromJson(json);
      expect(content.isImage, true);
      expect(content.text, null);
      expect(content.imagePath, 'assets/images/cat.png');
    });
  });

  group('Entry with SourceContent', () {
    test('Entry with text source', () {
      final entry = Entry(
        source: SourceContent.text('cat'),
        target: 'قطة'
      );
      expect(entry.sourceText, 'cat');
      expect(entry.target, 'قطة');
      expect(entry.source.isImage, false);
    });

    test('Entry with image source', () {
      final entry = Entry(
        source: SourceContent.image('assets/images/cat.png'),
        target: 'قطة'
      );
      expect(entry.sourceText, 'assets/images/cat.png');
      expect(entry.target, 'قطة');
      expect(entry.source.isImage, true);
    });

    test('Entry toJson with text source', () {
      final entry = Entry(
        source: SourceContent.text('cat'),
        target: 'قطة'
      );
      final json = entry.toJson();
      expect(json['target'], 'قطة');
      expect(json['source']['isImage'], false);
      expect(json['source']['text'], 'cat');
    });

    test('Entry toJson with image source', () {
      final entry = Entry(
        source: SourceContent.image('assets/images/cat.png'),
        target: 'قطة'
      );
      final json = entry.toJson();
      expect(json['target'], 'قطة');
      expect(json['source']['isImage'], true);
      expect(json['source']['imagePath'], 'assets/images/cat.png');
    });

    test('Entry fromJson with text source', () {
      final json = {
        'source': {'isImage': false, 'text': 'cat'},
        'target': 'قطة'
      };
      final entry = Entry.fromJson(json);
      expect(entry.sourceText, 'cat');
      expect(entry.target, 'قطة');
      expect(entry.source.isImage, false);
    });

    test('Entry fromJson with image source', () {
      final json = {
        'source': {'isImage': true, 'imagePath': 'assets/images/cat.png'},
        'target': 'قطة'
      };
      final entry = Entry.fromJson(json);
      expect(entry.sourceText, 'assets/images/cat.png');
      expect(entry.target, 'قطة');
      expect(entry.source.isImage, true);
    });
  });
} 