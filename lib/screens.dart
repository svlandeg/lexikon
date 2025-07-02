import 'package:flutter/material.dart';
import 'models.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Word> _words = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final prefs = await SharedPreferences.getInstance();
    final wordsJson = prefs.getStringList('words') ?? [];
    setState(() {
      _words.clear();
      _words.addAll(wordsJson.map((w) => Word.fromJson(jsonDecode(w))));
    });
  }

  Future<void> _saveWords() async {
    final prefs = await SharedPreferences.getInstance();
    final wordsJson = _words.map((w) => jsonEncode(w.toJson())).toList();
    await prefs.setStringList('words', wordsJson);
  }

  void _addWord(Word word) {
    setState(() {
      _words.add(word);
    });
    _saveWords();
  }

  void _removeWord(int index) {
    setState(() {
      _words.removeAt(index);
    });
    _saveWords();
  }

  void _editWord(int index, Word newWord) {
    setState(() {
      _words[index] = newWord;
    });
    _saveWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lexikon - Words')),
      body: ListView.builder(
        itemCount: _words.length,
        itemBuilder: (context, index) {
          final word = _words[index];
          return ListTile(
            title: Text(word.text),
            subtitle: Text(word.translation),
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
                        title: const Text('Delete Word'),
                        content: const Text('Are you sure you want to delete this word?'),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addWord',
            onPressed: () async {
              final result = await Navigator.push<Word>(
                context,
                MaterialPageRoute(builder: (context) => const AddWordScreen()),
              );
              if (result != null) {
                _addWord(result);
              }
            },
            child: const Icon(Icons.add),
            tooltip: 'Add Word',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'exercise',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExerciseScreen(words: _words)),
              );
            },
            child: const Icon(Icons.school),
            tooltip: 'Practice',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'flashcards',
            onPressed: () async {
              if (_words.isEmpty) return;
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
                    builder: (context) => FlashcardScreen(words: _words, count: count),
                  ),
                );
              }
            },
            child: const Icon(Icons.quiz),
            tooltip: 'Flashcards',
          ),
        ],
      ),
    );
  }
}

class AddWordScreen extends StatefulWidget {
  final Word? initialWord;
  const AddWordScreen({super.key, this.initialWord});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _wordController;
  late final TextEditingController _translationController;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.initialWord?.text ?? '');
    _translationController = TextEditingController(text: widget.initialWord?.translation ?? '');
  }

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialWord != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Word' : 'Add Word')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _wordController,
                decoration: const InputDecoration(labelText: 'Word'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a word' : null,
              ),
              TextFormField(
                controller: _translationController,
                decoration: const InputDecoration(labelText: 'Translation'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a translation' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      Word(
                        text: _wordController.text,
                        translation: _translationController.text,
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

class ExerciseScreen extends StatelessWidget {
  final List<Word> words;
  const ExerciseScreen({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Center(
        child: Text('Exercise screen coming soon! (${words.length} words)'),
      ),
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  final List<Word> words;
  final int count;
  const FlashcardScreen({super.key, required this.words, required this.count});

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
    final correctAnswer = _quizWords[_current].translation.trim().toLowerCase();
    if (userInput == correctAnswer) {
      setState(() {
        _correct++;
        _feedback = 'Correct! The translation is: ${_quizWords[_current].translation}';
        _showingFeedback = true;
      });
      _requestKeyboardFocus();
    } else {
      setState(() {
        _incorrect++;
        _feedback = 'Incorrect. The correct answer is: ${_quizWords[_current].translation}';
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
              Text('Correct: [32m$_correct[0m'),
              Text('Incorrect: [31m$_incorrect[0m'),
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
            Text('Word:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(word.text, style: Theme.of(context).textTheme.headlineMedium),
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
                        labelText: 'Type the translation',
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