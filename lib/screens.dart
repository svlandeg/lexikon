import 'package:flutter/material.dart';
import 'models.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:math';

class VocabularyListScreen extends StatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  final List<Vocabulary> _vocabularies = [];

  @override
  void initState() {
    super.initState();
    _loadVocabularies();
  }

  Future<void> _loadVocabularies() async {
    final prefs = await SharedPreferences.getInstance();
    final vocabulariesJson = prefs.getStringList('vocabularies') ?? [];
    setState(() {
      _vocabularies.clear();
      _vocabularies.addAll(vocabulariesJson.map((v) => Vocabulary.fromJson(jsonDecode(v))));
    });
  }

  Future<void> _saveVocabularies() async {
    final prefs = await SharedPreferences.getInstance();
    final vocabulariesJson = _vocabularies.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList('vocabularies', vocabulariesJson);
  }

  void _addVocabulary(Vocabulary vocabulary) {
    setState(() {
      _vocabularies.add(vocabulary);
    });
    _saveVocabularies();
  }

  void _removeVocabulary(int index) {
    setState(() {
      _vocabularies.removeAt(index);
    });
    _saveVocabularies();
  }

  void _updateVocabulary(int index, Vocabulary vocabulary) {
    setState(() {
      _vocabularies[index] = vocabulary;
    });
    _saveVocabularies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lexikon - Vocabularies')),
      body: _vocabularies.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No vocabularies yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first vocabulary to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _vocabularies.length,
              itemBuilder: (context, index) {
                final vocabulary = _vocabularies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(vocabulary.name),
                    subtitle: Text('${vocabulary.sourceLanguage} → ${vocabulary.targetLanguage} (${vocabulary.words.length} words)'),
                    leading: const Icon(Icons.book),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Vocabulary',
                          onPressed: () async {
                            final result = await Navigator.push<Vocabulary>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddVocabularyScreen(
                                  initialVocabulary: vocabulary,
                                ),
                              ),
                            );
                            if (result != null) {
                              _updateVocabulary(index, result);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete Vocabulary',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Vocabulary'),
                                content: Text('Are you sure you want to delete "${vocabulary.name}" and all its ${vocabulary.words.length} words?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _removeVocabulary(index);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VocabularyDetailScreen(
                            vocabulary: vocabulary,
                            onVocabularyUpdated: (updatedVocabulary) {
                              _updateVocabulary(index, updatedVocabulary);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Vocabulary>(
            context,
            MaterialPageRoute(builder: (context) => const AddVocabularyScreen()),
          );
          if (result != null) {
            _addVocabulary(result);
          }
        },
        tooltip: 'Add Vocabulary',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddVocabularyScreen extends StatefulWidget {
  final Vocabulary? initialVocabulary;
  const AddVocabularyScreen({super.key, this.initialVocabulary});

  @override
  State<AddVocabularyScreen> createState() => _AddVocabularyScreenState();
}

class _AddVocabularyScreenState extends State<AddVocabularyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sourceLanguageController;
  late final TextEditingController _targetLanguageController;
  late ReadingDirection _sourceReadingDirection;
  late ReadingDirection _targetReadingDirection;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialVocabulary?.name ?? '');
    _sourceLanguageController = TextEditingController(text: widget.initialVocabulary?.sourceLanguage ?? '');
    _targetLanguageController = TextEditingController(text: widget.initialVocabulary?.targetLanguage ?? '');
    _sourceReadingDirection = widget.initialVocabulary?.sourceReadingDirection ?? ReadingDirection.leftToRight;
    _targetReadingDirection = widget.initialVocabulary?.targetReadingDirection ?? ReadingDirection.leftToRight;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sourceLanguageController.dispose();
    _targetLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialVocabulary != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Vocabulary' : 'Add Vocabulary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vocabulary Name',
                  hintText: 'e.g., Spanish Basics, French Travel',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a vocabulary name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourceLanguageController,
                decoration: const InputDecoration(
                  labelText: 'Source Language',
                  hintText: 'e.g., English, Spanish',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter source language' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetLanguageController,
                decoration: const InputDecoration(
                  labelText: 'Target Language',
                  hintText: 'e.g., Spanish, French',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter target language' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReadingDirection>(
                value: _sourceReadingDirection,
                decoration: const InputDecoration(
                  labelText: 'Source Language Reading Direction',
                ),
                items: ReadingDirection.values.map((direction) {
                  return DropdownMenuItem<ReadingDirection>(
                    value: direction,
                    child: Text(direction.displayName),
                  );
                }).toList(),
                onChanged: (ReadingDirection? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sourceReadingDirection = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReadingDirection>(
                value: _targetReadingDirection,
                decoration: const InputDecoration(
                  labelText: 'Target Language Reading Direction',
                ),
                items: ReadingDirection.values.map((direction) {
                  return DropdownMenuItem<ReadingDirection>(
                    value: direction,
                    child: Text(direction.displayName),
                  );
                }).toList(),
                onChanged: (ReadingDirection? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _targetReadingDirection = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final now = DateTime.now();
                    final vocabulary = Vocabulary(
                      id: widget.initialVocabulary?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      sourceLanguage: _sourceLanguageController.text,
                      targetLanguage: _targetLanguageController.text,
                      sourceReadingDirection: _sourceReadingDirection,
                      targetReadingDirection: _targetReadingDirection,
                      words: widget.initialVocabulary?.words ?? [],
                      createdAt: widget.initialVocabulary?.createdAt ?? now,
                      updatedAt: now,
                    );
                    Navigator.pop(context, vocabulary);
                  }
                },
                child: Text(isEditing ? 'Save' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VocabularyDetailScreen extends StatefulWidget {
  final Vocabulary vocabulary;
  final Function(Vocabulary) onVocabularyUpdated;
  
  const VocabularyDetailScreen({
    super.key,
    required this.vocabulary,
    required this.onVocabularyUpdated,
  });

  @override
  State<VocabularyDetailScreen> createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState extends State<VocabularyDetailScreen> {
  late Vocabulary _vocabulary;

  @override
  void initState() {
    super.initState();
    _vocabulary = widget.vocabulary;
  }

  Future<void> _saveVocabulary() async {
    final updatedVocabulary = _vocabulary.copyWith(updatedAt: DateTime.now());
    widget.onVocabularyUpdated(updatedVocabulary);
    setState(() {
      _vocabulary = updatedVocabulary;
    });
  }

  void _addWord(Word word) {
    setState(() {
      _vocabulary = _vocabulary.copyWith(
        words: [..._vocabulary.words, word],
      );
    });
    _saveVocabulary();
  }

  void _removeWord(int index) {
    setState(() {
      final newWords = List<Word>.from(_vocabulary.words);
      newWords.removeAt(index);
      _vocabulary = _vocabulary.copyWith(words: newWords);
    });
    _saveVocabulary();
  }

  void _editWord(int index, Word newWord) {
    setState(() {
      final newWords = List<Word>.from(_vocabulary.words);
      newWords[index] = newWord;
      _vocabulary = _vocabulary.copyWith(words: newWords);
    });
    _saveVocabulary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vocabulary.name),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_vocabulary.sourceLanguage} (${_vocabulary.sourceReadingDirection.displayName}) → ${_vocabulary.targetLanguage} (${_vocabulary.targetReadingDirection.displayName})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_vocabulary.words.length} words',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
          Expanded(
            child: _vocabulary.words.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.translate_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No words yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first word to get started',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _vocabulary.words.length,
                    itemBuilder: (context, index) {
                      final word = _vocabulary.words[index];
                      return ListTile(
                        title: Text(word.source),
                        subtitle: Text(word.target),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () async {
                                final result = await Navigator.push<Word>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddWordScreen(
                                      initialWord: word,
                                      sourceLanguage: _vocabulary.sourceLanguage,
                                      targetLanguage: _vocabulary.targetLanguage,
                                      sourceReadingDirection: _vocabulary.sourceReadingDirection,
                                      targetReadingDirection: _vocabulary.targetReadingDirection,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  _editWord(index, result);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Entry'),
                                    content: const Text('Are you sure you want to delete this entry?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _removeWord(index);
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
                      FloatingActionButton(
              heroTag: 'addWord',
              onPressed: () async {
                final result = await Navigator.push<Word>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddWordScreen(
                      sourceLanguage: _vocabulary.sourceLanguage,
                      targetLanguage: _vocabulary.targetLanguage,
                      sourceReadingDirection: _vocabulary.sourceReadingDirection,
                      targetReadingDirection: _vocabulary.targetReadingDirection,
                    ),
                  ),
                );
                if (result != null) {
                  _addWord(result);
                }
              },
              tooltip: 'Add Word',
              child: const Icon(Icons.add),
            ),
          const SizedBox(height: 16),
                      FloatingActionButton(
              heroTag: 'importCSV',
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);
                  final content = await file.readAsString();
                  final rows = const CsvToListConverter().convert(content, eol: '\n');
                  List<Word> importedWords = [];
                  for (var row in rows) {
                    if (row.length >= 2 && row[0] is String && row[1] is String) {
                      importedWords.add(Word(source: row[0], target: row[1]));
                    }
                  }
                  if (importedWords.isNotEmpty) {
                    final action = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Import Entries'),
                        content: const Text('Do you want to add the imported entries to the existing list, or overwrite the list completely?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'add'),
                            child: const Text('Add'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'overwrite'),
                            child: const Text('Overwrite'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                    if (action == 'add') {
                      setState(() {
                        _vocabulary = _vocabulary.copyWith(
                          words: [..._vocabulary.words, ...importedWords],
                        );
                      });
                      await _saveVocabulary();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entries added successfully.')));
                      }
                    } else if (action == 'overwrite') {
                      setState(() {
                        _vocabulary = _vocabulary.copyWith(words: importedWords);
                      });
                      await _saveVocabulary();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vocabulary overwritten successfully.')));
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid entries found in CSV.')));
                    }
                  }
                }
              },
              tooltip: 'Import CSV',
              child: const Icon(Icons.upload_file),
            ),
        ],
      ),
    );
  }
}

class AddWordScreen extends StatefulWidget {
  final Word? initialWord;
  final String sourceLanguage;
  final String targetLanguage;
  final ReadingDirection sourceReadingDirection;
  final ReadingDirection targetReadingDirection;
  const AddWordScreen({
    super.key, 
    this.initialWord, 
    required this.sourceLanguage, 
    required this.targetLanguage,
    required this.sourceReadingDirection,
    required this.targetReadingDirection,
  });

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sourceController;
  late final TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(text: widget.initialWord?.source ?? '');
    _targetController = TextEditingController(text: widget.initialWord?.target ?? '');
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialWord != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Entry' : 'Add Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _sourceController,
                decoration: InputDecoration(
                  labelText: 'Source Language (${widget.sourceLanguage})',
                  hintText: 'Enter a source language word',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a source language word' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target Language (${widget.targetLanguage})',
                  hintText: 'Enter a target language word',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a target language word' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      Word(
                        source: _sourceController.text,
                        target: _targetController.text,
                      ),
                    );
                  }
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class FlashcardScreen extends StatefulWidget {
  final List<Word> words;
  final int count;
  final ReadingDirection sourceReadingDirection;
  final ReadingDirection targetReadingDirection;
  const FlashcardScreen({
    super.key, 
    required this.words, 
    required this.count,
    required this.sourceReadingDirection,
    required this.targetReadingDirection,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late List<Word> _quizWords;
  int _current = 0;
  int _correct = 0;
  int _incorrect = 0;
  String? _feedback;
  final _controller = TextEditingController();
  bool _showingFeedback = false;
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quizWords = List<Word>.from(widget.words);
    _quizWords.shuffle();
    if (_quizWords.length > widget.count) {
      _quizWords = _quizWords.sublist(0, widget.count);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _requestInputFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_showingFeedback) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  void _requestKeyboardFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showingFeedback) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  TextDirection _getTextDirection(ReadingDirection direction) {
    switch (direction) {
      case ReadingDirection.rightToLeft:
        return TextDirection.rtl;
      case ReadingDirection.leftToRight:
      default:
        return TextDirection.ltr;
    }
  }

  void _submit() {
    if (_showingFeedback) {
      setState(() {
        _feedback = null;
        _showingFeedback = false;
        _controller.clear();
        _current++;
      });
      _requestInputFocus();
      return;
    }
    final userInput = _controller.text.trim().toLowerCase();
    final correctAnswer = _quizWords[_current].target.trim().toLowerCase();
    if (userInput == correctAnswer) {
      setState(() {
        _correct++;
        _feedback = 'Correct! The translation is: ${_quizWords[_current].target}';
        _showingFeedback = true;
      });
      _requestKeyboardFocus();
    } else {
      setState(() {
        _incorrect++;
        _feedback = 'Incorrect. The correct answer is: ${_quizWords[_current].target}';
        _showingFeedback = true;
      });
      _requestKeyboardFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_current >= _quizWords.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Quiz complete!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text('Correct:  [32m$_correct [0m'),
              Text('Incorrect:  [31m$_incorrect [0m'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Words'),
              ),
            ],
          ),
        ),
      );
    }
    final word = _quizWords[_current];
    if (!_showingFeedback) {
      _requestInputFocus();
    } else {
      _requestKeyboardFocus();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Source Language:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              word.source, 
              style: Theme.of(context).textTheme.headlineMedium,
              textDirection: _getTextDirection(widget.sourceReadingDirection),
            ),
            const SizedBox(height: 32),
            RawKeyboardListener(
              focusNode: _keyboardFocusNode,
              autofocus: true,
              onKey: (event) {
                if (_showingFeedback && event.isKeyPressed(LogicalKeyboardKey.enter) && event.runtimeType.toString() == 'RawKeyDownEvent') {
                  setState(() {
                    _feedback = null;
                    _showingFeedback = false;
                    _controller.clear();
                    _current++;
                  });
                  _requestInputFocus();
                }
              },
              child: Column(
                children: [
                  if (_feedback == null) ...[
                    TextField(
                      controller: _controller,
                      focusNode: _inputFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Type the target language equivalent',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _submit(),
                      enabled: !_showingFeedback,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit'),
                    ),
                  ] else ...[
                    Text(_feedback!, style: TextStyle(fontSize: 20, color: _feedback!.startsWith('Correct!') ? Colors.green : Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _feedback = null;
                          _showingFeedback = false;
                          _controller.clear();
                          _current++;
                        });
                        _requestInputFocus();
                      },
                      child: const Text('Next'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Progress: ${_current + 1} / ${_quizWords.length}'),
          ],
        ),
      ),
    );
  }
}

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
                  child: Text('${vocabulary.name} (${vocabulary.words.length} words)'),
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
              
              if (_selectedVocabulary!.words.isEmpty) ...[
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
                  subtitle: Text('Practice with ${_selectedVocabulary!.words.length} words'),
                  onTap: () async {
                    final count = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        int selected = _selectedVocabulary!.words.length;
                        return AlertDialog(
                          title: const Text('How many words to practice?'),
                          content: StatefulBuilder(
                            builder: (context, setState) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Slider(
                                  value: selected.toDouble(),
                                  min: 1,
                                  max: _selectedVocabulary!.words.length.toDouble(),
                                  divisions: _selectedVocabulary!.words.length - 1,
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
                          words: _selectedVocabulary!.words,
                          count: count,
                          sourceReadingDirection: _selectedVocabulary!.sourceReadingDirection,
                          targetReadingDirection: _selectedVocabulary!.targetReadingDirection,
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
                        builder: (context) => WordSearchScreen(words: _selectedVocabulary!.words),
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

class PracticeHomeScreen extends StatefulWidget {
  final Vocabulary vocabulary;
  const PracticeHomeScreen({super.key, required this.vocabulary});

  @override
  State<PracticeHomeScreen> createState() => _PracticeHomeScreenState();
}

class _PracticeHomeScreenState extends State<PracticeHomeScreen> {
  List<Word> _words = [];

  @override
  void initState() {
    super.initState();
    _words = List<Word>.from(widget.vocabulary.words);
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Practice: ${widget.vocabulary.name}')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No words to practice',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Add some words to this vocabulary first',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Practice: ${widget.vocabulary.name}')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Flashcards'),
            onTap: () async {
              final count = await showDialog<int>(
                context: context,
                builder: (context) {
                  int selected = _words.length;
                  return AlertDialog(
                    title: const Text('How many words to practice?'),
                    content: StatefulBuilder(
                      builder: (context, setState) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Slider(
                            value: selected.toDouble(),
                            min: 1,
                            max: _words.length.toDouble(),
                            divisions: _words.length - 1,
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
                      words: _words, 
                      count: count,
                      sourceReadingDirection: widget.vocabulary.sourceReadingDirection,
                      targetReadingDirection: widget.vocabulary.targetReadingDirection,
                    ),
                  ),
                );
              }
            },
          ),
          // Word Search Practice
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: const Text('Word Search'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WordSearchScreen(words: _words),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class WordSearchScreen extends StatefulWidget {
  final List<Word> words;
  const WordSearchScreen({super.key, required this.words});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  static const int _numPairs = 10;
  late List<Word> _selectedWords;
  late List<List<String>> _grid;
  late int _gridSize;
  late List<_PlacedWord> _placedWords;
  Set<int> _foundWordIndexes = {};
  List<_FoundWord> _foundWords = [];
  int? _selectStartRow;
  int? _selectStartCol;
  int? _selectEndRow;
  int? _selectEndCol;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    // Set grid size to always be 12x12
    _gridSize = 12;
    final rand = Random();
    final allWords = List<Word>.from(widget.words)
        .where((w) {
          final trimmed = w.target.trim();
          return !trimmed.contains(' ') && trimmed.length <= _gridSize;
        })
        .toList();
    allWords.shuffle(rand);
    _selectedWords = allWords.take(_numPairs).toList();
    final wordList = _selectedWords.map((w) => w.target.trim().toUpperCase()).toList();
    _placedWords = [];
    _grid = _generateGrid(_gridSize, wordList, actuallyPlaced: _placedWords);
    _foundWordIndexes.clear();
    _foundWords.clear();
    _selectStartRow = null;
    _selectStartCol = null;
    _selectEndRow = null;
    _selectEndCol = null;
  }

  List<List<String>> _generateGrid(int gridSize, List<String> wordList, {List<_PlacedWord>? actuallyPlaced}) {
    final grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => ''));
    final rand = Random();
    final placed = <_PlacedWord>[];
    for (final word in wordList) {
      final isHorizontal = rand.nextBool();
      final maxStart = gridSize - word.length;
      if (maxStart < 0) continue;
      int row = 0, col = 0;
      bool placedWord = false;
      for (int attempt = 0; attempt < 100 && !placedWord; attempt++) {
        if (isHorizontal) {
          row = rand.nextInt(gridSize);
          col = rand.nextInt(maxStart + 1);
          bool canPlace = true;
          for (int i = 0; i < word.length; i++) {
            if (grid[row][col + i] != '' && grid[row][col + i] != word[i]) {
              canPlace = false;
              break;
            }
          }
          if (canPlace) {
            for (int i = 0; i < word.length; i++) {
              grid[row][col + i] = word[i];
            }
            placedWord = true;
            placed.add(_PlacedWord(
              word: word,
              start: [row, col],
              end: [row, col + word.length - 1],
              isHorizontal: true,
            ));
          }
        } else {
          row = rand.nextInt(maxStart + 1);
          col = rand.nextInt(gridSize);
          bool canPlace = true;
          for (int i = 0; i < word.length; i++) {
            if (grid[row + i][col] != '' && grid[row + i][col] != word[i]) {
              canPlace = false;
              break;
            }
          }
          if (canPlace) {
            for (int i = 0; i < word.length; i++) {
              grid[row + i][col] = word[i];
            }
            placedWord = true;
            placed.add(_PlacedWord(
              word: word,
              start: [row, col],
              end: [row + word.length - 1, col],
              isHorizontal: false,
            ));
          }
        }
      }
    }
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == '') {
          grid[r][c] = String.fromCharCode(rand.nextInt(26) + 65);
        }
      }
    }
    if (actuallyPlaced != null) {
      actuallyPlaced.clear();
      actuallyPlaced.addAll(placed);
    }
    return grid;
  }

  void _onCellTap(int row, int col) {
    setState(() {
      if (_selectStartRow == null || _selectStartCol == null) {
        _selectStartRow = row;
        _selectStartCol = col;
        _selectEndRow = null;
        _selectEndCol = null;
      } else if (_selectEndRow == null || _selectEndCol == null) {
        // Only allow straight lines
        if (row == _selectStartRow || col == _selectStartCol) {
          _selectEndRow = row;
          _selectEndCol = col;
          _checkSelection();
        } else {
          // Reset if not straight
          _selectStartRow = row;
          _selectStartCol = col;
          _selectEndRow = null;
          _selectEndCol = null;
        }
      } else {
        _selectStartRow = row;
        _selectStartCol = col;
        _selectEndRow = null;
        _selectEndCol = null;
      }
    });
  }

  void _checkSelection() {
    if (_selectStartRow == null || _selectStartCol == null || _selectEndRow == null || _selectEndCol == null) return;
    final start = [_selectStartRow!, _selectStartCol!];
    final end = [_selectEndRow!, _selectEndCol!];
    // Only allow horizontal or vertical
    if (start[0] != end[0] && start[1] != end[1]) return;
    // Get the word
    List<String> selected = [];
    if (start[0] == end[0]) {
      // Horizontal - only allow left to right selection
      int row = start[0];
      if (start[1] > end[1]) {
        // User selected right to left, which is not allowed
        setState(() {
          _selectStartRow = null;
          _selectStartCol = null;
          _selectEndRow = null;
          _selectEndCol = null;
        });
        return;
      }
      for (int c = start[1]; c <= end[1]; c++) {
        selected.add(_grid[row][c]);
      }
    } else {
      // Vertical - only allow top to bottom selection
      int col = start[1];
      if (start[0] > end[0]) {
        // User selected bottom to top, which is not allowed
        setState(() {
          _selectStartRow = null;
          _selectStartCol = null;
          _selectEndRow = null;
          _selectEndCol = null;
        });
        return;
      }
      for (int r = start[0]; r <= end[0]; r++) {
        selected.add(_grid[r][col]);
      }
    }
    final selectedWord = selected.join();
    // Check if matches any placed word and not already found
    bool found = false;
    for (int i = 0; i < _placedWords.length; i++) {
      if (_foundWordIndexes.contains(i)) continue;
      if (_placedWords[i].word == selectedWord) {
        setState(() {
          _foundWordIndexes.add(i);
          _foundWords.add(_FoundWord(
            index: i,
            word: selectedWord,
            start: _placedWords[i].start,
            end: _placedWords[i].end,
            isHorizontal: _placedWords[i].isHorizontal,
          ));
        });
        found = true;
        break;
      }
    }
    if (found) {
      // Keep highlight for a short delay before resetting
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _selectStartRow = null;
            _selectStartCol = null;
            _selectEndRow = null;
            _selectEndCol = null;
          });
        }
      });
    } else {
      // Reset selection immediately if not found
      setState(() {
        _selectStartRow = null;
        _selectStartCol = null;
        _selectEndRow = null;
        _selectEndCol = null;
      });
    }
  }

  List<int> _getSelectedCells() {
    // If only start cell is set, highlight it
    if (_selectStartRow != null && _selectStartCol != null && (_selectEndRow == null || _selectEndCol == null)) {
      return [_selectStartRow! * _gridSize + _selectStartCol!];
    }
    if (_selectStartRow == null || _selectStartCol == null || _selectEndRow == null || _selectEndCol == null) return [];
    final start = [_selectStartRow!, _selectStartCol!];
    final end = [_selectEndRow!, _selectEndCol!];
    List<int> cells = [];
    if (start[0] == end[0]) {
      // Horizontal - only highlight if left to right
      if (start[1] <= end[1]) {
        int row = start[0];
        for (int c = start[1]; c <= end[1]; c++) {
          cells.add(row * _gridSize + c);
        }
      }
    } else if (start[1] == end[1]) {
      // Vertical - only highlight if top to bottom
      if (start[0] <= end[0]) {
        int col = start[1];
        for (int r = start[0]; r <= end[0]; r++) {
          cells.add(r * _gridSize + col);
        }
      }
    }
    return cells;
  }

  bool _isCellInFoundWord(int row, int col) {
    for (final fw in _foundWords) {
      if (fw.isHorizontal) {
        if (row == fw.start[0] && col >= fw.start[1] && col <= fw.end[1]) return true;
      } else {
        if (col == fw.start[1] && row >= fw.start[0] && row <= fw.end[0]) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const double cellSize = 36.0;
    final double gridPixelSize = _gridSize * cellSize;
    final selectedCells = _getSelectedCells();
    return Scaffold(
      appBar: AppBar(title: const Text('Word Search')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: gridPixelSize,
                  height: gridPixelSize,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _gridSize * _gridSize,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final row = index ~/ _gridSize;
                      final col = index % _gridSize;
                      final isSelected = selectedCells.contains(index);
                      final isFound = _isCellInFoundWord(row, col);
                      return GestureDetector(
                        onTap: () => _onCellTap(row, col),
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueGrey),
                            color: isFound
                                ? Colors.greenAccent
                                : isSelected
                                    ? Colors.yellowAccent
                                    : Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              _grid[row][col],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hints (Source Language):',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: _selectedWords
                      .map((w) => Chip(label: Text(w.source)))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text('Found: ${_foundWords.length} / $_numPairs', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(_initGame),
                  child: const Text('Restart'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacedWord {
  final String word;
  final List<int> start;
  final List<int> end;
  final bool isHorizontal;
  _PlacedWord({required this.word, required this.start, required this.end, required this.isHorizontal});
}

class _FoundWord {
  final int index;
  final String word;
  final List<int> start;
  final List<int> end;
  final bool isHorizontal;
  _FoundWord({required this.index, required this.word, required this.start, required this.end, required this.isHorizontal});
} 