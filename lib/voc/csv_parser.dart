import 'package:lexikon/voc/entry.dart';
import 'package:flutter/material.dart'; 

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