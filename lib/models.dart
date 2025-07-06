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
    switch (value) {
      case 'rightToLeft':
        return ReadingDirection.rightToLeft;
      case 'leftToRight':
      default:
        return ReadingDirection.leftToRight;
    }
  }
}

class Word {
  final String source;
  final String target;

  Word({required this.source, required this.target});

  Map<String, dynamic> toJson() => {
    'source': source,
    'target': target,
  };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
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
  final List<Word> words;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vocabulary({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.sourceReadingDirection = ReadingDirection.leftToRight,
    this.targetReadingDirection = ReadingDirection.leftToRight,
    required this.words,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'sourceReadingDirection': sourceReadingDirection.name,
    'targetReadingDirection': targetReadingDirection.name,
    'words': words.map((w) => w.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Vocabulary.fromJson(Map<String, dynamic> json) => Vocabulary(
    id: json['id'] as String,
    name: json['name'] as String,
    sourceLanguage: json['sourceLanguage'] as String,
    targetLanguage: json['targetLanguage'] as String,
    sourceReadingDirection: json.containsKey('sourceReadingDirection') 
        ? ReadingDirection.fromString(json['sourceReadingDirection'] as String)
        : ReadingDirection.leftToRight,
    targetReadingDirection: json.containsKey('targetReadingDirection')
        ? ReadingDirection.fromString(json['targetReadingDirection'] as String)
        : ReadingDirection.leftToRight,
    words: (json['words'] as List).map((w) => Word.fromJson(w)).toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Vocabulary copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? targetLanguage,
    ReadingDirection? sourceReadingDirection,
    ReadingDirection? targetReadingDirection,
    List<Word>? words,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      sourceReadingDirection: sourceReadingDirection ?? this.sourceReadingDirection,
      targetReadingDirection: targetReadingDirection ?? this.targetReadingDirection,
      words: words ?? this.words,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 