import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vocabulary.dart';

// Color definitions for FlashcardScreen
const Color correctC = Colors.green;
const Color incorrectC = Colors.red;

class FlashcardScreen extends StatefulWidget {
  final Vocabulary vocabulary;
  final int count;
  const FlashcardScreen({
    super.key,
    required this.vocabulary,
    required this.count,
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
  final FocusNode _backButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quizEntries = List<Entry>.from(widget.vocabulary.entries);
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
    _backButtonFocusNode.dispose();
    super.dispose();
  }

  void _requestBackButtonFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _backButtonFocusNode.requestFocus();
    });
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
    final correctAnswer = _quizEntries[_current].target.trim().toLowerCase();
    if (userInput == correctAnswer) {
      setState(() {
        _correct++;
        _feedback = 'Correct!\nThe ${widget.vocabulary.targetLanguage} word is: ${_quizEntries[_current].target}';
        _showingFeedback = true;
      });
      _requestKeyboardFocus();
    } else {
      setState(() {
        _incorrect++;
        _feedback = 'Incorrect.\nYour answer: ${_controller.text.trim()}\nThe correct ${widget.vocabulary.targetLanguage} word is: ${_quizEntries[_current].target}';
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
      _requestBackButtonFocus();
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Quiz complete!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text('Correct:  $_correct', style: const TextStyle(color: correctC, fontSize: 18)),
              Text('Incorrect:  $_incorrect', style: const TextStyle(color: incorrectC, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Total score: ${percent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 24),
              ElevatedButton(
                focusNode: _backButtonFocusNode,
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
            Text('${widget.vocabulary.sourceLanguage}:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            EntrySourceWidget(
              entry: entry,
              style: Theme.of(context).textTheme.headlineMedium,
              textDirection: widget.vocabulary.sourceReadingDirection,
              imageHeight: 200,
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
                        labelText: '${widget.vocabulary.targetLanguage} translation',
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
                      style: TextStyle(fontSize: 20, color: _feedback!.startsWith('Correct!') ? correctC : incorrectC),
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