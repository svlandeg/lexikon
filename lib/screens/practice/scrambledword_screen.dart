import 'package:flutter/material.dart';
import 'package:lexikon/voc/vocabulary.dart';
import 'package:lexikon/voc/entry.dart';
import 'package:lexikon/screens/utils/entry_source_widget.dart';
import 'dart:math';

// Color definitions for ScrambledWordScreen
const Color correctBgC = Colors.greenAccent;
const Color correctTextC = Colors.green;

class ScrambledWordScreen extends StatefulWidget {
  final Vocabulary vocabulary;
  final int count;
  const ScrambledWordScreen({
    super.key,
    required this.vocabulary,
    required this.count,
  });

  @override
  State<ScrambledWordScreen> createState() => _ScrambledWordScreenState();
}

class _ScrambledWordScreenState extends State<ScrambledWordScreen> {
  late List<Entry> _quizEntries;
  int _current = 0;
  late List<String> _scrambledLetters;
  late List<String> _userOrder;
  bool _isCorrect = false;
  bool _showHint = false;
  late ScrollController _scrollController;

  /// Checks if a word can be meaningfully scrambled
  bool _canBeScrambled(String word) {
    if (word.length <= 1) return false;
    if (word.split('').toSet().length == 1) return false; // all identical characters
    return true;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Filter out words that can't be meaningfully scrambled
    _quizEntries = widget.vocabulary.entries
        .where((entry) => _canBeScrambled(entry.target.trim()))
        .toList();
    
    _quizEntries.shuffle();
    if (_quizEntries.length > widget.count) {
      _quizEntries = _quizEntries.sublist(0, widget.count);
    }
    _setupCurrentWord();
  }

  void _setupCurrentWord() {
    final target = _quizEntries[_current].target.trim();
    _scrambledLetters = target.split('');
    
    // Ensure the scrambled result is different from the original
    int attempts = 0;
    const maxAttempts = 100; // Safety limit to prevent infinite loops
    
    do {
      _scrambledLetters.shuffle(Random());
      _userOrder = List<String>.from(_scrambledLetters);
      _checkCorrect();
      attempts++;
    } while (_isCorrect && attempts < maxAttempts);
    
    _isCorrect = false;
    _showHint = false;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final letter = _userOrder.removeAt(oldIndex);
      _userOrder.insert(newIndex, letter);
      _checkCorrect();
    });
  }

  void _checkCorrect() {
    final target = _quizEntries[_current].target.trim();
    if (_userOrder.join() == target) {
      setState(() {
        _isCorrect = true;
      });
    } else {
      setState(() {
        _isCorrect = false;
      });
    }
  }

  void _nextWord() {
    setState(() {
      _current++;
      if (_current < _quizEntries.length) {
        _setupCurrentWord();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle case where no valid words are available
    if (_quizEntries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scrambled Word')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No words available for scrambling'),
              const SizedBox(height: 8),
              const Text(
                'All words in this vocabulary are too short or contain only identical characters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
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
    
    if (_current >= _quizEntries.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scrambled Word')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Exercise complete'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Scrambled Word')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
                         Center(
               child: Column(
                 children: [
                   Text('${widget.vocabulary.inputSource}:', style: Theme.of(context).textTheme.titleLarge),
                   const SizedBox(height: 8),
                   EntrySourceWidget(
                     entry: entry,
                     style: Theme.of(context).textTheme.headlineMedium,
                     vocabulary: widget.vocabulary,
                     imageSize: ImageSize.large,
                   ),
                 ],
               ),
             ),
                         const SizedBox(height: 32),
             Center(
               child: Text('${widget.vocabulary.targetLanguage}:', style: Theme.of(context).textTheme.titleLarge),
             ),
             const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
                             child: Directionality(
                 textDirection: widget.vocabulary.targetReadingDirection,
                                   child: Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                              child: Scrollbar(
                       controller: _scrollController,
                       thumbVisibility: MediaQuery.of(context).size.width > 600,
                       trackVisibility: MediaQuery.of(context).size.width > 600,
                       thickness: 8,
                       radius: const Radius.circular(4),
                       child: SingleChildScrollView(
                         controller: _scrollController,
                         scrollDirection: Axis.horizontal,
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             for (int i = 0; i < _userOrder.length; i++)
                               Container(
                                 key: ValueKey('letter_$i'),
                                 margin: const EdgeInsets.symmetric(horizontal: 8),
                                 child: Draggable<String>(
                                   data: _userOrder[i],
                                   feedback: Material(
                                     child: Chip(
                                       label: Text(_userOrder[i], style: const TextStyle(fontSize: 24)),
                                       backgroundColor: _isCorrect ? correctBgC : null,
                                     ),
                                   ),
                                   childWhenDragging: Material(
                                     child: Chip(
                                       label: Text(_userOrder[i], style: const TextStyle(fontSize: 24)),
                                       backgroundColor: Colors.grey[300],
                                     ),
                                   ),
                                   child: DragTarget<String>(
                                     onWillAccept: (data) => data != null,
                                     onAccept: (data) {
                                       setState(() {
                                         final oldIndex = _userOrder.indexOf(data);
                                         final newIndex = i;
                                         if (oldIndex != -1 && oldIndex != newIndex) {
                                           _userOrder.removeAt(oldIndex);
                                           _userOrder.insert(newIndex, data);
                                           _checkCorrect();
                                         }
                                       });
                                     },
                                     builder: (context, candidateData, rejectedData) {
                                       return Chip(
                                         label: Text(_userOrder[i], style: const TextStyle(fontSize: 24)),
                                         backgroundColor: _isCorrect ? correctBgC : null,
                                       );
                                     },
                                   ),
                                 ),
                               ),
                           ],
                         ),
                       ),
                     ),
                  ),
               ),
                         ),
                           if (!_isCorrect) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Show hint'),
                    const SizedBox(width: 8),
                    Switch(
                      value: _showHint,
                      onChanged: (value) {
                        setState(() {
                          _showHint = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
                           const SizedBox(height: 24),
              if (_isCorrect || _showHint)
               Center(
                 child: Column(
                   children: [
                     if (_isCorrect)
                       const Text('Correct!', style: TextStyle(color: correctTextC, fontSize: 20)),
                     if (_isCorrect) const SizedBox(height: 8),
                     Text(
                       _quizEntries[_current].target,
                       style: TextStyle(
                         fontSize: _isCorrect ? 24 : 18,
                         fontWeight: FontWeight.bold,
                         color: _isCorrect ? null : Colors.blue,
                       ),
                     ),
                     if (_isCorrect) ...[
                       const SizedBox(height: 16),
                       ElevatedButton(
                         onPressed: _nextWord,
                         child: const Text('Next'),
                       ),
                     ],
                   ],
                 ),
               ),
             Center(
               child: Text('Progress: ${_current + 1} / ${_quizEntries.length}'),
             ),
           ],
         ),
       ),
       ),
     );
  }
} 