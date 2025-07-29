import 'package:flutter/material.dart';

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
  final type = json['type'] as String;
  switch (type) {
    case 'text':
      return TextEntry.fromJson(json);
    case 'image':
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
    return TextVocabulary(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      sourceReadingDirection: sourceReadingDirection ?? this.sourceReadingDirection,
      targetReadingDirection: targetReadingDirection ?? this.targetReadingDirection,
              entries: entries?.cast<TextEntry>() ?? textEntries,
    );
  }
}

// Image vocabulary with image entries
class ImageVocabulary extends Vocabulary {
  const ImageVocabulary({
    required super.id,
    required super.name,
    required super.sourceLanguage,
    required super.targetLanguage,
    super.sourceReadingDirection = TextDirection.ltr,
    super.targetReadingDirection = TextDirection.ltr,
    required List<ImageEntry> entries,
  }) : super(entries: entries);

  List<ImageEntry> get imageEntries => entries.cast<ImageEntry>();

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
    return ImageVocabulary(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      sourceReadingDirection: sourceReadingDirection ?? this.sourceReadingDirection,
      targetReadingDirection: targetReadingDirection ?? this.targetReadingDirection,
              entries: entries?.cast<ImageEntry>() ?? imageEntries,
    );
  }
}

// Factory method for creating vocabularies from JSON
Vocabulary vocabularyFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  final baseData = {
    'id': json['id'] as String,
    'name': json['name'] as String,
    'sourceLanguage': json['sourceLanguage'] as String,
    'targetLanguage': json['targetLanguage'] as String,
    'sourceReadingDirection': TextDirection.values.firstWhere(
      (e) => e.name == (json['sourceReadingDirection'] as String),
      orElse: () => TextDirection.ltr,
    ),
    'targetReadingDirection': TextDirection.values.firstWhere(
      (e) => e.name == (json['targetReadingDirection'] as String),
      orElse: () => TextDirection.ltr,
    ),
    'entries': (json['entries'] as List).map((e) => entryFromJson(e)).toList(),
  };

  switch (type) {
    case 'text':
      return TextVocabulary(
        id: baseData['id'] as String,
        name: baseData['name'] as String,
        sourceLanguage: baseData['sourceLanguage'] as String,
        targetLanguage: baseData['targetLanguage'] as String,
        sourceReadingDirection: baseData['sourceReadingDirection'] as TextDirection,
        targetReadingDirection: baseData['targetReadingDirection'] as TextDirection,
        entries: (baseData['entries'] as List<Entry>).cast<TextEntry>(),
      );
    case 'image':
      return ImageVocabulary(
        id: baseData['id'] as String,
        name: baseData['name'] as String,
        sourceLanguage: baseData['sourceLanguage'] as String,
        targetLanguage: baseData['targetLanguage'] as String,
        sourceReadingDirection: baseData['sourceReadingDirection'] as TextDirection,
        targetReadingDirection: baseData['targetReadingDirection'] as TextDirection,
        entries: (baseData['entries'] as List<Entry>).cast<ImageEntry>(),
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
    } else {
      throw ArgumentError('Unknown entry type: ${entry.runtimeType}');
    }
  }
} 