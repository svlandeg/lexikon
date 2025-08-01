import 'package:flutter/material.dart';
import 'dart:io';
import 'entry.dart';


// Base abstract class for all vocabularies
abstract class Vocabulary {
  final String id;
  final String name;
  final String inputSource;
  final String targetLanguage;
  final TextDirection targetReadingDirection;
  final List<Entry> entries;

  const Vocabulary({
    required this.id,
    required this.name,
    required this.targetLanguage,
    this.targetReadingDirection = TextDirection.ltr,
    required this.entries,
    required this.inputSource
  });

  Map<String, dynamic> toJson();

  setEntries(List<Entry> entries);

  String get inputSourceDetail => inputSource;
}

// Text vocabulary with text entries
class TextVocabulary extends Vocabulary {

  final String sourceLanguage;
  final TextDirection sourceReadingDirection;

  const TextVocabulary({
    required super.id,
    required super.name,
    required super.targetLanguage,
    super.targetReadingDirection = TextDirection.ltr,
    required List<TextEntry> entries,
    required this.sourceLanguage,
    this.sourceReadingDirection = TextDirection.ltr,
  }) : super(
    entries: entries,
    inputSource: sourceLanguage,
    );

  List<TextEntry> get textEntries => entries.cast<TextEntry>();

  String get inputSourceDetail => '$inputSource ($sourceReadingDirection.name)';

  @override
  List<Entry> get entries {
    // Ensure all entries are TextEntry
    for (final entry in super.entries) {
      if (entry is! TextEntry) {
        throw ArgumentError('TextVocabulary can only contain TextEntry objects, found: ${entry.runtimeType}');
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
    if (entries != null) {
      for (final entry in entries) {
        if (entry is TextEntry) {
          textEntries.add(entry);
        } else {
          throw ArgumentError('TextVocabulary can only contain TextEntry objects, found: ${entry.runtimeType}');
        }
      }
    } 
    entries = textEntries;
  }

  factory TextVocabulary.fromJson(Map<String, dynamic> json) {
    const requiredFields = ['id', 'name', 'sourceLanguage', 'targetLanguage', 'entries', 'sourceReadingDirection', 'targetReadingDirection'];
    for (final field in requiredFields) {
      if (json[field] == null) {
        throw ArgumentError('TextVocabulary JSON is missing required field: $field');
      }
    }

    final entries = (json['entries'] as List).map((e) => entryFromJson(e)).toList();

      // Validate that all entries are TextEntry
      final textEntries = <TextEntry>[];
      for (final entry in entries) {
        if (entry is TextEntry) {
          textEntries.add(entry);
        } else {
          throw ArgumentError('TextVocabulary can only contain TextEntry objects, found: ${entry.runtimeType}');
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
  const ImageVocabulary({
    required super.id,
    required super.name,
    required super.targetLanguage,
    super.targetReadingDirection = TextDirection.ltr,
    required List<ImageEntry> entries,
  }) : super(
    entries: entries, inputSource: "Image"
    );

  List<ImageEntry> get imageEntries => entries.cast<ImageEntry>();

  @override
  List<Entry> get entries {
    // Ensure all entries are ImageEntry
    for (final entry in super.entries) {
      if (entry is! ImageEntry) {
        throw ArgumentError('ImageVocabulary can only contain ImageEntry objects, found: ${entry.runtimeType}');
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
    if (entries != null) {
      for (final entry in entries) {
        if (entry is ImageEntry) {
          imageEntries.add(entry);
        } else {
          throw ArgumentError('ImageVocabulary can only contain ImageEntry objects, found: ${entry.runtimeType}');
        }
      }
    }
    entries = imageEntries;
  }

  factory ImageVocabulary.fromJson(Map<String, dynamic> json) {
    const requiredFields = ['id', 'name', 'targetLanguage', 'entries', 'targetReadingDirection'];
    for (final field in requiredFields) {
      if (json[field] == null) {
        throw ArgumentError('ImageVocabulary JSON is missing required field: $field');
      }
    }

    final entries = (json['entries'] as List).map((e) => entryFromJson(e)).toList();
      
      // Validate that all entries are ImageEntry
      final imageEntries = <ImageEntry>[];
      for (final entry in entries) {
        if (entry is ImageEntry) {
          imageEntries.add(entry);
        } else {
          throw ArgumentError('ImageVocabulary can only contain ImageEntry objects, found: ${entry.runtimeType}');
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



// CSV parsing utilities for vocabulary creation
class CsvVocabularyData {
  final String name;
  final String sourceLanguage;
  final String targetLanguage;
  final List<TextEntry> entries;
  final TextDirection sourceReadingDirection;
  final TextDirection targetReadingDirection;

  const CsvVocabularyData({
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.entries,
    required this.sourceReadingDirection,
    required this.targetReadingDirection,
  });
}

class CsvParser {
  // RTL languages list - atomic names that indicate RTL languages
  static const List<String> _rtlLanguages = [
    'arabic',
    'balochi',
    'farsi',
    'hebrew',
    'kurdish',
    'pashto',
    'persian',
    'sindhi',
    'urdu',
    'uyghur',
  ];

  /// Determines if a language is RTL based on the language name
  /// Checks if the normalized language name contains any of the RTL language keywords
  static bool _isRtlLanguage(String language) {
    final normalizedLanguage = language.toLowerCase().trim();
    return _rtlLanguages.any((rtlLang) => normalizedLanguage.contains(rtlLang));
  }

  /// Parses a CSV file and extracts vocabulary data
  /// 
  /// Expected format:
  /// - First line: "SourceLanguage,TargetLanguage" (e.g., "English,Arabic")
  /// - Subsequent lines: "source,target" pairs (e.g., "Hello,مرحبا")
  /// 
  /// Returns CsvVocabularyData with:
  /// - name: filename without extension
  /// - sourceLanguage: from first line, first column
  /// - targetLanguage: from first line, second column
  /// - entries: all subsequent lines as TextEntry objects
  /// - sourceReadingDirection: automatically determined from source language
  /// - targetReadingDirection: automatically determined from target language
  static CsvVocabularyData parseCsvFile(String filename, String csvContent) {
    final lines = csvContent.trim().split('\n');
    
    if (lines.isEmpty) {
      throw ArgumentError('CSV file is empty');
    }
    
    // Parse first line for languages
    final languageLine = lines[0].trim();
    final languageParts = languageLine.split(',');
    
    if (languageParts.length < 2) {
      throw ArgumentError('First line must contain source and target languages separated by comma');
    }
    
    final sourceLanguage = languageParts[0].trim();
    final targetLanguage = languageParts[1].trim();
    
    if (sourceLanguage.isEmpty || targetLanguage.isEmpty) {
      throw ArgumentError('Source and target languages cannot be empty');
    }
    
    // Determine reading directions based on languages
    final sourceReadingDirection = _isRtlLanguage(sourceLanguage) 
        ? TextDirection.rtl 
        : TextDirection.ltr;
    final targetReadingDirection = _isRtlLanguage(targetLanguage) 
        ? TextDirection.rtl 
        : TextDirection.ltr;
    
    // Parse vocabulary entries from remaining lines
    final entries = <TextEntry>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        final parts = line.split(',');
        if (parts.length >= 2) {
          final source = parts[0].trim();
          final target = parts[1].trim();
          if (source.isNotEmpty && target.isNotEmpty) {
            entries.add(TextEntry(source: source, target: target));
          }
        }
      }
    }
    
    // Extract name from filename (remove extension)
    final name = filename.replaceAll(RegExp(r'\.csv$'), '');
    
    return CsvVocabularyData(
      name: name,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      entries: entries,
      sourceReadingDirection: sourceReadingDirection,
      targetReadingDirection: targetReadingDirection,
    );
  }
} 