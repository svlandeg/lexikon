import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/wordsearch_screen.dart';
import 'package:lexikon/vocabulary.dart';

void main() {
  group('WordSearchScreen', () {
    // Use the grid dimension from the widget
    const gridDim = WordSearchScreen.gridDimension;

    // Mock Greek entries
    final greekEntries = [
      Entry(source: 'cat', target: 'ΓΑΤΑ'),
      Entry(source: 'dog', target: 'ΣΚΥΛΟΣ'),
      Entry(source: 'fish', target: 'ΨΑΡΙ'),
      Entry(source: 'bird', target: 'ΠΟΥΛΙ'),
      Entry(source: 'horse', target: 'ΑΛΟΓΟ'),
      Entry(source: 'mouse', target: 'ΠΟΝΤΙΚΙ'),
    ];

    testWidgets('renders 10x10 grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WordSearchScreen(
            entries: greekEntries,
            readingDirection: TextDirection.ltr,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the GridView
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      // Find grid cell containers by their structure
      final cellFinder = find.descendant(
        of: gridFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
            widget is Container &&
            widget.child is Center &&
            (widget.child as Center).child is Text &&
            ((widget.child as Center).child as Text).data != null &&
            ((widget.child as Center).child as Text).data!.length == 1,
        ),
      );
      expect(cellFinder, findsNWidgets(gridDim * gridDim));

      // Assert at least as many chips as entries (could be more due to hints)
      expect(find.byType(Chip), findsWidgets);

      // Assert Restart button is present
      expect(find.text('Restart'), findsOneWidget);

      // Assert switch is present
      expect(find.byType(Switch), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('toggles difficulty correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WordSearchScreen(
            entries: greekEntries,
            readingDirection: TextDirection.ltr,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, the toggle should show 'Hints (Source Language):'
      expect(find.text('Hints (Source Language):'), findsOneWidget);
      expect(find.text('Target Words:'), findsNothing);

      // Only source words should be shown as chips
      for (final entry in greekEntries) {
        expect(find.widgetWithText(Chip, entry.source), findsOneWidget);
        expect(find.widgetWithText(Chip, entry.target), findsNothing);
      }

      // Tap the switch to toggle mode from Difficult to Easy
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Now, the toggle should show 'Target Words:'
      expect(find.text('Target Words:'), findsOneWidget);
      expect(find.text('Hints (Source Language):'), findsNothing);

      // Now, all target words should be shown as chips, with their source words beneath
      for (final entry in greekEntries) {
        expect(find.widgetWithText(Chip, entry.target), findsOneWidget);
        // The source word should be present as a Text widget (not in a chip)
        expect(
          find.descendant(
            of: find.widgetWithText(Chip, entry.target),
            matching: find.text(entry.source),
          ),
          findsNothing, // source is not inside the chip
        );
        expect(find.text(entry.source), findsWidgets); // source is present somewhere below
      }
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('highlights cells on selection (yellow)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WordSearchScreen(
            entries: greekEntries,
            readingDirection: TextDirection.ltr,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the GridView
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      // Helper to get the index for (row, col)
      int cellIndex(int row, int col) => row * gridDim + col;

      // Tap cell (4,2)
      final cellA = find.descendant(
        of: gridFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
            widget is Container &&
            widget.child is Center &&
            (widget.child as Center).child is Text &&
            ((widget.child as Center).child as Text).data != null &&
            ((widget.child as Center).child as Text).data!.length == 1,
        ),
      ).at(cellIndex(4, 2));
      await tester.tap(cellA);
      await tester.pumpAndSettle();

      // Tap cell (4,6)
      final cellB = find.descendant(
        of: gridFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
            widget is Container &&
            widget.child is Center &&
            (widget.child as Center).child is Text &&
            ((widget.child as Center).child as Text).data != null &&
            ((widget.child as Center).child as Text).data!.length == 1,
        ),
      ).at(cellIndex(4, 6));
      await tester.tap(cellB);
      await tester.pumpAndSettle();

      // After two taps, at least the selected cells should be highlighted (yellow)
      int highlightedCount = 0;
      final cellWidgets = tester.widgetList<Container>(find.descendant(
        of: gridFinder,
        matching: find.byType(Container),
      ));
      for (final container in cellWidgets) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration &&
            decoration.color == Colors.yellowAccent) {
          highlightedCount++;
        }
      }
      expect(highlightedCount, 5);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('permanently highlights correct word (green)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WordSearchScreen(
            entries: greekEntries,
            readingDirection: TextDirection.ltr,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      // Helper to get the index for (row, col)
      int cellIndex(int row, int col) => row * gridDim + col;

      // Read the grid into a 2D list of strings
      List<List<String>> gridLetters = List.generate(gridDim, (_) => List.filled(gridDim, ''));
      final cellFinder = find.descendant(
        of: gridFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
            widget is Container &&
            widget.child is Center &&
            (widget.child as Center).child is Text &&
            ((widget.child as Center).child as Text).data != null &&
            ((widget.child as Center).child as Text).data!.length == 1,
        ),
      );
      final cellWidgets = tester.widgetList<Container>(cellFinder).toList();
      for (int row = 0; row < gridDim; row++) {
        for (int col = 0; col < gridDim; col++) {
          final idx = cellIndex(row, col);
          final container = cellWidgets[idx];
          final center = container.child as Center;
          final text = center.child as Text;
          gridLetters[row][col] = text.data!;
        }
      }

      // The word to find
      const word = 'ΠΟΥΛΙ';
      final wordRunes = word.runes.toList();
      final wordLen = wordRunes.length;
      bool found = false;
      int? startRow, startCol, endRow, endCol;
      // Search horizontally
      for (int row = 0; row < gridDim && !found; row++) {
        for (int col = 0; col <= gridDim - wordLen; col++) {
          bool match = true;
          for (int k = 0; k < wordLen; k++) {
            if (gridLetters[row][col + k] != String.fromCharCode(wordRunes[k])) {
              match = false;
              break;
            }
          }
          if (match) {
            startRow = row;
            startCol = col;
            endRow = row;
            endCol = col + wordLen - 1;
            found = true;
            break;
          }
        }
      }
      // Search vertically if not found
      for (int col = 0; col < gridDim && !found; col++) {
        for (int row = 0; row <= gridDim - wordLen; row++) {
          bool match = true;
          for (int k = 0; k < wordLen; k++) {
            if (gridLetters[row + k][col] != String.fromCharCode(wordRunes[k])) {
              match = false;
              break;
            }
          }
          if (match) {
            startRow = row;
            startCol = col;
            endRow = row + wordLen - 1;
            endCol = col;
            found = true;
            break;
          }
        }
      }
      expect(found, isTrue, reason: 'ΠΟΥΛΙ should be present in the grid');

      // Tap the start and end cells to select the word
      await tester.tap(cellFinder.at(cellIndex(startRow!, startCol!)));
      await tester.pumpAndSettle();
      await tester.tap(cellFinder.at(cellIndex(endRow!, endCol!)));
      await tester.pumpAndSettle();

      // Check that all cells in the word are highlighted green
      final updatedCellWidgets = tester.widgetList<Container>(cellFinder).toList();
      // Collect indices for ΠΟΥΛΙ
      List<int> pouliIndices = [];
      for (int k = 0; k < wordLen; k++) {
        // If the word is horizontal, the row is the same for all cells
        int row = (startRow == endRow) ? startRow : startRow + k;
        // If the word is vertical, the column is the same for all cells
        int col = (startCol == endCol) ? startCol : startCol + k;
        final idx = cellIndex(row, col);
        pouliIndices.add(idx);
        final container = updatedCellWidgets[idx];
        final decoration = container.decoration;
        expect(
          decoration is BoxDecoration && decoration.color == Colors.greenAccent,
          isTrue,
          reason: 'Cell ($row, $col) should be highlighted green',
        );
      }

      // 1. Tap the second letter of ΠΟΥΛΙ
      await tester.tap(cellFinder.at(pouliIndices[1]));
      await tester.pumpAndSettle();

      // Check: all ΠΟΥΛΙ cells are green except the second, which is yellow
      final afterTapWidgets = tester.widgetList<Container>(cellFinder).toList();
      for (int k = 0; k < wordLen; k++) {
        final idx = pouliIndices[k];
        final container = afterTapWidgets[idx];
        final decoration = container.decoration;
        if (k == 1) {
          expect(
            decoration is BoxDecoration && decoration.color == Colors.yellowAccent,
            isTrue,
            reason: 'Cell for 2nd letter should be yellow after tap',
          );
        } else {
          expect(
            decoration is BoxDecoration && decoration.color == Colors.greenAccent,
            isTrue,
            reason: 'Other cells should remain green after tapping 2nd letter',
          );
        }
      }

      // 2. Tap a cell not in ΠΟΥΛΙ: (1,1) if startRow==0, else (0,0)
      int tapRow = (startRow == 0) ? 1 : 0;
      int tapCol = (startRow == 0) ? 1 : 0;
      int tapIdx = cellIndex(tapRow, tapCol);
      // Make sure this cell is not part of ΠΟΥΛΙ
      assert(!pouliIndices.contains(tapIdx));
      await tester.tap(cellFinder.at(tapIdx));
      await tester.pumpAndSettle();

      // Check: all ΠΟΥΛΙ cells are green again
      final afterSecondTapWidgets = tester.widgetList<Container>(cellFinder).toList();
      for (final idx in pouliIndices) {
        final container = afterSecondTapWidgets[idx];
        final decoration = container.decoration;
        expect(
          decoration is BoxDecoration && decoration.color == Colors.greenAccent,
          isTrue,
          reason: 'Cell $idx should be green after tapping outside ΠΟΥΛΙ',
        );
      }
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
} 