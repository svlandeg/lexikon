import 'package:flutter/material.dart';
import 'vocabulary.dart';
import 'wordsearch_screen.dart';
import 'flashcard_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:math';
import 'scrambledword_screen.dart';
import 'connect_screen.dart';

// Color definitions for PracticeScreen
const Color iconC = Colors.grey;
const Color textC = Colors.grey;

const int kDefaultFlashcardCount = 20;

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
              Icon(Icons.school_outlined, size: 64, color: iconC),
              SizedBox(height: 16),
              Text(
                'No vocabularies available',
                style: TextStyle(fontSize: 18, color: textC),
              ),
              SizedBox(height: 8),
              Text(
                'Create a vocabulary first to start practicing',
                style: TextStyle(color: textC),
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
                    final entryCount = _selectedVocabulary!.entries.length;
                    int? count;
                    if (entryCount == 1) {
                      count = await showDialog<int>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Practice Flashcards'),
                          content: const Text('There is only one word in this vocabulary.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, 1),
                              child: const Text('Start'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      count = await showDialog<int>(
                        context: context,
                        builder: (context) {
                          int selected = entryCount >= kDefaultFlashcardCount ? kDefaultFlashcardCount : entryCount;
                          final FocusNode startButtonFocusNode = FocusNode();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            startButtonFocusNode.requestFocus();
                          });
                          return AlertDialog(
                            title: const Text('How many words to practice?'),
                            content: StatefulBuilder(
                              builder: (context, setState) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Slider(
                                    value: selected.toDouble(),
                                    min: 1,
                                    max: entryCount.toDouble(),
                                    divisions: entryCount - 1,
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
                                focusNode: startButtonFocusNode,
                                onPressed: () => Navigator.pop(context, selected),
                                child: const Text('Start'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (count != null && count > 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardScreen(
                            vocabulary: _selectedVocabulary!,
                            count: count!, // use non-null assertion
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
                ListTile(
                  leading: const Icon(Icons.shuffle),
                  title: const Text('Scrambled Word'),
                  subtitle: const Text('Reorder scrambled letters to form the translation'),
                  onTap: () async {
                    final entryCount = _selectedVocabulary!.entries.length;
                    int? count;
                    if (entryCount == 1) {
                      count = await showDialog<int>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Practice Scrambled Words'),
                          content: const Text('There is only one word in this vocabulary.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, 1),
                              child: const Text('Start'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      count = await showDialog<int>(
                        context: context,
                        builder: (context) {
                          int selected = entryCount >= kDefaultFlashcardCount ? kDefaultFlashcardCount : entryCount;
                          final FocusNode startButtonFocusNode = FocusNode();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            startButtonFocusNode.requestFocus();
                          });
                          return AlertDialog(
                            title: const Text('How many words to practice?'),
                            content: StatefulBuilder(
                              builder: (context, setState) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Slider(
                                    value: selected.toDouble(),
                                    min: 1,
                                    max: entryCount.toDouble(),
                                    divisions: entryCount - 1,
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
                                focusNode: startButtonFocusNode,
                                onPressed: () => Navigator.pop(context, selected),
                                child: const Text('Start'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (count != null && count > 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScrambledWordScreen(
                            vocabulary: _selectedVocabulary!,
                            count: count!,
                          ),
                        ),
                      );
                    }
                  },
                ),
                // Connect Exercise Option
                ListTile(
                  leading: const Icon(Icons.compare_arrows),
                  title: const Text('Connect'),
                  subtitle: const Text('Match source and target words by drawing connections'),
                  enabled: _selectedVocabulary!.entries.isNotEmpty,
                  onTap: _selectedVocabulary!.entries.isEmpty
                      ? null
                      : () async {
                          final entries = _selectedVocabulary!.entries;
                          final entryCount = entries.length;
                          List<Map<String, String>> pairs = entries
                              .map((e) => {'source': e.sourceText, 'target': e.target})
                              .toList();
                          if (entryCount < 5) {
                            // Fewer than 5: use all
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConnectScreen(wordPairs: pairs),
                              ),
                            );
                          } else if (entryCount < 10) {
                            // 5-9: use 5 random
                            pairs.shuffle();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConnectScreen(wordPairs: pairs.take(5).toList()),
                              ),
                            );
                          } else {
                            // 10 or more: show slider dialog for multiples of 5
                            int maxCount = (entryCount ~/ 5) * 5;
                            int selected = 5;
                            final FocusNode startButtonFocusNode = FocusNode();
                            int? count = await showDialog<int>(
                              context: context,
                              builder: (context) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  startButtonFocusNode.requestFocus();
                                });
                                return AlertDialog(
                                  title: const Text('How many word pairs to practice?'),
                                  content: StatefulBuilder(
                                    builder: (context, setState) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Slider(
                                          value: selected.toDouble(),
                                          min: 5,
                                          max: maxCount.toDouble(),
                                          divisions: (maxCount ~/ 5) - 1,
                                          label: selected.toString(),
                                          onChanged: (v) => setState(() => selected = (v ~/ 5) * 5),
                                        ),
                                        Text('Pairs: $selected'),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      focusNode: startButtonFocusNode,
                                      onPressed: () => Navigator.pop(context, selected),
                                      child: const Text('Start'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (count != null && count > 0) {
                              pairs.shuffle();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConnectScreen(wordPairs: pairs.take(count).toList()),
                                ),
                              );
                            }
                          }
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