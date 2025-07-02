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