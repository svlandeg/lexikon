enum ReadingDirection {
  leftToRight,
  rightToLeft;

  String get displayName {
    switch (this) {
      case ReadingDirection.leftToRight:
        return 'Left to Right';
      case ReadingDirection.rightToLeft:
        return 'Right to Left';
    }
  }

  static ReadingDirection fromString(String value) {
    final normalized = value.replaceAll(' ', '').toLowerCase();
    switch (normalized) {
      case 'righttoleft':
        return ReadingDirection.rightToLeft;
      case 'lefttoright':
        return ReadingDirection.leftToRight;
      default:
        return ReadingDirection.leftToRight;
    }
  }
}

class Entry {
  final String source;
  final String target;

  Entry({required this.source, required this.target});

  Map<String, dynamic> toJson() => {
    'source': source,
    'target': target,
  };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
    source: json['source'] as String,
    target: json['target'] as String,
  );
}

class Vocabulary {
  final String id;
  final String name;
  final String sourceLanguage;
  final String targetLanguage;
  final ReadingDirection sourceReadingDirection;
  final ReadingDirection targetReadingDirection;
  final List<Entry> entries;

  Vocabulary({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.sourceReadingDirection = ReadingDirection.leftToRight,
    this.targetReadingDirection = ReadingDirection.leftToRight,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'sourceReadingDirection': sourceReadingDirection.name,
    'targetReadingDirection': targetReadingDirection.name,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory Vocabulary.fromJson(Map<String, dynamic> json) => Vocabulary(
    id: json['id'] as String,
    name: json['name'] as String,
    sourceLanguage: json['sourceLanguage'] as String,
    targetLanguage: json['targetLanguage'] as String,
    sourceReadingDirection: ReadingDirection.fromString(json['sourceReadingDirection'] as String),
    targetReadingDirection: ReadingDirection.fromString(json['targetReadingDirection'] as String),
    entries: (json['entries'] as List).map((e) => Entry.fromJson(e)).toList(),
  );

  Vocabulary copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? targetLanguage,
    ReadingDirection? sourceReadingDirection,
    ReadingDirection? targetReadingDirection,
    List<Entry>? entries,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      sourceReadingDirection: sourceReadingDirection ?? this.sourceReadingDirection,
      targetReadingDirection: targetReadingDirection ?? this.targetReadingDirection,
      entries: entries ?? this.entries,
    );
  }
} 