import 'package:flutter/material.dart';
import 'models.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:math';

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
                      _words.addAll(importedWords);
                    });
                    await _saveWords();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entries added successfully.')));
                  } else if (action == 'overwrite') {
                    setState(() {
                      _words.clear();
                      _words.addAll(importedWords);
                    });
                    await _saveWords();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vocabulary list overwritten successfully.')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid entries found in CSV.')));
                }
              }
            },
            child: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
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
                decoration: const InputDecoration(labelText: 'Source Language'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a source language word' : null,
              ),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(labelText: 'Target Language'),
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

class ExerciseScreen extends StatelessWidget {
  final List<Word> words;
  const ExerciseScreen({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: Center(
        child: Text('Exercise screen coming soon! (${words.length} entries)'),
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
            Text('Source Language:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(word.source, style: Theme.of(context).textTheme.headlineMedium),
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

class PracticeHomeScreen extends StatefulWidget {
  const PracticeHomeScreen({super.key});

  @override
  State<PracticeHomeScreen> createState() => _PracticeHomeScreenState();
}

class _PracticeHomeScreenState extends State<PracticeHomeScreen> {
  List<Word> _words = [];

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final prefs = await SharedPreferences.getInstance();
    final wordsJson = prefs.getStringList('words') ?? [];
    setState(() {
      _words = wordsJson.map((w) => Word.fromJson(jsonDecode(w))).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Flashcards'),
            onTap: () async {
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
          ),
          // Word Search Practice
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: const Text('Word Search'),
            onTap: () {
              if (_words.isEmpty) return;
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
  static const int _numPairs = 3;
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
    // Select 3 random pairs from the vocabulary
    final rand = Random();
    final allWords = List<Word>.from(widget.words);
    allWords.shuffle(rand);
    _selectedWords = allWords.take(_numPairs).toList();
    final wordList = _selectedWords.map((w) => w.target.toUpperCase()).toList();
    _gridSize = (wordList.fold<int>(0, (p, w) => w.length > p ? w.length : p)).clamp(6, 12);
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
      // Horizontal
      int row = start[0];
      int minCol = start[1] < end[1] ? start[1] : end[1];
      int maxCol = start[1] > end[1] ? start[1] : end[1];
      for (int c = minCol; c <= maxCol; c++) {
        selected.add(_grid[row][c]);
      }
    } else {
      // Vertical
      int col = start[1];
      int minRow = start[0] < end[0] ? start[0] : end[0];
      int maxRow = start[0] > end[0] ? start[0] : end[0];
      for (int r = minRow; r <= maxRow; r++) {
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
      int row = start[0];
      int minCol = start[1] < end[1] ? start[1] : end[1];
      int maxCol = start[1] > end[1] ? start[1] : end[1];
      for (int c = minCol; c <= maxCol; c++) {
        cells.add(row * _gridSize + c);
      }
    } else if (start[1] == end[1]) {
      int col = start[1];
      int minRow = start[0] < end[0] ? start[0] : end[0];
      int maxRow = start[0] > end[0] ? start[0] : end[0];
      for (int r = minRow; r <= maxRow; r++) {
        cells.add(r * _gridSize + col);
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