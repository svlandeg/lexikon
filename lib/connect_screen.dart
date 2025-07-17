import 'package:flutter/material.dart';
import 'dart:math';

class ConnectScreen extends StatefulWidget {
  final List<Map<String, String>> wordPairs;
  ConnectScreen({Key? key, required this.wordPairs}) : super(key: key);

  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  List<String> sourceWords = [];
  List<String> targetWords = [];
  int? selectedSourceIndex;
  int? selectedTargetIndex;
  List<_Connection> connections = [];
  int? selectedWordCount;
  List<Map<String, String>> selectedPairs = [];

  @override
  void initState() {
    super.initState();
    // No selection yet; wait for user to pick count if enough words
  }

  void startExercise(int count) {
    setState(() {
      selectedWordCount = count;
      selectedPairs = List.from(widget.wordPairs);
      selectedPairs.shuffle();
      selectedPairs = selectedPairs.take(count).toList();
      sourceWords = selectedPairs.map((e) => e['source']!).toList();
      targetWords = selectedPairs.map((e) => e['target']!).toList();
      targetWords.shuffle();
      connections.clear();
      selectedSourceIndex = null;
      selectedTargetIndex = null;
    });
  }

  void startExerciseAll() {
    startExercise(widget.wordPairs.length);
  }

  void onWordTap(bool isSource, int index) {
    // Prevent selecting already connected words
    if (isSource && connections.any((c) => c.sourceIndex == index)) {
      print('Source $index is already connected.');
      return;
    }
    if (!isSource && connections.any((c) => c.targetIndex == index)) {
      print('Target $index is already connected.');
      return;
    }

    setState(() {
      if (isSource) {
        selectedSourceIndex = index;
      } else {
        selectedTargetIndex = index;
      }
    });
    print('Selected: source '
        + (selectedSourceIndex?.toString() ?? '-')
        + ', target '
        + (selectedTargetIndex?.toString() ?? '-')
    );
    print('Connections: ' + connections.map((c) => '(${c.sourceIndex},${c.targetIndex})').join(', '));

    // If both are selected and they match, add connection and clear selection
    if (selectedSourceIndex != null && selectedTargetIndex != null) {
      final source = sourceWords[selectedSourceIndex!];
      final target = targetWords[selectedTargetIndex!];
      final match = selectedPairs.any((pair) => pair['source'] == source && pair['target'] == target);
      if (match) {
        setState(() {
          connections.add(_Connection(
            sourceIndex: selectedSourceIndex!,
            targetIndex: selectedTargetIndex!,
          ));
          print('Added connection: (${selectedSourceIndex!},${selectedTargetIndex!})');
          selectedSourceIndex = null;
          selectedTargetIndex = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pre-exercise selection if enough words
    if (selectedWordCount == null) {
      int maxCount = widget.wordPairs.length;
      List<int> options = [];
      for (int i = 5; i <= maxCount; i += 5) {
        options.add(i);
      }
      bool lessThanFive = maxCount < 5;
      if (lessThanFive) {
        // Go straight to exercise with all words
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selectedWordCount == null) startExerciseAll();
        });
        return const SizedBox.shrink();
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Connect Exercise')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('How many word pairs to practice?'),
              ...options.map((count) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () => startExercise(count),
                      child: Text('$count pairs'),
                    ),
                  )),
            ],
          ),
        ),
      );
    }

    // ... rest of the exercise UI ...
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;
        double wordHeight = 60.0;
        double verticalPadding = 8.0;
        double totalWordHeight = wordHeight + 2 * verticalPadding;
        int n = sourceWords.length;
        return Stack(
          children: [
            Row(
              children: [
                // Source words
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(sourceWords.length, (i) {
                      bool isSelected = selectedSourceIndex == i;
                      bool isConnected = connections.any((c) => c.sourceIndex == i);
                      return GestureDetector(
                        onTap: isConnected ? null : () => onWordTap(true, i),
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: verticalPadding),
                          padding: EdgeInsets.all(12),
                          height: wordHeight,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red : isConnected ? Colors.grey[300] : Colors.white,
                            border: Border.all(
                              color: isSelected ? Colors.red : isConnected ? Colors.grey : Colors.blueGrey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(sourceWords[i], style: TextStyle(fontSize: 18)),
                        ),
                      );
                    }),
                  ),
                ),
                // Target words
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(targetWords.length, (i) {
                      bool isSelected = selectedTargetIndex == i;
                      bool isConnected = connections.any((c) => c.targetIndex == i);
                      return GestureDetector(
                        onTap: isConnected ? null : () => onWordTap(false, i),
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: verticalPadding),
                          padding: EdgeInsets.all(12),
                          height: wordHeight,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange : isConnected ? Colors.grey[300] : Colors.white,
                            border: Border.all(
                              color: isSelected ? Colors.orange : isConnected ? Colors.grey : Colors.blueGrey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(targetWords[i], style: TextStyle(fontSize: 18)),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            // Draw all connection lines
            ...connections.map((conn) => IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                size: Size(width, height),
                painter: _ConnectionLinePainter(
                  sourceIndex: conn.sourceIndex,
                  targetIndex: conn.targetIndex,
                  n: n,
                  wordHeight: totalWordHeight,
                  width: width,
                  height: height,
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

class _Connection {
  final int sourceIndex;
  final int targetIndex;
  _Connection({required this.sourceIndex, required this.targetIndex});
}

class _ConnectionLinePainter extends CustomPainter {
  final int sourceIndex;
  final int targetIndex;
  final int n;
  final double wordHeight;
  final double width;
  final double height;

  _ConnectionLinePainter({
    required this.sourceIndex,
    required this.targetIndex,
    required this.n,
    required this.wordHeight,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    double leftX = width * 0.25;
    double rightX = width * 0.75;
    double y1 = (height - n * wordHeight) / 2 + wordHeight * (sourceIndex + 0.5);
    double y2 = (height - n * wordHeight) / 2 + wordHeight * (targetIndex + 0.5);
    final p1 = Offset(leftX, y1);
    final p2 = Offset(rightX, y2);
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 