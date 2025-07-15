import 'package:flutter/material.dart';
import 'dart:math';
import 'vocabulary.dart';
import 'package:unicode_data/unicode_data.dart';

class _PlacementOption {
  final int row;
  final int col;
  final bool isHorizontal;
  final int overlap;
  _PlacementOption(this.row, this.col, this.isHorizontal, this.overlap);
}

class WordSearchScreen extends StatefulWidget {
  final List<Entry> entries;
  final TextDirection readingDirection;
  static const int gridDimension = 10;
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
    // Set grid size from the widget's static const
    _gridSize = WordSearchScreen.gridDimension;
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

  List<List<String>> _generateGrid(int gridSize, List<String> wordList, TextDirection direction, {List<_PlacedWord>? actuallyPlaced}) {
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
      final isRTL = direction == TextDirection.rtl;
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
        // Only add if it's not already present
        if (!alphabet.contains(letter)) {
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
    final isRTL = widget.readingDirection == TextDirection.rtl;
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
    // Keep the yellow highlight until a new selection is started
  }

  List<int> _getSelectedCells() {
    // If only start cell is set, highlight it
    if (_selectStartRow != null && _selectStartCol != null && (_selectEndRow == null || _selectEndCol == null)) {
      return [_selectStartRow! * _gridSize + _selectStartCol!];
    }
    if (_selectStartRow == null || _selectStartCol == null || _selectEndRow == null || _selectEndCol == null) return [];
    final start = [_selectStartRow!, _selectStartCol!];
    final end = [_selectEndRow!, _selectEndCol!];
    final isRTL = widget.readingDirection == TextDirection.rtl;
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
                      materialTapTargetSize: MaterialTapTargetSize.padded,
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
                Text('Found:  ${_foundWords.length} / ${_selectedEntries.length}', style: Theme.of(context).textTheme.titleLarge),
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