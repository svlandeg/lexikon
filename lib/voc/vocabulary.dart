import 'package:flutter/material.dart';
import 'entry.dart';

// Base abstract class for all vocabularies
abstract class Vocabulary {
  final String id;
  String name;
  String targetLanguage;
  TextDirection targetReadingDirection;
  List<Entry> entries;

  Vocabulary({
    required this.id,
    required this.name,
    required this.targetLanguage,
    this.targetReadingDirection = TextDirection.ltr,
    required this.entries,
  });

  Map<String, dynamic> toJson();

  setEntries(List<Entry> entries);

  String get inputSource;
}

// Text vocabulary with text entries
class TextVocabulary extends Vocabulary {
  String sourceLanguage;
  TextDirection sourceReadingDirection;

  TextVocabulary({
    required super.id,
    required super.name,
    required super.targetLanguage,
    super.targetReadingDirection = TextDirection.ltr,
    required List<TextEntry> entries,
    required this.sourceLanguage,
    this.sourceReadingDirection = TextDirection.ltr,
  }) : super(entries: entries);

  List<TextEntry> get textEntries => entries.cast<TextEntry>();

  @override
  String get inputSource => sourceLanguage;

  @override
  List<Entry> get entries {
    // Ensure all entries are TextEntry
    for (final entry in super.entries) {
      if (entry is! TextEntry) {
        throw ArgumentError(
          'TextVocabulary can only contain TextEntry objects, found: ${entry.runtimeType}',
        );
      }
    }
    return super.entries;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'id': id,
    'name': name,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'sourceReadingDirection': sourceReadingDirection.name,
    'targetReadingDirection': targetReadingDirection.name,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  @override
  setEntries(List<Entry> entries) {
    // Ensure all entries are TextEntry
    List<TextEntry> textEntries = <TextEntry>[];
    for (final entry in entries) {
      if (entry is TextEntry) {
        textEntries.add(entry);
      } else {
        throw ArgumentError(
          'TextVocabulary can only contain TextEntry objects, found: ${entry.runtimeType}',
        );
      }
    }
    this.entries = textEntries;
  }

  factory TextVocabulary.fromJson(Map<String, dynamic> json) {
    const requiredFields = [
      'id',
      'name',
      'sourceLanguage',
      'targetLanguage',
      'entries',
      'sourceReadingDirection',
      'targetReadingDirection',
    ];
    for (final field in requiredFields) {
      if (json[field] == null) {
        throw ArgumentError(
          'TextVocabulary JSON is missing required field: $field',
        );
      }
    }

    final entries = (json['entries'] as List)
        .map((e) => entryFromJson(e))
        .toList();

    // Validate that all entries are TextEntry
    final textEntries = <TextEntry>[];
    for (final entry in entries) {
      if (entry is TextEntry) {
        textEntries.add(entry);
      } else {
        throw ArgumentError(
          'TextVocabulary can only contain TextEntry objects, found: ${entry.runtimeType}',
        );
      }
    }

    return TextVocabulary(
      id: json['id'] as String,
      name: json['name'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      sourceReadingDirection: TextDirection.values.firstWhere(
        (e) => e.name == (json['sourceReadingDirection'] as String? ?? 'ltr'),
        orElse: () => TextDirection.ltr,
      ),
      targetReadingDirection: TextDirection.values.firstWhere(
        (e) => e.name == (json['targetReadingDirection'] as String? ?? 'ltr'),
        orElse: () => TextDirection.ltr,
      ),
      entries: textEntries,
    );
  }
}

// Image vocabulary with image entries
class ImageVocabulary extends Vocabulary {
  ImageVocabulary({
    required super.id,
    required super.name,
    required super.targetLanguage,
    super.targetReadingDirection = TextDirection.ltr,
    required List<ImageEntry> entries,
  }) : super(entries: entries);

  List<ImageEntry> get imageEntries => entries.cast<ImageEntry>();

  @override
  String get inputSource => 'Image';

  @override
  List<Entry> get entries {
    // Ensure all entries are ImageEntry
    for (final entry in super.entries) {
      if (entry is! ImageEntry) {
        throw ArgumentError(
          'ImageVocabulary can only contain ImageEntry objects, found: ${entry.runtimeType}',
        );
      }
    }
    return super.entries;
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'id': id,
    'name': name,
    'targetLanguage': targetLanguage,
    'targetReadingDirection': targetReadingDirection.name,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  @override
  setEntries(List<Entry> entries) {
    // Ensure all entries are ImageEntry
    List<ImageEntry> imageEntries = <ImageEntry>[];
    for (final entry in entries) {
      if (entry is ImageEntry) {
        imageEntries.add(entry);
      } else {
        throw ArgumentError(
          'ImageVocabulary can only contain ImageEntry objects, found: ${entry.runtimeType}',
        );
      }
    }
    this.entries = imageEntries;
  }

  factory ImageVocabulary.fromJson(Map<String, dynamic> json) {
    const requiredFields = [
      'id',
      'name',
      'targetLanguage',
      'entries',
      'targetReadingDirection',
    ];
    for (final field in requiredFields) {
      if (json[field] == null) {
        throw ArgumentError(
          'ImageVocabulary JSON is missing required field: $field',
        );
      }
    }

    final entries = (json['entries'] as List)
        .map((e) => entryFromJson(e))
        .toList();

    // Validate that all entries are ImageEntry
    final imageEntries = <ImageEntry>[];
    for (final entry in entries) {
      if (entry is ImageEntry) {
        imageEntries.add(entry);
      } else {
        throw ArgumentError(
          'ImageVocabulary can only contain ImageEntry objects, found: ${entry.runtimeType}',
        );
      }
    }

    return ImageVocabulary(
      id: json['id'] as String,
      name: json['name'] as String,
      targetLanguage: json['targetLanguage'] as String,
      targetReadingDirection: TextDirection.values.firstWhere(
        (e) => e.name == (json['targetReadingDirection'] as String? ?? 'ltr'),
        orElse: () => TextDirection.ltr,
      ),
      entries: imageEntries,
    );
  }
}

// Factory method for creating vocabularies from JSON
Vocabulary vocabularyFromJson(Map<String, dynamic> json) {
  // Validate required fields
  if (json['type'] == null) {
    throw ArgumentError('Vocabulary JSON is missing required field: type');
  }

  final type = json['type'] as String;
  switch (type) {
    case 'text':
      return TextVocabulary.fromJson(json);
    case 'image':
      return ImageVocabulary.fromJson(json);
    default:
      throw ArgumentError('Unknown vocabulary type: $type');
  }
}
