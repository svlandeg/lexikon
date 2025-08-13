import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'package:lexikon/voc/vocabulary.dart';
import 'package:lexikon/voc/entry.dart';

// Color definitions for ConnectScreen
const Color boxC = Colors.white;
const Color boxConnectedC = Colors.grey;
const Color boxSelectedC = Colors.amber;
const Color borderConnectedC = Colors.grey;
const Color borderDefaultC = Colors.blueGrey;
const Color lineC = Colors.greenAccent;

class ConnectScreen extends StatefulWidget {
  final List<Entry> entries;
  ConnectScreen({Key? key, required this.entries}) : super(key: key);

  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  static const int batchSize = 5;
  late List<Entry> allEntries;
  int batchIndex = 0;
  List<Entry> sourceEntries = [];
  List<String> targetWords = [];
  int? selectedSourceIndex;
  int? selectedTargetIndex;
  List<_Connection> connections = [];

  @override
  void initState() {
    super.initState();
    allEntries = List<Entry>.from(widget.entries);
    allEntries.shuffle();
    _loadBatch();
  }

  void _loadBatch() {
    final start = batchIndex * batchSize;
    final end = (start + batchSize).clamp(0, allEntries.length);
    final batch = allEntries.sublist(start, end);
    sourceEntries = batch;
    targetWords = batch.map((e) => e.target).toList();
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

    // If both are selected, check if they match
    if (selectedSourceIndex != null && selectedTargetIndex != null) {
      final sourceEntry = sourceEntries[selectedSourceIndex!];
      final target = targetWords[selectedTargetIndex!];
      final match = sourceEntry.target == target;

      if (match) {
        // If they match, add connection and clear selection
        setState(() {
          connections.add(
            _Connection(
              sourceIndex: selectedSourceIndex!,
              targetIndex: selectedTargetIndex!,
            ),
          );
          selectedSourceIndex = null;
          selectedTargetIndex = null;
        });
      } else {
        // If they don't match, clear both selections after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              selectedSourceIndex = null;
              selectedTargetIndex = null;
            });
          }
        });
      }
    }
  }

  void _onNextPressed() {
    if ((batchIndex + 1) * batchSize < allEntries.length) {
      // Move to next batch
      setState(() {
        batchIndex++;
        _loadBatch();
      });
    } else {
      // All done - navigate back to main screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildSourceWidget(Entry entry, bool isSelected, bool isConnected) {
    if (entry is ImageEntry) {
      // For images, remove border and padding to let image fill the space
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        height: 60.0,
        decoration: BoxDecoration(
          color: isSelected
              ? boxSelectedC
              : isConnected
              ? boxConnectedC
              : boxC,
          border: isSelected
              ? Border.all(color: Colors.yellow, width: 2)
              : isConnected
              ? Border.all(color: Colors.grey, width: 2)
              : Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(entry as ImageEntry),
        ),
      );
    } else {
      // For text entries, keep the original border and padding
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12),
        height: 60.0,
        decoration: BoxDecoration(
          color: isSelected
              ? boxSelectedC
              : isConnected
              ? boxConnectedC
              : boxC,
          border: Border.all(
            color: isConnected ? borderConnectedC : borderDefaultC,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          (entry as TextEntry).source,
          style: const TextStyle(fontSize: 18),
        ),
      );
    }
  }

  Widget _buildImageWidget(ImageEntry imageEntry) {
    // Check if the path is a local file path (contains directory separators)
    if (imageEntry.imagePath.contains('/') ||
        imageEntry.imagePath.contains('\\')) {
      // Local file path - use Image.file
      final file = File(imageEntry.imagePath);

      // Check if file exists before trying to load it
      if (!file.existsSync()) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            color: Colors.grey[200],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 4),
                Text(
                  'File not found',
                  style: TextStyle(fontSize: 10, color: Colors.red[700]),
                ),
                Text(
                  imageEntry.imagePath.split('/').last,
                  style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }

      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: ${imageEntry.imagePath}');
          print('Error: $error');
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              color: Colors.grey[200],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 4),
                  Text(
                    'Load failed',
                    style: TextStyle(fontSize: 10, color: Colors.red[700]),
                  ),
                  Text(
                    imageEntry.imagePath.split('/').last,
                    style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Asset path - use Image.asset
      return Image.asset(
        imageEntry.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              color: Colors.grey[200],
            ),
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = allEntries.length;
    int solved = (batchIndex * batchSize) + connections.length;
    int currentBatchStart = batchIndex * batchSize;
    int currentBatchEnd = ((batchIndex + 1) * batchSize).clamp(0, total);
    bool allPairsMatched = connections.length == sourceEntries.length;

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
            int n = sourceEntries.length;
            return Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : solved / total,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$solved/$total',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Connect game area
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          // Source entries
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(sourceEntries.length, (
                                i,
                              ) {
                                bool isSelected = selectedSourceIndex == i;
                                bool isConnected = connections.any(
                                  (c) => c.sourceIndex == i,
                                );
                                return GestureDetector(
                                  onTap: isConnected
                                      ? null
                                      : () => onWordTap(true, i),
                                  child: _buildSourceWidget(
                                    sourceEntries[i],
                                    isSelected,
                                    isConnected,
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
                                bool isConnected = connections.any(
                                  (c) => c.targetIndex == i,
                                );
                                return GestureDetector(
                                  onTap: isConnected
                                      ? null
                                      : () => onWordTap(false, i),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: verticalPadding,
                                    ),
                                    padding: EdgeInsets.all(12),
                                    height: wordHeight,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? boxSelectedC
                                          : isConnected
                                          ? boxConnectedC
                                          : boxC,
                                      border: Border.all(
                                        color: isConnected
                                            ? borderConnectedC
                                            : borderDefaultC,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      targetWords[i],
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      // Draw all connection lines
                      ...connections.map(
                        (conn) => IgnorePointer(
                          ignoring: true,
                          child: CustomPaint(
                            size: Size(width, height),
                            painter: _ConnectionLinePainter(
                              sourceIndex: conn.sourceIndex,
                              targetIndex: conn.targetIndex,
                              n: n,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Next button
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: allPairsMatched ? _onNextPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allPairsMatched
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        (batchIndex + 1) * batchSize < allEntries.length
                            ? 'Next'
                            : 'Finish',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
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

  _ConnectionLinePainter({
    required this.sourceIndex,
    required this.targetIndex,
    required this.n,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineC
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Use the actual size of the CustomPaint widget
    double actualWidth = size.width;
    double actualHeight = size.height;

    // Calculate the actual layout positions
    // The layout has two Expanded columns, so each takes half the width
    double columnWidth = actualWidth / 2;

    // Source boxes are in the left column, target boxes in the right column
    // Both columns use MainAxisAlignment.center, so boxes are centered vertically
    double leftX = columnWidth / 2; // Center of left column
    double rightX = columnWidth + columnWidth / 2; // Center of right column

    // Calculate vertical positions
    // Each box has height + 2 * margin (8.0 vertical margin on each side)
    double boxHeight = 60.0;
    double margin = 8.0;
    double totalBoxHeight = boxHeight + 2 * margin;

    // The Column with MainAxisAlignment.center centers the content
    double totalContentHeight = n * totalBoxHeight;
    double startY = (actualHeight - totalContentHeight) / 2;

    // Calculate the center of each box
    // Each box starts at startY + margin + (index * totalBoxHeight)
    double y1 =
        startY + margin + (totalBoxHeight * sourceIndex) + boxHeight / 2;
    double y2 =
        startY + margin + (totalBoxHeight * targetIndex) + boxHeight / 2;

    // Connect to the edges of the boxes, not the centers
    const double boxWidth = 120.0; // Approximate width of the word box
    final p1 = Offset(leftX + boxWidth / 2, y1);
    final p2 = Offset(rightX - boxWidth / 2, y2);
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
