import 'package:flutter/material.dart';
import 'vocabulary.dart';
import 'dart:math';

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

  @override
  void initState() {
    super.initState();
    _quizEntries = List<Entry>.from(widget.vocabulary.entries);
    _quizEntries.shuffle();
    if (_quizEntries.length > widget.count) {
      _quizEntries = _quizEntries.sublist(0, widget.count);
    }
    _setupCurrentWord();
  }

  void _setupCurrentWord() {
    final target = _quizEntries[_current].target.trim();
    _scrambledLetters = target.split('');
    _scrambledLetters.shuffle(Random());
    _userOrder = List<String>.from(_scrambledLetters);
    _isCorrect = false;
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
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${widget.vocabulary.sourceLanguage}:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              entry.source,
              style: Theme.of(context).textTheme.headlineMedium,
              textDirection: widget.vocabulary.sourceReadingDirection,
            ),
            const SizedBox(height: 32),
            Text('${widget.vocabulary.targetLanguage}:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: Directionality(
                textDirection: widget.vocabulary.targetReadingDirection,
                child: ReorderableListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  onReorder: _onReorder,
                  children: [
                    for (int i = 0; i < _userOrder.length; i++)
                      Container(
                        key: ValueKey('letter_$i'),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ReorderableDragStartListener(
                          index: i,
                          child: Chip(
                            label: Text(_userOrder[i], style: const TextStyle(fontSize: 24)),
                            backgroundColor: _isCorrect ? Colors.greenAccent : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isCorrect)
              Column(
                children: [
                  const Text('Correct!', style: TextStyle(color: Colors.green, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(
                    _quizEntries[_current].target,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _nextWord,
                    child: const Text('Next'),
                  ),
                ],
              ),
            Text('Progress: ${_current + 1} / ${_quizEntries.length}'),
          ],
        ),
      ),
    );
  }
} 