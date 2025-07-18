import 'package:flutter/material.dart';
import 'dart:math';

class ConnectScreen extends StatefulWidget {
  final List<Map<String, String>> wordPairs;
  ConnectScreen({Key? key, required this.wordPairs}) : super(key: key);

  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  static const int batchSize = 5;
  late List<Map<String, String>> allPairs;
  int batchIndex = 0;
  List<String> sourceWords = [];
  List<String> targetWords = [];
  int? selectedSourceIndex;
  int? selectedTargetIndex;
  List<_Connection> connections = [];

  @override
  void initState() {
    super.initState();
    allPairs = List<Map<String, String>>.from(widget.wordPairs);
    allPairs.shuffle();
    _loadBatch();
  }

  void _loadBatch() {
    final start = batchIndex * batchSize;
    final end = (start + batchSize).clamp(0, allPairs.length);
    final batch = allPairs.sublist(start, end);
    sourceWords = batch.map((e) => e['source']!).toList();
    targetWords = batch.map((e) => e['target']!).toList();
    targetWords.shuffle();
    connections = [];
    selectedSourceIndex = null;
    selectedTargetIndex = null;
    setState(() {});
  }

  void onWordTap(bool isSource, int index) {
    // Prevent selecting already connected words
    if (isSource && connections.any((c) => c.sourceIndex == index)) {
      return;
    }
    if (!isSource && connections.any((c) => c.targetIndex == index)) {
      return;
    }

    setState(() {
      if (isSource) {
        selectedSourceIndex = index;
      } else {
        selectedTargetIndex = index;
      }
    });

    // If both are selected and they match, add connection and clear selection
    if (selectedSourceIndex != null && selectedTargetIndex != null) {
      final source = sourceWords[selectedSourceIndex!];
      final target = targetWords[selectedTargetIndex!];
      final match = allPairs.any((pair) => pair['source'] == source && pair['target'] == target);
      if (match) {
        setState(() {
          connections.add(_Connection(
            sourceIndex: selectedSourceIndex!,
            targetIndex: selectedTargetIndex!,
          ));
          selectedSourceIndex = null;
          selectedTargetIndex = null;
        });
        // If all connections for this batch are made, show dialog and wait for user to proceed
        if (connections.length == sourceWords.length) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if ((batchIndex + 1) * batchSize < allPairs.length) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('Solved!'),
                  content: const Text('You solved this batch.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          batchIndex++;
                          _loadBatch();
                        });
                      },
                      child: const Text('Next'),
                    ),
                  ],
                ),
              );
            } else {
              // All done
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('Completed!'),
                  content: const Text('You have finished all word pairs.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LayoutBuilder(
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
                                color: isSelected ? Colors.yellowAccent : isConnected ? Colors.grey[300] : Colors.white,
                                border: Border.all(
                                  color: isSelected ? Colors.yellowAccent : isConnected ? Colors.grey : Colors.blueGrey,
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
                                color: isSelected ? Colors.yellowAccent : isConnected ? Colors.grey[300] : Colors.white,
                                border: Border.all(
                                  color: isSelected ? Colors.yellowAccent : isConnected ? Colors.grey : Colors.blueGrey,
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
        ),
      ),
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
      ..color = Colors.greenAccent
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    double leftX = width * 0.25;
    double rightX = width * 0.75;
    double y1 = (height - n * wordHeight) / 2 + wordHeight * (sourceIndex + 0.5);
    double y2 = (height - n * wordHeight) / 2 + wordHeight * (targetIndex + 0.5);
    const double boxWidth = 120.0; // Approximate width of the word box
    final p1 = Offset(leftX + boxWidth / 2, y1);
    final p2 = Offset(rightX - boxWidth / 2, y2);
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 