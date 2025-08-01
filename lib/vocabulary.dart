import 'package:flutter/material.dart';
import 'dart:io';

// Base abstract class for all entries
abstract class Entry {
  final String target;

  const Entry({required this.target});

  Map<String, dynamic> toJson();
}



// Text entry with both source and target as text
class TextEntry extends Entry {
  final String source;

  const TextEntry({required this.source, required super.target});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'source': source,
    'target': target,
  };

  factory TextEntry.fromJson(Map<String, dynamic> json) => TextEntry(
    source: json['source'] as String,
    target: json['target'] as String,
  );
}

// Image entry with image source and text target
class ImageEntry extends Entry {
  final String imagePath;

  const ImageEntry({required this.imagePath, required super.target});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'imagePath': imagePath,
    'target': target,
  };

  factory ImageEntry.fromJson(Map<String, dynamic> json) => ImageEntry(
    imagePath: json['imagePath'] as String,
    target: json['target'] as String,
  );
}

// Factory method for creating entries from JSON
Entry entryFromJson(Map<String, dynamic> json) {
  // Validate required fields
  if (json['type'] == null) {
    throw ArgumentError('Entry JSON is missing required field: type');
  }
  if (json['target'] == null) {
    throw ArgumentError('Entry JSON is missing required field: target');
  }

  final type = json['type'] as String;
  switch (type) {
    case 'text':
      if (json['source'] == null) {
        throw ArgumentError('TextEntry JSON is missing required field: source');
      }
      return TextEntry.fromJson(json);
    case 'image':
      if (json['imagePath'] == null) {
        throw ArgumentError('ImageEntry JSON is missing required field: imagePath');
      }
      return ImageEntry.fromJson(json);
    default:
      throw ArgumentError('Unknown entry type: $type');
  }
}

// Base abstract class for all vocabularies
abstract class Vocabulary {
  final String id;
  final String name;
  final String sourceLanguage;
  final String targetLanguage;
  final TextDirection sourceReadingDirection;
  final TextDirection targetReadingDirection;
  final List<Entry> entries;

  const Vocabulary({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.sourceReadingDirection = TextDirection.ltr,
    this.targetReadingDirection = TextDirection.ltr,
    required this.entries,
  });

  Map<String, dynamic> toJson();

  Vocabulary copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? targetLanguage,
    TextDirection? sourceReadingDirection,
    TextDirection? targetReadingDirection,
    List<Entry>? entries,
  });
}

// Text vocabulary with text entries
class TextVocabulary extends Vocabulary {
  const TextVocabulary({
    required super.id,
    required super.name,
    required super.sourceLanguage,
    required super.targetLanguage,
    super.sourceReadingDirection = TextDirection.ltr,
    super.targetReadingDirection = TextDirection.ltr,
    required List<TextEntry> entries,
  }) : super(entries: entries);

  List<TextEntry> get textEntries => entries.cast<TextEntry>();

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
  TextVocabulary copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? targetLanguage,
    TextDirection? sourceReadingDirection,
    TextDirection? targetReadingDirection,
    List<Entry>? entries,
  }) {
    // Ensure all entries are TextEntry
    List<TextEntry> textEntries;
    if (entries != null) {
      textEntries = <TextEntry>[];
      for (final entry in entries) {
        if (entry is TextEntry) {
          textEntries.add(entry);
        } else {
          throw ArgumentError('TextVocabulary can only contain TextEntry objects, found: ${entry.runtimeType}');
        }
      }
    } else {
      textEntries = this.textEntries;
    }

    return TextVocabulary(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      sourceReadingDirection: sourceReadingDirection ?? this.sourceReadingDirection,
      targetReadingDirection: targetReadingDirection ?? this.targetReadingDirection,
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
    sourceLanguage: 'Image',
    sourceReadingDirection: TextDirection.ltr,
    entries: entries,
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
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'sourceReadingDirection': sourceReadingDirection.name,
    'targetReadingDirection': targetReadingDirection.name,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

    @override
  ImageVocabulary copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? targetLanguage,
    TextDirection? sourceReadingDirection,
    TextDirection? targetReadingDirection,
    List<Entry>? entries,
  }) {
    // Ensure all entries are ImageEntry
    List<ImageEntry> imageEntries;
    if (entries != null) {
      imageEntries = <ImageEntry>[];
      for (final entry in entries) {
        if (entry is ImageEntry) {
          imageEntries.add(entry);
        } else {
          throw ArgumentError('ImageVocabulary can only contain ImageEntry objects, found: ${entry.runtimeType}');
        }
      }
    } else {
      imageEntries = this.imageEntries;
    }

    return ImageVocabulary(
      id: id ?? this.id,
      name: name ?? this.name,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      targetReadingDirection: targetReadingDirection ?? this.targetReadingDirection,
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
  if (json['id'] == null) {
    throw ArgumentError('Vocabulary JSON is missing required field: id');
  }
  if (json['name'] == null) {
    throw ArgumentError('Vocabulary JSON is missing required field: name');
  }
  if (json['entries'] == null) {
    throw ArgumentError('Vocabulary JSON is missing required field: entries');
  }

  final type = json['type'] as String;
  final entries = (json['entries'] as List).map((e) => entryFromJson(e)).toList();

  switch (type) {
    case 'text':
      if (json['sourceLanguage'] == null) {
        throw ArgumentError('TextVocabulary JSON is missing required field: sourceLanguage');
      }
      if (json['targetLanguage'] == null) {
        throw ArgumentError('TextVocabulary JSON is missing required field: targetLanguage');
      }
      
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
    case 'image':
      if (json['targetLanguage'] == null) {
        throw ArgumentError('ImageVocabulary JSON is missing required field: targetLanguage');
      }
      
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
    default:
      throw ArgumentError('Unknown vocabulary type: $type');
  }
}

// Widget for displaying entry sources (text or image)
class EntrySourceWidget extends StatelessWidget {
  final Entry entry;
  final TextStyle? style;
  final TextDirection? textDirection;
  final double? imageWidth;
  final double? imageHeight;
  final BoxFit imageFit;

  const EntrySourceWidget({
    super.key,
    required this.entry,
    this.style,
    this.textDirection,
    this.imageWidth,
    this.imageHeight,
    this.imageFit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (entry is TextEntry) {
      final textEntry = entry as TextEntry;
      return Text(
        textEntry.source,
        style: style,
        textDirection: textDirection,
      );
    } else if (entry is ImageEntry) {
      final imageEntry = entry as ImageEntry;
      
             // Check if the path is a local file path (contains directory separators)
       if (imageEntry.imagePath.contains('/') || imageEntry.imagePath.contains('\\')) {
         // Local file path - use Image.file
         final file = File(imageEntry.imagePath);
         
         // Check if file exists before trying to load it
         if (!file.existsSync()) {
           return Container(
             width: imageWidth,
             height: imageHeight,
             decoration: BoxDecoration(
               border: Border.all(color: Colors.red),
               color: Colors.grey[200],
             ),
             child: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.error, color: Colors.red),
                   const SizedBox(height: 4),
                   Text(
                     'File not found',
                     style: TextStyle(
                       fontSize: 10,
                       color: Colors.red[700],
                     ),
                   ),
                   Text(
                     imageEntry.imagePath.split('/').last,
                     style: TextStyle(
                       fontSize: 8,
                       color: Colors.grey[600],
                     ),
                   ),
                 ],
               ),
             ),
           );
         }
         
         return Image.file(
           file,
           width: imageWidth,
           height: imageHeight,
           fit: imageFit,
           errorBuilder: (context, error, stackTrace) {
             print('Error loading image: ${imageEntry.imagePath}');
             print('Error: $error');
             return Container(
               width: imageWidth,
               height: imageHeight,
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.red),
                 color: Colors.grey[200],
               ),
               child: Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.error, color: Colors.red),
                     const SizedBox(height: 4),
                     Text(
                       'Load failed',
                       style: TextStyle(
                         fontSize: 10,
                         color: Colors.red[700],
                       ),
                     ),
                     Text(
                       imageEntry.imagePath.split('/').last,
                       style: TextStyle(
                         fontSize: 8,
                         color: Colors.grey[600],
                       ),
                     ),
                   ],
                 ),
               ),
             );
           },
         );
      } else {
        // Asset path - use Image.asset
        return Image.asset(
          imageEntry.imagePath,
          width: imageWidth,
          height: imageHeight,
          fit: imageFit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: imageWidth,
              height: imageHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
                color: Colors.grey[200],
              ),
              child: const Center(
                child: Icon(Icons.error, color: Colors.red),
              ),
            );
          },
        );
      }
    } else {
      throw ArgumentError('Unknown entry type: ${entry.runtimeType}');
    }
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