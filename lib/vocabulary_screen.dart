import 'package:flutter/material.dart';
import 'vocabulary.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'practice_screen.dart';

// Color definitions for VocabularyScreen
const Color iconC = Colors.grey;
const Color textC = Colors.grey;
const Color bgC = Colors.white;


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
              _vocabularies.addAll(vocabulariesJson.map((v) => vocabularyFromJson(jsonDecode(v))));
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
      appBar: AppBar(title: const Text('LexiKon - Vocabularies')),
      body: _vocabularies.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: iconC),
                  SizedBox(height: 16),
                  Text(
                    'No vocabularies yet',
                    style: TextStyle(fontSize: 18, color: textC),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first vocabulary to get started',
                    style: TextStyle(color: textC),
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
  late TextDirection _sourceReadingDirection;
  late TextDirection _targetReadingDirection;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialVocabulary?.name ?? '');
    _sourceLanguageController = TextEditingController(text: widget.initialVocabulary?.sourceLanguage ?? '');
    _targetLanguageController = TextEditingController(text: widget.initialVocabulary?.targetLanguage ?? '');
    _sourceReadingDirection = widget.initialVocabulary?.sourceReadingDirection ?? TextDirection.ltr;
    _targetReadingDirection = widget.initialVocabulary?.targetReadingDirection ?? TextDirection.ltr;
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
              DropdownButtonFormField<TextDirection>(
                value: _sourceReadingDirection,
                decoration: const InputDecoration(
                  labelText: 'Source Language Reading Direction',
                ),
                items: TextDirection.values.map((direction) {
                  return DropdownMenuItem<TextDirection>(
                    value: direction,
                    child: Text(direction.displayName),
                  );
                }).toList(),
                onChanged: (TextDirection? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sourceReadingDirection = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TextDirection>(
                value: _targetReadingDirection,
                decoration: const InputDecoration(
                  labelText: 'Target Language Reading Direction',
                ),
                items: TextDirection.values.map((direction) {
                  return DropdownMenuItem<TextDirection>(
                    value: direction,
                    child: Text(direction.displayName),
                  );
                }).toList(),
                onChanged: (TextDirection? newValue) {
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

  void _addEntry(Entry entry) {
    setState(() {
      _vocabulary = _vocabulary.copyWith(
        entries: [..._vocabulary.entries, entry],
      );
    });
    widget.onVocabularyUpdated(_vocabulary);
  }

  void _removeEntry(int index) {
    setState(() {
      final newEntries = List<Entry>.from(_vocabulary.entries);
      newEntries.removeAt(index);
      _vocabulary = _vocabulary.copyWith(entries: newEntries);
    });
    widget.onVocabularyUpdated(_vocabulary);
  }

  void _editEntry(int index, Entry newEntry) {
    setState(() {
      final newEntries = List<Entry>.from(_vocabulary.entries);
      newEntries[index] = newEntry;
      _vocabulary = _vocabulary.copyWith(entries: newEntries);
    });
    widget.onVocabularyUpdated(_vocabulary);
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
            color: bgC,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_vocabulary.sourceLanguage} (${_vocabulary.sourceReadingDirection.name}) → ${_vocabulary.targetLanguage} (${_vocabulary.targetReadingDirection.name})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_vocabulary.entries.length} words',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textC),
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
                        Icon(Icons.translate_outlined, size: 64, color: iconC),
                        SizedBox(height: 16),
                        Text(
                          'No words yet',
                          style: TextStyle(fontSize: 18, color: textC),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first word to get started',
                          style: TextStyle(color: textC),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _vocabulary.entries.length,
                    itemBuilder: (context, index) {
                      final entry = _vocabulary.entries[index];
                      return ListTile(
                        title: EntrySourceWidget(
                          entry: entry,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                                      vocabulary: _vocabulary,
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
                    vocabulary: _vocabulary,
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
                    importedEntries.add(TextEntry(source: row[0], target: row[1]));
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
                    widget.onVocabularyUpdated(_vocabulary);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entries added successfully.')));
                    }
                  } else if (action == 'overwrite') {
                    setState(() {
                      _vocabulary = _vocabulary.copyWith(entries: importedEntries);
                    });
                    widget.onVocabularyUpdated(_vocabulary);
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
  final Vocabulary vocabulary;
  const AddEntryScreen({
    super.key, 
    this.initialEntry, 
    required this.vocabulary,
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
    _sourceController = TextEditingController(text: widget.initialEntry is TextEntry ? (widget.initialEntry as TextEntry).source : '');
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
                  labelText: 'Source Language ( ${widget.vocabulary.sourceLanguage})',
                  hintText: 'Enter a word from the source language',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a source language entry' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target Language ( ${widget.vocabulary.targetLanguage})',
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
                      TextEntry(
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

extension TextDirectionDisplayName on TextDirection {
  String get displayName => this == TextDirection.ltr ? 'Left to Right' : 'Right to Left';
}