import 'package:flutter/material.dart';
import 'vocabulary.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:math';
import 'package:unicode_data/unicode_data.dart';

// Helper class for placement options
class _PlacementOption {
  final int row;
  final int col;
  final bool isHorizontal;
  final int overlap;
  _PlacementOption(this.row, this.col, this.isHorizontal, this.overlap);
}

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
                    subtitle: Text('${vocabulary.sourceLanguage} → ${vocabulary.targetLanguage} (${vocabulary.entries.length} entries)'),
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
                                content: Text('Are you sure you want to delete "${vocabulary.name}" and all its ${vocabulary.entries.length} words?'),
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
                      entries: widget.initialVocabulary?.entries ?? [],
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
    widget.onVocabularyUpdated(_vocabulary);
    setState(() {
      // no updatedAt
    });
  }

  void _addEntry(Entry entry) {
    setState(() {
      _vocabulary = _vocabulary.copyWith(
        entries: [..._vocabulary.entries, entry],
      );
    });
    _saveVocabulary();
  }

  void _removeEntry(int index) {
    setState(() {
      final newEntries = List<Entry>.from(_vocabulary.entries);
      newEntries.removeAt(index);
      _vocabulary = _vocabulary.copyWith(entries: newEntries);
    });
    _saveVocabulary();
  }

  void _editEntry(int index, Entry newEntry) {
    setState(() {
      final newEntries = List<Entry>.from(_vocabulary.entries);
      newEntries[index] = newEntry;
      _vocabulary = _vocabulary.copyWith(entries: newEntries);
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
                        '${_vocabulary.entries.length} words',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
          Expanded(
            child: _vocabulary.entries.isEmpty
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
                    itemCount: _vocabulary.entries.length,
                    itemBuilder: (context, index) {
                      final entry = _vocabulary.entries[index];
                      return ListTile(
                        title: Text(entry.source),
                        subtitle: Text(entry.target),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () async {
                                final result = await Navigator.push<Entry>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEntryScreen(
                                      initialEntry: entry,
                                      sourceLanguage: _vocabulary.sourceLanguage,
                                      targetLanguage: _vocabulary.targetLanguage,
                                      sourceReadingDirection: _vocabulary.sourceReadingDirection,
                                      targetReadingDirection: _vocabulary.targetReadingDirection,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  _editEntry(index, result);
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
                                          _removeEntry(index);
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
              heroTag: 'addEntry',
              onPressed: () async {
                final result = await Navigator.push<Entry>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEntryScreen(
                      sourceLanguage: _vocabulary.sourceLanguage,
                      targetLanguage: _vocabulary.targetLanguage,
                      sourceReadingDirection: _vocabulary.sourceReadingDirection,
                      targetReadingDirection: _vocabulary.targetReadingDirection,
                    ),
                  ),
                );
                if (result != null) {
                  _addEntry(result);
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
                  List<Entry> importedEntries = [];
                  for (var row in rows) {
                    if (row.length >= 2 && row[0] is String && row[1] is String) {
                      importedEntries.add(Entry(source: row[0], target: row[1]));
                    }
                  }
                  if (importedEntries.isNotEmpty) {
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
                          entries: [..._vocabulary.entries, ...importedEntries],
                        );
                      });
                      await _saveVocabulary();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entries added successfully.')));
                      }
                    } else if (action == 'overwrite') {
                      setState(() {
                        _vocabulary = _vocabulary.copyWith(entries: importedEntries);
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

class AddEntryScreen extends StatefulWidget {
  final Entry? initialEntry;
  final String sourceLanguage;
  final String targetLanguage;
  final ReadingDirection sourceReadingDirection;
  final ReadingDirection targetReadingDirection;
  const AddEntryScreen({
    super.key, 
    this.initialEntry, 
    required this.sourceLanguage, 
    required this.targetLanguage,
    required this.sourceReadingDirection,
    required this.targetReadingDirection,
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sourceController;
  late final TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(text: widget.initialEntry?.source ?? '');
    _targetController = TextEditingController(text: widget.initialEntry?.target ?? '');
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEntry != null;
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
                  labelText: 'Source Language ( ${widget.sourceLanguage})',
                  hintText: 'Enter a word from the source language',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a source language entry' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target Language ( ${widget.targetLanguage})',
                  hintText: 'Enter a word from the target language',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a target language entry' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      Entry(
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
  final List<Entry> entries;
  final int count;
  final ReadingDirection sourceReadingDirection;
  final ReadingDirection targetReadingDirection;
  final String sourceLanguage;
  final String targetLanguage;
  const FlashcardScreen({
    super.key, 
    required this.entries, 
    required this.count,
    required this.sourceReadingDirection,
    required this.targetReadingDirection,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late List<Entry> _quizEntries;
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
    _quizEntries = List<Entry>.from(widget.entries);
    _quizEntries.shuffle();
    if (_quizEntries.length > widget.count) {
      _quizEntries = _quizEntries.sublist(0, widget.count);
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
    final correctAnswer = _quizEntries[_current].target.trim().toLowerCase();
    if (userInput == correctAnswer) {
      setState(() {
        _correct++;
        _feedback = 'Correct!\nThe ${widget.targetLanguage} translation is: ${_quizEntries[_current].target}';
        _showingFeedback = true;
      });
      _requestKeyboardFocus();
    } else {
      setState(() {
        _incorrect++;
        _feedback = 'Incorrect.\nThe correct ${widget.targetLanguage} translation is: ${_quizEntries[_current].target}';
        _showingFeedback = true;
      });
      _requestKeyboardFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_current >= _quizEntries.length) {
      int total = _correct + _incorrect;
      double percent = total > 0 ? (_correct / total) * 100 : 0;
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Quiz complete!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text('Correct: $_correct', style: const TextStyle(color: Colors.green, fontSize: 18)),
              Text('Incorrect: $_incorrect', style: const TextStyle(color: Colors.red, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Total score: ${percent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to practice'),
              ),
            ],
          ),
        ),
      );
    }
    final entry = _quizEntries[_current];
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
            Text('${widget.sourceLanguage}:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              entry.source, 
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
                      decoration: InputDecoration(
                        labelText: '${widget.targetLanguage} translation',
                        border: const OutlineInputBorder(),
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
                    Text(
                      _feedback!,
                      style: TextStyle(fontSize: 20, color: _feedback!.startsWith('Correct!') ? Colors.green : Colors.red),
                      softWrap: true,
                      maxLines: null,
                    ),
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
            Text('Progress: ${_current + 1} / ${_quizEntries.length}'),
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

class PracticeHomeScreen extends StatefulWidget {
  final Vocabulary vocabulary;
  const PracticeHomeScreen({super.key, required this.vocabulary});

  @override
  State<PracticeHomeScreen> createState() => _PracticeHomeScreenState();
}

class _PracticeHomeScreenState extends State<PracticeHomeScreen> {
  List<Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    _entries = List<Entry>.from(widget.vocabulary.entries);
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
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
                  int selected = _entries.length;
                  return AlertDialog(
                    title: const Text('How many words to practice?'),
                    content: StatefulBuilder(
                      builder: (context, setState) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Slider(
                            value: selected.toDouble(),
                            min: 1,
                            max: _entries.length.toDouble(),
                            divisions: _entries.length - 1,
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
                      entries: _entries, 
                      count: count,
                      sourceReadingDirection: widget.vocabulary.sourceReadingDirection,
                      targetReadingDirection: widget.vocabulary.targetReadingDirection,
                      sourceLanguage: widget.vocabulary.sourceLanguage,
                      targetLanguage: widget.vocabulary.targetLanguage,
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
                  builder: (context) => WordSearchScreen(entries: _entries, readingDirection: widget.vocabulary.targetReadingDirection),
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
  final List<Entry> entries;
  final ReadingDirection readingDirection;
  const WordSearchScreen({super.key, required this.entries, required this.readingDirection});

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  static const int _numPairs = 12;
  late List<Entry> _selectedEntries;
  late List<List<String>> _grid;
  late int _gridSize;
  late List<_PlacedWord> _placedWords;
  Set<int> _foundWordIndexes = {};
  List<_FoundWord> _foundWords = [];
  int? _selectStartRow;
  int? _selectStartCol;
  int? _selectEndRow;
  int? _selectEndCol;
  bool _showSourceHints = true;
  late List<List<bool>> _foundMatrix;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    // Set grid size to always be 10x10
    _gridSize = 10;
    final rand = Random();
    final allEntries = List<Entry>.from(widget.entries)
        .where((e) {
          final trimmed = e.target.trim();
          // Exclude words with spaces or punctuation
          final hasPunctuation = RegExp(r'[\p{P}]', unicode: true).hasMatch(trimmed);
          return !trimmed.contains(' ') && !hasPunctuation && trimmed.length <= _gridSize;
        })
        .toList();
    allEntries.shuffle(rand);
    _selectedEntries = allEntries.take(_numPairs).toList();
    final wordList = _selectedEntries.map((e) => e.target.trim().toUpperCase()).toList();
    _placedWords = [];
    _grid = _generateGrid(_gridSize, wordList, widget.readingDirection, actuallyPlaced: _placedWords);
    _foundWordIndexes.clear();
    _foundWords.clear();
    _selectStartRow = null;
    _selectStartCol = null;
    _selectEndRow = null;
    _selectEndCol = null;
    _foundMatrix = List.generate(_gridSize, (_) => List.filled(_gridSize, false));
  }

  List<List<String>> _generateGrid(int gridSize, List<String> wordList, ReadingDirection direction, {List<_PlacedWord>? actuallyPlaced}) {
    final grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => ''));
    final rand = Random();
    final placed = <_PlacedWord>[];

    // --- Begin: Unicode-aware alphabet detection ---
    // 1. Collect all unique letters from all words
    final Set<String> uniqueLetters = {};
    for (final word in wordList) {
      for (final rune in word.runes) {
        final char = String.fromCharCode(rune);
        if (RegExp(r'\p{L}', unicode: true).hasMatch(char)) {
          uniqueLetters.add(char);
        }
      }
    }

    // 2. Determine script for each letter
    String? detectedScript;
    final Map<String, int> scriptCounts = {};
    for (final letter in uniqueLetters) {
      final script = _getUnicodeScript(letter);
      if (script != null) {
        scriptCounts[script] = (scriptCounts[script] ?? 0) + 1;
      }
    }
    if (scriptCounts.isNotEmpty) {
      detectedScript = scriptCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    // 3. Get full alphabet for the detected script
    List<String> alphabet;
    if (detectedScript != null) {
      alphabet = _getAlphabetForScript(detectedScript, uniqueLetters);
    } else {
      // fallback: use unique letters only
      alphabet = uniqueLetters.toList();
    }
    // --- End: Unicode-aware alphabet detection ---

    for (final wordOrig in wordList) {
      // For RTL, reverse the word string, but placement logic is always left-to-right or top-to-bottom
      final isRTL = direction == ReadingDirection.rightToLeft;
      final word = isRTL ? wordOrig.split("").reversed.join("") : wordOrig;
      List<_PlacementOption> bestOptions = [];
      int maxOverlap = -1;
      for (final isHorizontal in [true, false]) {
        final maxStart = gridSize - word.length;
        if (maxStart < 0) continue;
        for (int row = 0; row < gridSize; row++) {
          for (int col = 0; col < gridSize; col++) {
            if (isHorizontal && col > maxStart) continue;
            if (!isHorizontal && row > maxStart) continue;
            bool canPlace = true;
            int overlap = 0;
            // Prevent two vertical words next to each other or two horizontal words right below each other
            if (isHorizontal) {
              // Check for horizontal word directly above or below
              for (final pw in placed) {
                if (pw.isHorizontal &&
                    ((row == pw.start[0] + 1 || row == pw.start[0] - 1) &&
                     ((col <= pw.end[1] && col + word.length - 1 >= pw.start[1])))) {
                  canPlace = false;
                  break;
                }
              }
            } else {
              // Check for vertical word directly left or right
              for (final pw in placed) {
                if (!pw.isHorizontal &&
                    ((col == pw.start[1] + 1 || col == pw.start[1] - 1) &&
                     ((row <= pw.end[0] && row + word.length - 1 >= pw.start[0])))) {
                  canPlace = false;
                  break;
                }
              }
            }
            if (!canPlace) continue;
            for (int i = 0; i < word.length; i++) {
              int r = isHorizontal ? row : row + i;
              int c = isHorizontal ? col + i : col;
              if (grid[r][c] != '' && grid[r][c] != word[i]) {
                canPlace = false;
                break;
              }
              if (grid[r][c] == word[i]) {
                // Only count overlap if the existing letter is from a word placed in the opposite direction
                bool overlapAllowed = false;
                for (final pw in placed) {
                  if (pw.isHorizontal != isHorizontal) {
                    // Check if this cell is part of pw
                    if (pw.isHorizontal) {
                      if (r == pw.start[0] && c >= pw.start[1] && c <= pw.end[1]) {
                        overlapAllowed = true;
                        break;
                      }
                    } else {
                      if (c == pw.start[1] && r >= pw.start[0] && r <= pw.end[0]) {
                        overlapAllowed = true;
                        break;
                      }
                    }
                  }
                }
                if (overlapAllowed) overlap++;
              }
            }
            if (canPlace) {
              if (overlap > maxOverlap) {
                maxOverlap = overlap;
                bestOptions = [
                  _PlacementOption(row, col, isHorizontal, overlap)
                ];
              } else if (overlap == maxOverlap) {
                bestOptions.add(_PlacementOption(row, col, isHorizontal, overlap));
              }
            }
          }
        }
      }
      if (bestOptions.isNotEmpty) {
        final chosen = bestOptions[rand.nextInt(bestOptions.length)];
        for (int i = 0; i < word.length; i++) {
          int r = chosen.isHorizontal ? chosen.row : chosen.row + i;
          int c = chosen.isHorizontal ? chosen.col + i : chosen.col;
          grid[r][c] = word[i];
        }
        placed.add(_PlacedWord(
          word: wordOrig, // always store the original word
          start: [chosen.row, chosen.col],
          end: chosen.isHorizontal
              ? [chosen.row, chosen.col + word.length - 1]
              : [chosen.row + word.length - 1, chosen.col],
          isHorizontal: chosen.isHorizontal,
        ));
      }
    }
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == '') {
          grid[r][c] = alphabet[rand.nextInt(alphabet.length)];
        }
      }
    }
    if (actuallyPlaced != null) {
      actuallyPlaced.clear();
      actuallyPlaced.addAll(placed);
    }
    return grid;
  }

  // Helper: Detect Unicode script of a single character using unicode_data
  String? _getUnicodeScript(String char) {
    if (char.isEmpty) return null;
    final code = char.runes.first;
    final script = UnicodeScript.scripts.where((s) => code >= s.start && code <= s.end).toList();
    if (script.isEmpty) return null;
    return script.first.name;
  }

  // Helper: Get the alphabet for the script: all unique letters from all target words in the vocabulary, plus common letters for the script
  List<String> _getAlphabetForScript(String script, Set<String> vocabLetters) {
    // 1. Start with all unique letters from the vocabulary (already filtered for letters)
    final Set<String> alphabet = {...vocabLetters};

    // 2. Add most common letters for the script (if available)
    final List<String>? common = _commonLettersForScript(script);
    if (common != null) {
      for (final letter in common) {
        // Only add if it's not already present and is a printable, non-combining letter
        if (!alphabet.contains(letter) &&
            RegExp(r'^[\p{L}]$', unicode: true).hasMatch(letter) &&
            !RegExp(r'^[\p{M}]$', unicode: true).hasMatch(letter)) {
          alphabet.add(letter);
        }
      }
    }
    final sorted = alphabet.toList()..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  // Helper: Curated list of most common letters for major scripts (alphabetized)
  List<String>? _commonLettersForScript(String script) {
    switch (script.toLowerCase()) {
      case 'latin':
        return ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
      case 'cyrillic':
        return ['А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'];
      case 'greek':
        return ['Α','Β','Γ','Δ','Ε','Ζ','Η','Θ','Ι','Κ','Λ','Μ','Ν','Ξ','Ο','Π','Ρ','Σ','Τ','Υ','Φ','Χ','Ψ','Ω'];
      case 'arabic':
        return ['ا','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي'];
      default:
        return null;
    }
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

  void _markWordFound(_PlacedWord word) {
    final start = word.start;
    final end = word.end;
    if (word.isHorizontal) {
      for (int c = start[1]; c <= end[1]; c++) {
        _foundMatrix[start[0]][c] = true;
      }
    } else {
      for (int r = start[0]; r <= end[0]; r++) {
        _foundMatrix[r][start[1]] = true;
      }
    }
  }

  void _checkSelection() {
    if (_selectStartRow == null || _selectStartCol == null || _selectEndRow == null || _selectEndCol == null) return;
    final start = [_selectStartRow!, _selectStartCol!];
    final end = [_selectEndRow!, _selectEndCol!];
    // Only allow horizontal or vertical
    if (start[0] != end[0] && start[1] != end[1]) return;
    final isRTL = widget.readingDirection == ReadingDirection.rightToLeft;
    List<String> selected = [];
    if (start[0] == end[0]) {
      // Horizontal
      int row = start[0];
      if (!isRTL) {
        // LTR: only allow left to right
        if (start[1] > end[1]) {
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
        // RTL: only allow right to left
        if (start[1] < end[1]) {
          setState(() {
            _selectStartRow = null;
            _selectStartCol = null;
            _selectEndRow = null;
            _selectEndCol = null;
          });
          return;
        }
        for (int c = start[1]; c >= end[1]; c--) {
          selected.add(_grid[row][c]);
        }
      }
    } else {
      // Vertical
      int col = start[1];
      if (!isRTL) {
        // LTR: only allow top to bottom
        if (start[0] > end[0]) {
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
      } else {
        // RTL: only allow bottom to top
        if (start[0] < end[0]) {
          setState(() {
            _selectStartRow = null;
            _selectStartCol = null;
            _selectEndRow = null;
            _selectEndCol = null;
          });
          return;
        }
        for (int r = start[0]; r >= end[0]; r--) {
          selected.add(_grid[r][col]);
        }
      }
    }
    final selectedWord = selected.join();
    // Check if matches any placed word and not already found
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
          _markWordFound(_placedWords[i]);
          _selectStartRow = null;
          _selectStartCol = null;
          _selectEndRow = null;
          _selectEndCol = null;
        });
        return;
      }
    }
    // Reset selection immediately if not found
    setState(() {
      _selectStartRow = null;
      _selectStartCol = null;
      _selectEndRow = null;
      _selectEndCol = null;
    });
  }

  List<int> _getSelectedCells() {
    // If only start cell is set, highlight it
    if (_selectStartRow != null && _selectStartCol != null && (_selectEndRow == null || _selectEndCol == null)) {
      return [_selectStartRow! * _gridSize + _selectStartCol!];
    }
    if (_selectStartRow == null || _selectStartCol == null || _selectEndRow == null || _selectEndCol == null) return [];
    final start = [_selectStartRow!, _selectStartCol!];
    final end = [_selectEndRow!, _selectEndCol!];
    final isRTL = widget.readingDirection == ReadingDirection.rightToLeft;
    List<int> cells = [];
    if (start[0] == end[0]) {
      // Horizontal
      if (!isRTL) {
        if (start[1] <= end[1]) {
          int row = start[0];
          for (int c = start[1]; c <= end[1]; c++) {
            cells.add(row * _gridSize + c);
          }
        }
      } else {
        if (start[1] >= end[1]) {
          int row = start[0];
          for (int c = start[1]; c >= end[1]; c--) {
            cells.add(row * _gridSize + c);
          }
        }
      }
    } else if (start[1] == end[1]) {
      // Vertical
      if (!isRTL) {
        if (start[0] <= end[0]) {
          int col = start[1];
          for (int r = start[0]; r <= end[0]; r++) {
            cells.add(r * _gridSize + col);
          }
        }
      } else {
        if (start[0] >= end[0]) {
          int col = start[1];
          for (int r = start[0]; r >= end[0]; r--) {
            cells.add(r * _gridSize + col);
          }
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

  bool _isCellSelected(int row, int col) {
    if (_selectStartRow == null || _selectStartCol == null) return false;
    if (_selectEndRow == null || _selectEndCol == null) {
      return row == _selectStartRow && col == _selectStartCol;
    }
    // Only horizontal or vertical
    if (_selectStartRow == _selectEndRow) {
      if (row == _selectStartRow && col >= _selectStartCol! && col <= _selectEndCol!) return true;
      if (row == _selectStartRow && col <= _selectStartCol! && col >= _selectEndCol!) return true;
    } else if (_selectStartCol == _selectEndCol) {
      if (col == _selectStartCol && row >= _selectStartRow! && row <= _selectEndRow!) return true;
      if (col == _selectStartCol && row <= _selectStartRow! && row >= _selectEndRow!) return true;
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
                      final isSelected = _isCellSelected(row, col);
                      final isFound = _foundMatrix[row][col];
                      return GestureDetector(
                        onTap: () => _onCellTap(row, col),
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueGrey),
                            color: isSelected
                                ? Colors.yellowAccent
                                : isFound
                                    ? Colors.greenAccent
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Switch(
                      value: _showSourceHints,
                      onChanged: (val) {
                        setState(() {
                          _showSourceHints = val;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(_showSourceHints ? 'Hard' : 'Easy'),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _showSourceHints ? 'Hints (Source Language):' : 'Target Words:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: _showSourceHints
                      ? _selectedEntries.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final word = entry.value;
                          final foundIdx = _foundWords.indexWhere((fw) => fw.word == word.target.trim().toUpperCase());
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(label: Text(word.source)),
                              if (foundIdx != -1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Chip(
                                    label: Text(word.target),
                                    backgroundColor: Colors.greenAccent,
                                  ),
                                ),
                            ],
                          );
                        }).toList()
                      : _selectedEntries.map((e) {
                          final found = _foundWords.any((fw) => fw.word == e.target.trim().toUpperCase());
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(e.target),
                                backgroundColor: found ? Colors.greenAccent : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  e.source,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                ),
                const SizedBox(height: 24),
                Text('Found: ${_foundWords.length} / ${_selectedEntries.length}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                // Show found words in full at the bottom
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