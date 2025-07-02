class Word {
  final String text;
  final String translation;

  Word({required this.text, required this.translation});

  Map<String, dynamic> toJson() => {
    'text': text,
    'translation': translation,
  };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    text: json['text'] as String,
    translation: json['translation'] as String,
  );
} 