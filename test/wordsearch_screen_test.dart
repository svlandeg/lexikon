import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/wordsearch_screen.dart';
import 'package:lexikon/vocabulary.dart';

void main() {
  group('WordSearchScreen', () {
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
      expect(cellFinder, findsNWidgets(100));

      // Assert at least as many chips as entries (could be more due to hints)
      expect(find.byType(Chip), findsWidgets);

      // Assert Restart button is present
      expect(find.text('Restart'), findsOneWidget);

      // Assert switch is present
      expect(find.byType(Switch), findsOneWidget);
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
    });
  });
} 