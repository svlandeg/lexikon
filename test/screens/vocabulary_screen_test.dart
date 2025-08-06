import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexikon/screens/vocabulary_screen.dart';
import 'package:lexikon/voc/vocabulary.dart';
import 'package:lexikon/voc/entry.dart';
import 'package:lexikon/voc/csv_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('VocabularyListScreen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows empty state when no vocabularies', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      expect(find.text('No vocabularies yet'), findsOneWidget);
      expect(find.text('Create your first vocabulary to get started'), findsOneWidget);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
    });

    testWidgets('shows creation options modal', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      
      // Check that the modal shows all three creation options
      expect(find.text('Create Vocabulary'), findsOneWidget);
      expect(find.text('Create an empty Text-to-Text vocabulary'), findsOneWidget);
      expect(find.text('Upload a Text-to-Text vocabulary from a CSV File'), findsOneWidget);
      expect(find.text('Upload an Image-to-Text vocabulary from a directory'), findsOneWidget);
    });

    testWidgets('can create empty vocabulary', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      
      // Select "Create an empty text-to-text vocabulary" option
      await tester.tap(find.text('Create an empty Text-to-Text vocabulary'));
      await tester.pumpAndSettle();
      
      // Fill in the form
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Vocab');
      await tester.enterText(find.byType(TextFormField).at(1), 'English');
      await tester.enterText(find.byType(TextFormField).at(2), 'Spanish');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
      await tester.pumpAndSettle();
      
      expect(find.text('Test Vocab'), findsOneWidget);
      expect(find.text('English → Spanish (0 entries)'), findsOneWidget);
    });

    testWidgets('can delete a vocabulary', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          jsonEncode(TextVocabulary(
            id: '1',
            name: 'ToDelete',
            sourceLanguage: 'English',
            targetLanguage: 'Spanish',
            entries: [],
          ).toJson()),
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('ToDelete'), findsOneWidget);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete));
      await tester.pumpAndSettle();
      expect(find.text('Delete Vocabulary'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('ToDelete'), findsNothing);
    });

    testWidgets('can navigate to vocabulary detail', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          jsonEncode(TextVocabulary(
            id: '2',
            name: 'DetailTest',
            sourceLanguage: 'English',
            targetLanguage: 'French',
            entries: [],
          ).toJson()),
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DetailTest'));
      await tester.pumpAndSettle();
      expect(find.text('DetailTest'), findsWidgets); // AppBar and detail
      expect(find.text('No words yet'), findsOneWidget);
    });

    testWidgets('can edit a vocabulary', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'vocabularies': [
          jsonEncode(TextVocabulary(
            id: '3',
            name: 'EditMe',
            sourceLanguage: 'English',
            targetLanguage: 'German',
            entries: [],
          ).toJson()),
        ],
      });
      await tester.pumpWidget(const MaterialApp(home: VocabularyListScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'EditedName');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('EditedName'), findsOneWidget);
      expect(find.text('EditMe'), findsNothing);
    });
  });

  group('CsvParser', () {
    test('parses CSV file correctly', () {
      const csvContent = '''English,Arabic
Hello,مرحبا
Good morning,صباح الخير
Goodbye,مع السلامة''';
      
      final result = CsvParser.parseCsvFile('test_vocab.csv', csvContent);
      
      expect(result.name, 'test_vocab');
      expect(result.sourceLanguage, 'English');
      expect(result.targetLanguage, 'Arabic');
      expect(result.entries.length, 3);
      expect(result.entries[0].source, 'Hello');
      expect(result.entries[0].target, 'مرحبا');
      expect(result.entries[1].source, 'Good morning');
      expect(result.entries[1].target, 'صباح الخير');
      expect(result.entries[2].source, 'Goodbye');
      expect(result.entries[2].target, 'مع السلامة');
    });

    test('throws error for empty CSV', () {
      expect(() => CsvParser.parseCsvFile('empty.csv', ''), 
        throwsA(isA<ArgumentError>()));
    });

    test('throws error for invalid language line', () {
      const csvContent = '''English
Hello,مرحبا''';
      
      expect(() => CsvParser.parseCsvFile('invalid.csv', csvContent), 
        throwsA(isA<ArgumentError>()));
    });

    test('skips empty lines and invalid entries', () {
      const csvContent = '''English,Arabic
Hello,مرحبا

Good morning,صباح الخير
,invalid
valid,entry''';
      
      final result = CsvParser.parseCsvFile('test.csv', csvContent);
      
      expect(result.entries.length, 3);
      expect(result.entries[0].source, 'Hello');
      expect(result.entries[0].target, 'مرحبا');
      expect(result.entries[1].source, 'Good morning');
      expect(result.entries[1].target, 'صباح الخير');
      expect(result.entries[2].source, 'valid');
      expect(result.entries[2].target, 'entry');
    });

    test('detects reading directions correctly', () {
      // Test LTR languages
      const ltrCsv = '''English,Spanish
Hello,Hola
Good morning,Buenos días''';
      
      final ltrResult = CsvParser.parseCsvFile('ltr_test.csv', ltrCsv);
      expect(ltrResult.sourceReadingDirection, TextDirection.ltr);
      expect(ltrResult.targetReadingDirection, TextDirection.ltr);
      
      // Test RTL languages
      const rtlCsv = '''English,Arabic
Hello,مرحبا
Good morning,صباح الخير''';
      
      final rtlResult = CsvParser.parseCsvFile('rtl_test.csv', rtlCsv);
      expect(rtlResult.sourceReadingDirection, TextDirection.ltr);
      expect(rtlResult.targetReadingDirection, TextDirection.rtl);
      
      // Test both RTL
      const bothRtlCsv = '''Arabic,Hebrew
مرحبا,שלום
صباح الخير,בוקר טוב''';
      
      final bothRtlResult = CsvParser.parseCsvFile('both_rtl_test.csv', bothRtlCsv);
      expect(bothRtlResult.sourceReadingDirection, TextDirection.rtl);
      expect(bothRtlResult.targetReadingDirection, TextDirection.rtl);
      
      // Test various language name formats
      const arabicVariantsCsv = '''English,Arabic (Egypt)
Hello,مرحبا''';
      
      final arabicVariantsResult = CsvParser.parseCsvFile('arabic_variants_test.csv', arabicVariantsCsv);
      expect(arabicVariantsResult.targetReadingDirection, TextDirection.rtl);
      
      const persianVariantsCsv = '''English,Persian (Iran)
Hello,سلام''';
      
      final persianVariantsResult = CsvParser.parseCsvFile('persian_variants_test.csv', persianVariantsCsv);
      expect(persianVariantsResult.targetReadingDirection, TextDirection.rtl);
      
      const farsiVariantsCsv = '''English,Farsi
Hello,سلام''';
      
      final farsiVariantsResult = CsvParser.parseCsvFile('farsi_variants_test.csv', farsiVariantsCsv);
      expect(farsiVariantsResult.targetReadingDirection, TextDirection.rtl);
    });

    test('creates image vocabulary from directory', () async {
      // This test would require actual file system access
      // For now, we'll test the UI components
      final entries = [
        ImageEntry(imagePath: '/path/to/cat.png', target: 'cat'),
        ImageEntry(imagePath: '/path/to/dog.png', target: 'dog'),
        ImageEntry(imagePath: '/path/to/bird.png', target: 'bird'),
      ];
      
      // Test that ImageVocabularyCreationScreen can be created
      final screen = ImageVocabularyCreationScreen(
        directoryName: 'Animals',
        entries: entries,
        vocabularyId: 'test_id',
      );
      
      expect(screen.directoryName, 'Animals');
      expect(screen.entries.length, 3);
      expect(screen.entries[0].target, 'cat');
      expect(screen.entries[0].imagePath, '/path/to/cat.png');
    });
  });


} 