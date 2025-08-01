import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/screens/practice/connect_screen.dart';
import 'package:lexikon/vocabulary.dart';

void main() {
  group('ConnectScreen', () {
    final entries = [
      TextEntry(source: 'cat', target: 'chat'),
      TextEntry(source: 'dog', target: 'chien'),
      TextEntry(source: 'fish', target: 'poisson'),
    ];

    testWidgets('renders source and target words', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectScreen(entries: entries),
        ),
      );
      await tester.pumpAndSettle();

      // Should show all source words
      for (final entry in entries) {
        expect(find.text(entry.source), findsOneWidget);
      }
      // Should show all target words (order may be shuffled)
      for (final entry in entries) {
        expect(find.text(entry.target), findsOneWidget);
      }
      // Should show progress bar and progress text
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
    });

    testWidgets('can make a valid connection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectScreen(entries: entries),
        ),
      );
      await tester.pumpAndSettle();

      // Find the first source word and its correct target
      final firstEntry = entries[0];
      final sourceFinder = find.text(firstEntry.source);
      final targetFinder = find.text(firstEntry.target);

      // Before tapping, the source and target should be enabled (not greyed out)
      final sourceBoxPreTap = tester.widget<Container>(find.ancestor(of: sourceFinder, matching: find.byType(Container)).first);
      final targetBoxPreTap = tester.widget<Container>(find.ancestor(of: targetFinder, matching: find.byType(Container)).first);
      final BoxDecoration? sourceDecorationPreTap = sourceBoxPreTap.decoration as BoxDecoration?;
      final BoxDecoration? targetDecorationPreTap = targetBoxPreTap.decoration as BoxDecoration?;
      expect(sourceDecorationPreTap?.color, equals(boxC));
      expect(targetDecorationPreTap?.color, equals(boxC));

      // Tap the source word
      await tester.tap(sourceFinder);
      await tester.pumpAndSettle();
      // Tap the correct target word
      await tester.tap(targetFinder);
      await tester.pumpAndSettle();

      // After connecting, the source and target should be disabled (greyed out)
      final sourceBoxPostTap = tester.widget<Container>(find.ancestor(of: sourceFinder, matching: find.byType(Container)).first);
      final targetBoxPostTap = tester.widget<Container>(find.ancestor(of: targetFinder, matching: find.byType(Container)).first);
      final BoxDecoration? sourceDecorationPostTap = sourceBoxPostTap.decoration as BoxDecoration?;
      final BoxDecoration? targetDecorationPostTap = targetBoxPostTap.decoration as BoxDecoration?;
      expect(sourceDecorationPostTap?.color, equals(boxConnectedC));
      expect(targetDecorationPostTap?.color, equals(boxConnectedC));

      // Progress should update to 1/3
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('0/3'), findsNothing);
    });
  });
} 