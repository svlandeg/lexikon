import 'package:flutter/material.dart';
import 'vocabulary.dart';
import 'wordsearch_screen.dart';
import 'vocabulary_screen.dart';
import 'flashcard_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:math';

export 'vocabulary_screen.dart' show VocabularyListScreen;

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  List<Vocabulary> _vocabularies = [];
  Vocabulary? _selectedVocabulary;

  @override
  void initState() {
    super.initState();
    _loadVocabularies();
  }

  Future<void> _loadVocabularies() async {
    final prefs = await SharedPreferences.getInstance();
    final vocabulariesJson = prefs.getStringList('vocabularies') ?? [];
    setState(() {
      _vocabularies = vocabulariesJson.map((v) => Vocabulary.fromJson(jsonDecode(v))).toList();
      if (_vocabularies.isNotEmpty) {
        _selectedVocabulary = _vocabularies.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_vocabularies.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No vocabularies available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Create a vocabulary first to start practicing',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vocabulary Selector
            Text(
              'Select Vocabulary:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Vocabulary>(
              value: _selectedVocabulary,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _vocabularies.map((vocabulary) {
                return DropdownMenuItem<Vocabulary>(
                  value: vocabulary,
                  child: Text('${vocabulary.name} (${vocabulary.entries.length} entries)'),
                );
              }).toList(),
              onChanged: (Vocabulary? newValue) {
                setState(() {
                  _selectedVocabulary = newValue;
                });
              },
            ),
            const SizedBox(height: 32),
            
            // Practice Options
            if (_selectedVocabulary != null) ...[
              Text(
                'Practice Options:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              if (_selectedVocabulary!.entries.isEmpty) ...[
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(height: 8),
                        Text(
                          'This vocabulary has no words yet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Add some words to start practicing'),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.quiz),
                  title: const Text('Flashcards'),
                  subtitle: const Text('Type the correct translation'),
                  onTap: () async {
                    final count = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        int selected = _selectedVocabulary!.entries.length;
                        return AlertDialog(
                          title: const Text('How many words to practice?'),
                          content: StatefulBuilder(
                            builder: (context, setState) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Slider(
                                  value: selected.toDouble(),
                                  min: 1,
                                  max: _selectedVocabulary!.entries.length.toDouble(),
                                  divisions: _selectedVocabulary!.entries.length - 1,
                                  label: selected.toString(),
                                  onChanged: (v) => setState(() => selected = v.round()),
                                ),
                                Text('Words: $selected'),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, selected),
                              child: const Text('Start'),
                            ),
                          ],
                        );
                      },
                    );
                    if (count != null && count > 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                                                  builder: (context) => FlashcardScreen(
                          entries: _selectedVocabulary!.entries,
                          count: count,
                          sourceReadingDirection: _selectedVocabulary!.sourceReadingDirection,
                          targetReadingDirection: _selectedVocabulary!.targetReadingDirection,
                          sourceLanguage: _selectedVocabulary!.sourceLanguage,
                          targetLanguage: _selectedVocabulary!.targetLanguage,
                        ),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.grid_on),
                  title: const Text('Word Search'),
                  subtitle: Text('Find words in a grid puzzle'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WordSearchScreen(entries: _selectedVocabulary!.entries, readingDirection: _selectedVocabulary!.targetReadingDirection),
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
} 