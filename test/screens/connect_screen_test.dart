import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/connect_screen.dart';

void main() {
  group('ConnectScreen', () {
    final wordPairs = [
      {'source': 'cat', 'target': 'chat'},
      {'source': 'dog', 'target': 'chien'},
      {'source': 'fish', 'target': 'poisson'},
    ];

    testWidgets('renders source and target words', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectScreen(wordPairs: wordPairs),
        ),
      );
      await tester.pumpAndSettle();

      // Should show all source words
      for (final pair in wordPairs) {
        expect(find.text(pair['source']!), findsOneWidget);
      }
      // Should show all target words (order may be shuffled)
      for (final pair in wordPairs) {
        expect(find.text(pair['target']!), findsOneWidget);
      }
      // Should show progress bar and progress text
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);
    });
  });
} 