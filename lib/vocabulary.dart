import 'package:flutter/material.dart';

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
  final TextDirection sourceReadingDirection;
  final TextDirection targetReadingDirection;
  final List<Entry> entries;

  Vocabulary({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.sourceReadingDirection = TextDirection.ltr,
    this.targetReadingDirection = TextDirection.ltr,
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
    sourceReadingDirection: TextDirection.values.firstWhere(
      (e) => e.name == (json['sourceReadingDirection'] as String),
      orElse: () => TextDirection.ltr,
    ),
    targetReadingDirection: TextDirection.values.firstWhere(
      (e) => e.name == (json['targetReadingDirection'] as String),
      orElse: () => TextDirection.ltr,
    ),
    entries: (json['entries'] as List).map((e) => Entry.fromJson(e)).toList(),
  );

  Vocabulary copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? targetLanguage,
    TextDirection? sourceReadingDirection,
    TextDirection? targetReadingDirection,
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