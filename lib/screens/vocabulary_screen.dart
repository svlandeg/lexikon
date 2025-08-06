import 'package:flutter/material.dart';
import 'package:lexikon/voc/vocabulary.dart';
import 'package:lexikon/voc/entry.dart';
import 'package:lexikon/screens/utils/entry_source_widget.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:image/image.dart' as img;
import 'practice_screen.dart';
import 'package:lexikon/voc/csv_parser.dart';

// Color definitions for VocabularyScreen
const Color iconC = Colors.grey;
const Color textC = Colors.grey;
const Color bgC = Colors.white;


class VocabularyListScreen extends StatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen> {
  final List<Vocabulary> _vocabularies = [];
  Vocabulary? _selectedVocabulary;

  @override
  void initState() {
    super.initState();
    _loadVocabularies();
  }

  Future<void> _loadVocabularies() async {
    final prefs = await SharedPreferences.getInstance();
    final vocabulariesJson = prefs.getStringList('vocabularies') ?? [];
    setState(() {
      _vocabularies.clear();
      for (final jsonString in vocabulariesJson) {
        try {
          final json = jsonDecode(jsonString);
          final vocabulary = vocabularyFromJson(json);
          _vocabularies.add(vocabulary);
        } catch (e) {
          // Log the error and skip corrupted vocabulary data
          print('Error loading vocabulary from JSON: $e');
          print('Corrupted JSON string: $jsonString');
        }
      }
      if (_vocabularies.isNotEmpty) {
        _selectedVocabulary = _vocabularies.first;
      }
    });
    
    // Save the cleaned vocabularies to remove any corrupted data
    _saveVocabularies();
  }

  Future<void> _saveVocabularies() async {
    final prefs = await SharedPreferences.getInstance();
    final vocabulariesJson = _vocabularies.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList('vocabularies', vocabulariesJson);
  }

  void _addVocabulary(Vocabulary vocabulary) {
    setState(() {
      _vocabularies.add(vocabulary);
    });
    _saveVocabularies();
  }

     void _removeVocabulary(int index) {
     final vocabulary = _vocabularies[index];
     
     // Clean up associated image files if it's an image vocabulary
     if (vocabulary is ImageVocabulary) {
       _cleanupVocabularyImages(vocabulary);
     }
     
     setState(() {
       _vocabularies.removeAt(index);
     });
     _saveVocabularies();
   }

       void _cleanupVocabularyImages(ImageVocabulary vocabulary) {
      try {
        // Delete the entire vocabulary directory
        final vocabularyDir = Directory('app_data/vocabularies/${vocabulary.id}');
        if (vocabularyDir.existsSync()) {
          vocabularyDir.deleteSync(recursive: true);
        }
      } catch (e) {
        // Silently handle cleanup errors
      }
    }

     void _updateVocabulary(int index, Vocabulary vocabulary) {
     setState(() {
       _vocabularies[index] = vocabulary;
     });
     _saveVocabularies();
   }

               Future<String?> _copyAndResizeImage(File sourceFile, String targetWord, String extension, String vocabularyId) async {
      try {
        // Create app data directory for images with vocabulary ID subdirectory
        final appDataDir = Directory('app_data/vocabularies/$vocabularyId');
        if (!appDataDir.existsSync()) {
          appDataDir.createSync(recursive: true);
        }

        // Create a unique filename based on target word and timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = '${targetWord}_$timestamp.$extension';
        final destinationFile = File('${appDataDir.path}/$filename');

        // Read and decode the source image
        final bytes = await sourceFile.readAsBytes();
        final image = img.decodeImage(bytes);
        
        if (image == null) {
          return null; // Failed to decode image
        }

        // Resize image to standard size (300x300) while maintaining aspect ratio
        final resizedImage = img.copyResize(
          image,
          width: 300,
          height: 300,
          interpolation: img.Interpolation.linear,
        );

                 // Encode the resized image
         List<int> encodedBytes;
         switch (extension.toLowerCase()) {
           case 'jpg':
           case 'jpeg':
             encodedBytes = img.encodeJpg(resizedImage, quality: 85);
             break;
           case 'png':
             encodedBytes = img.encodePng(resizedImage);
             break;
           case 'webp':
             // WebP not supported by image package, convert to PNG
             encodedBytes = img.encodePng(resizedImage);
             break;
           default:
             // For other formats, use PNG as fallback
             encodedBytes = img.encodePng(resizedImage);
             break;
         }

        // Write the resized image to the destination file
        await destinationFile.writeAsBytes(encodedBytes);

        // Return the relative path for storage in vocabulary
        return 'app_data/vocabularies/$vocabularyId/$filename';
      } catch (e) {
        return null;
      }
    }

  void _showCreateVocabularyOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Vocabulary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.create),
              title: const Text('Create an empty Text-to-Text vocabulary'),
              onTap: () {
                Navigator.pop(context);
                _createEmptyVocabulary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload a Text-to-Text vocabulary from a CSV File'),
              onTap: () {
                Navigator.pop(context);
                _createFromCsvFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Upload an Image-to-Text vocabulary from a directory'),
              onTap: () {
                Navigator.pop(context);
                _createFromDirectory();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createEmptyVocabulary() async {
    final result = await Navigator.push<Vocabulary>(
      context,
      MaterialPageRoute(builder: (context) => const AddVocabularyScreen()),
    );
    if (result != null) {
      _addVocabulary(result);
    }
  }

  void _createFromCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final filename = result.files.single.name;
        
        try {
          final csvData = CsvParser.parseCsvFile(filename, content);
          
          final vocabulary = await Navigator.push<Vocabulary>(
            context,
            MaterialPageRoute(
              builder: (context) => CsvVocabularyCreationScreen(csvData: csvData),
            ),
          );
          
          if (vocabulary != null) {
            _addVocabulary(vocabulary);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error parsing CSV file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createFromDirectory() async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Directory for Image Vocabulary',
      );
      
      if (directoryPath != null) {
        final directory = Directory(directoryPath);
        final directoryName = directory.path.split(Platform.pathSeparator).last;
        
        // Get all image files from the directory
        final imageExtensions = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'];
        final files = directory.listSync().where((file) {
          if (file is File) {
            final extension = file.path.split('.').last.toLowerCase();
            return imageExtensions.contains(extension);
          }
          return false;
        }).toList();
        
        if (files.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No image files found in the selected directory'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
           // Create image entries from files
           final entries = <ImageEntry>[];
           final vocabularyId = DateTime.now().millisecondsSinceEpoch.toString();
           
           for (final file in files) {
             final fileName = file.path.split(Platform.pathSeparator).last;
             final targetWord = fileName.split('.').first; // Remove extension
             
              // Check if the image can be loaded and copy it to app data
              if (file is File && file.existsSync()) {
                try {
                  // Try to create a FileImage and test if it can be loaded
                  final imageProvider = FileImage(file);
                  
                  // Test the image by trying to resolve it
                  final stream = imageProvider.resolve(ImageConfiguration.empty);
                  final completer = Completer<bool>();
                  
                  stream.addListener(ImageStreamListener((info, _) {
                    completer.complete(true);
                  }, onError: (error, stackTrace) {
                    completer.complete(false);
                  }));
                  
                  final isValid = await completer.future;
                  
                  if (isValid) {
                    // Generate a unique filename for the copied image
                    final extension = file.path.split('.').last.toLowerCase();
                    final copiedImagePath = await _copyAndResizeImage(file, targetWord, extension, vocabularyId);
                    
                                         if (copiedImagePath != null) {
                        entries.add(ImageEntry(
                          imagePath: copiedImagePath,
                          target: targetWord,
                        ));
                      } else {
                        continue;
                      }
                    } else {
                      continue;
                    }
                  } catch (e) {
                    // Skip this file if it can't be loaded
                    continue;
                  }
                } else {
                  // Skip if file doesn't exist or is not a file
                }
           }
        
         // Navigate to image vocabulary creation screen
         final vocabulary = await Navigator.push<Vocabulary>(
           context,
           MaterialPageRoute(
             builder: (context) => ImageVocabularyCreationScreen(
               directoryName: directoryName,
               entries: entries,
               vocabularyId: vocabularyId,
             ),
           ),
         );
         
                  if (vocabulary != null) {
            _addVocabulary(vocabulary);
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading directory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LexiKon - Vocabularies')),
      body: _vocabularies.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: iconC),
                  SizedBox(height: 16),
                  Text(
                    'No vocabularies yet',
                    style: TextStyle(fontSize: 18, color: textC),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first vocabulary to get started',
                    style: TextStyle(color: textC),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _vocabularies.length,
              itemBuilder: (context, index) {
                final vocabulary = _vocabularies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(vocabulary.name),
                    subtitle: Text('${vocabulary.inputSource} → ${vocabulary.targetLanguage} (${vocabulary.entries.length} entries)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Vocabulary',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          onPressed: () async {
                            Vocabulary? result;
                            
                            if (vocabulary is TextVocabulary) {
                              // Edit text vocabulary using AddVocabularyScreen
                              result = await Navigator.push<Vocabulary>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddVocabularyScreen(
                                    initialVocabulary: vocabulary,
                                  ),
                                ),
                              );
                            } else if (vocabulary is ImageVocabulary) {
                              // Edit image vocabulary using ImageVocabularyCreationScreen
                              result = await Navigator.push<Vocabulary>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageVocabularyCreationScreen(
                                    directoryName: vocabulary.name,
                                    entries: vocabulary.imageEntries,
                                    vocabularyId: vocabulary.id,
                                    initialVocabulary: vocabulary,
                                  ),
                                ),
                              );
                            }
                            
                            if (result != null) {
                              _updateVocabulary(index, result);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.list),
                          tooltip: 'Edit Entries',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VocabularyDetailScreen(
                                  vocabulary: vocabulary,
                                  onVocabularyUpdated: (updatedVocabulary) {
                                    _updateVocabulary(index, updatedVocabulary);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete Vocabulary',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Vocabulary'),
                                content: Text('Are you sure you want to delete "${vocabulary.name}" and all its ${vocabulary.entries.length} words?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _removeVocabulary(index);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VocabularyDetailScreen(
                            vocabulary: vocabulary,
                            onVocabularyUpdated: (updatedVocabulary) {
                              _updateVocabulary(index, updatedVocabulary);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
             floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
       floatingActionButton: FloatingActionButton.extended(
         onPressed: () {
           _showCreateVocabularyOptions();
         },
         tooltip: 'Create Vocabulary',
         icon: const Icon(Icons.add),
         label: const Text('Create new vocabulary'),
       ),
    );
  }
}

class AddVocabularyScreen extends StatefulWidget {
  final TextVocabulary? initialVocabulary;
  const AddVocabularyScreen({super.key, this.initialVocabulary});

  @override
  State<AddVocabularyScreen> createState() => _AddVocabularyScreenState();
}

class _AddVocabularyScreenState extends State<AddVocabularyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sourceLanguageController;
  late final TextEditingController _targetLanguageController;
  late TextDirection _sourceReadingDirection;
  late TextDirection _targetReadingDirection;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialVocabulary?.name ?? '');
    _sourceLanguageController = TextEditingController(text: widget.initialVocabulary?.sourceLanguage ?? '');
    _targetLanguageController = TextEditingController(text: widget.initialVocabulary?.targetLanguage ?? '');
    _sourceReadingDirection = widget.initialVocabulary?.sourceReadingDirection ?? TextDirection.ltr;
    _targetReadingDirection = widget.initialVocabulary?.targetReadingDirection ?? TextDirection.ltr;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sourceLanguageController.dispose();
    _targetLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialVocabulary != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Vocabulary' : 'Add Vocabulary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Vocabulary Name',
                  hintText: 'e.g., Spanish Basics, French Travel',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a vocabulary name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourceLanguageController,
                decoration: const InputDecoration(
                  labelText: 'Source Language',
                  hintText: 'e.g., English, Spanish',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter source language' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetLanguageController,
                decoration: const InputDecoration(
                  labelText: 'Target Language',
                  hintText: 'e.g., Spanish, French',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter target language' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TextDirection>(
                value: _sourceReadingDirection,
                decoration: const InputDecoration(
                  labelText: 'Source Language Reading Direction',
                ),
                items: TextDirection.values.map((direction) {
                  return DropdownMenuItem<TextDirection>(
                    value: direction,
                    child: Text(direction.displayName),
                  );
                }).toList(),
                onChanged: (TextDirection? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sourceReadingDirection = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TextDirection>(
                value: _targetReadingDirection,
                decoration: const InputDecoration(
                  labelText: 'Target Language Reading Direction',
                ),
                items: TextDirection.values.map((direction) {
                  return DropdownMenuItem<TextDirection>(
                    value: direction,
                    child: Text(direction.displayName),
                  );
                }).toList(),
                onChanged: (TextDirection? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _targetReadingDirection = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final now = DateTime.now();
                    final vocabulary = TextVocabulary(
                      id: widget.initialVocabulary?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      sourceLanguage: _sourceLanguageController.text,
                      targetLanguage: _targetLanguageController.text,
                      sourceReadingDirection: _sourceReadingDirection,
                      targetReadingDirection: _targetReadingDirection,
                      entries: widget.initialVocabulary?.entries.cast<TextEntry>() ?? [],
                    );
                    Navigator.pop(context, vocabulary);
                  }
                },
                child: Text(isEditing ? 'Save' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VocabularyDetailScreen extends StatefulWidget {
  final Vocabulary vocabulary;
  final Function(Vocabulary) onVocabularyUpdated;
  
  const VocabularyDetailScreen({
    super.key,
    required this.vocabulary,
    required this.onVocabularyUpdated,
  });

  @override
  State<VocabularyDetailScreen> createState() => _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState extends State<VocabularyDetailScreen> {
  late Vocabulary _vocabulary;

  @override
  void initState() {
    super.initState();
    _vocabulary = widget.vocabulary;
  }

  void _addEntry(Entry entry) {
    setState(() {
      final newEntries = List<Entry>.from(_vocabulary.entries);   
      newEntries.add(entry);
      _vocabulary.setEntries(newEntries);
    });
    widget.onVocabularyUpdated(_vocabulary);
  }

  void _removeEntry(int index) {
    final entry = _vocabulary.entries[index];
    
    // Clean up image file if it's an image entry
    if (entry is ImageEntry) {
      _cleanupImageFile(entry.imagePath);
    }
    
    setState(() {
      final newEntries = List<Entry>.from(_vocabulary.entries);
      newEntries.removeAt(index);
      _vocabulary.setEntries(newEntries);
    });
    widget.onVocabularyUpdated(_vocabulary);
  }

  void _cleanupImageFile(String imagePath) {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      // Silently handle cleanup errors
    }
  }

  void _editEntry(int index, Entry newEntry) {
    setState(() {
      final newEntries = List<Entry>.from(_vocabulary.entries);
      newEntries[index] = newEntry;
      _vocabulary.setEntries(newEntries);
    });
    widget.onVocabularyUpdated(_vocabulary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vocabulary.name),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: bgC,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_vocabulary.inputSource} → ${_vocabulary.targetLanguage}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_vocabulary.entries.length} words',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textC),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
          Expanded(
            child: _vocabulary.entries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.translate_outlined, size: 64, color: iconC),
                        SizedBox(height: 16),
                        Text(
                          'No words yet',
                          style: TextStyle(fontSize: 18, color: textC),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first word to get started',
                          style: TextStyle(color: textC),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _vocabulary.entries.length,
                    itemBuilder: (context, index) {
                      final entry = _vocabulary.entries[index];
                      return ListTile(
                        title: EntrySourceWidget(
                          entry: entry,
                          style: Theme.of(context).textTheme.titleMedium,
                          vocabulary: _vocabulary,
                          imageSize: ImageSize.small, 
                        ),
                        subtitle: Text(entry.target),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () async {
                                final result = await Navigator.push<Entry>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEntryScreen(
                                      initialEntry: entry,
                                      vocabulary: _vocabulary,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  _editEntry(index, result);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Entry'),
                                    content: const Text('Are you sure you want to delete this entry?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _removeEntry(index);
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
             floatingActionButton: FloatingActionButton(
         heroTag: 'addEntry',
         onPressed: () async {
           final result = await Navigator.push<Entry>(
             context,
             MaterialPageRoute(
               builder: (context) => AddEntryScreen(
                 vocabulary: _vocabulary,
               ),
             ),
           );
           if (result != null) {
             _addEntry(result);
           }
         },
         tooltip: 'Add Word',
         child: const Icon(Icons.add),
       ),
    );
  }
}

class AddEntryScreen extends StatefulWidget {
  final Entry? initialEntry;
  final Vocabulary vocabulary;
  const AddEntryScreen({
    super.key, 
    this.initialEntry, 
    required this.vocabulary,
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sourceController;
  late final TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController(text: widget.initialEntry is TextEntry 
      ? (widget.initialEntry as TextEntry).source 
      : widget.initialEntry is ImageEntry 
        ? (widget.initialEntry as ImageEntry).imagePath 
        : '');
    _targetController = TextEditingController(text: widget.initialEntry?.target ?? '');
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEntry != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Entry' : 'Add Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.vocabulary is TextVocabulary) ...[
                TextFormField(
                  controller: _sourceController,
                  decoration: InputDecoration(
                    labelText: 'Source Language ( ${(widget.vocabulary as TextVocabulary).sourceLanguage})',
                    hintText: 'Enter a word from the source language',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter a source language entry' : null,
                ),
              ] else ...[
                TextFormField(
                  controller: _sourceController,
                  decoration: InputDecoration(
                    labelText: 'Image Path',
                    hintText: 'Enter the path to the image (e.g., assets/images/cat.png)',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter an image path' : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target Language ( ${widget.vocabulary.targetLanguage})',
                  hintText: 'Enter a word from the target language',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a target language entry' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Entry entry;
                    if (widget.vocabulary is TextVocabulary) {
                      entry = TextEntry(
                        source: _sourceController.text,
                        target: _targetController.text,
                      );
                    } else {
                      entry = ImageEntry(
                        imagePath: _sourceController.text,
                        target: _targetController.text,
                      );
                    }
                    Navigator.pop(context, entry);
                  }
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension TextDirectionDisplayName on TextDirection {
  String get displayName => this == TextDirection.ltr ? 'Left to Right' : 'Right to Left';
}

class CsvVocabularyCreationScreen extends StatefulWidget {
  final CsvVocabularyData csvData;
  
  const CsvVocabularyCreationScreen({
    super.key,
    required this.csvData,
  });

  @override
  State<CsvVocabularyCreationScreen> createState() => _CsvVocabularyCreationScreenState();
}

class _CsvVocabularyCreationScreenState extends State<CsvVocabularyCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sourceLanguageController;
  late final TextEditingController _targetLanguageController;
  late TextDirection _sourceReadingDirection;
  late TextDirection _targetReadingDirection;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.csvData.name);
    _sourceLanguageController = TextEditingController(text: widget.csvData.sourceLanguage);
    _targetLanguageController = TextEditingController(text: widget.csvData.targetLanguage);
    _sourceReadingDirection = widget.csvData.sourceReadingDirection;
    _targetReadingDirection = widget.csvData.targetReadingDirection;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sourceLanguageController.dispose();
    _targetLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Vocabulary from CSV')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                 // Vocabulary details form
                Text(
                  'Vocabulary Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vocabulary Name',
                    hintText: 'e.g., Spanish Basics, French Travel',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter a vocabulary name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sourceLanguageController,
                  decoration: const InputDecoration(
                    labelText: 'Source Language',
                    hintText: 'e.g., English, Spanish',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter source language' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetLanguageController,
                  decoration: const InputDecoration(
                    labelText: 'Target Language',
                    hintText: 'e.g., Spanish, French',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter target language' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TextDirection>(
                  value: _sourceReadingDirection,
                  decoration: const InputDecoration(
                    labelText: 'Source Language Reading Direction',
                  ),
                  items: TextDirection.values.map((direction) {
                    return DropdownMenuItem<TextDirection>(
                      value: direction,
                      child: Text(direction.displayName),
                    );
                  }).toList(),
                  onChanged: (TextDirection? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sourceReadingDirection = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TextDirection>(
                  value: _targetReadingDirection,
                  decoration: const InputDecoration(
                    labelText: 'Target Language Reading Direction',
                  ),
                  items: TextDirection.values.map((direction) {
                    return DropdownMenuItem<TextDirection>(
                      value: direction,
                      child: Text(direction.displayName),
                    );
                  }).toList(),
                  onChanged: (TextDirection? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _targetReadingDirection = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                // Create button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final vocabulary = TextVocabulary(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _nameController.text,
                          sourceLanguage: _sourceLanguageController.text,
                          targetLanguage: _targetLanguageController.text,
                          sourceReadingDirection: _sourceReadingDirection,
                          targetReadingDirection: _targetReadingDirection,
                          entries: widget.csvData.entries,
                        );
                        Navigator.pop(context, vocabulary);
                      }
                    },
                    child: const Text('Create Vocabulary'),
                  ),
                ),
                const SizedBox(height: 16), // Extra padding at bottom for safety
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImageVocabularyCreationScreen extends StatefulWidget {
  final String directoryName;
  final List<ImageEntry> entries;
  final String vocabularyId;
  final ImageVocabulary? initialVocabulary; // Add support for editing existing vocabulary
  
  const ImageVocabularyCreationScreen({
    super.key,
    required this.directoryName,
    required this.entries,
    required this.vocabularyId,
    this.initialVocabulary, // Optional parameter for editing
  });

  @override
  State<ImageVocabularyCreationScreen> createState() => _ImageVocabularyCreationScreenState();
}

class _ImageVocabularyCreationScreenState extends State<ImageVocabularyCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetLanguageController;
  late TextDirection _targetReadingDirection;

  @override
  void initState() {
    super.initState();
    // If editing existing vocabulary, use its properties; otherwise use directory name
    final isEditing = widget.initialVocabulary != null;
    _nameController = TextEditingController(
      text: isEditing ? widget.initialVocabulary!.name : widget.directoryName
    );
    _targetLanguageController = TextEditingController(
      text: isEditing ? widget.initialVocabulary!.targetLanguage : widget.directoryName
    );
    _targetReadingDirection = isEditing 
      ? widget.initialVocabulary!.targetReadingDirection 
      : TextDirection.ltr;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetLanguageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialVocabulary != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Image Vocabulary' : 'Create Image Vocabulary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vocabulary details form
                Text(
                  'Vocabulary Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vocabulary Name',
                    hintText: 'e.g., Animals, Objects, Colors',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter a vocabulary name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetLanguageController,
                  decoration: const InputDecoration(
                    labelText: 'Target Language',
                    hintText: 'e.g., English, Spanish, French',
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter target language' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TextDirection>(
                  value: _targetReadingDirection,
                  decoration: const InputDecoration(
                    labelText: 'Target Language Reading Direction',
                  ),
                  items: TextDirection.values.map((direction) {
                    return DropdownMenuItem<TextDirection>(
                      value: direction,
                      child: Text(direction.displayName),
                    );
                  }).toList(),
                  onChanged: (TextDirection? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _targetReadingDirection = newValue;
                      });
                    }
                  },
                ),
                                 const SizedBox(height: 24),
                
                // Create button
                Center(
                  child: Focus(
                    autofocus: true,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final vocabulary = ImageVocabulary(
                            id: widget.vocabularyId,
                            name: _nameController.text,
                            targetLanguage: _targetLanguageController.text,
                            targetReadingDirection: _targetReadingDirection,
                            entries: widget.entries,
                          );
                          
                          Navigator.pop(context, vocabulary);
                        }
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Create Image Vocabulary'),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Extra padding at bottom for safety
              ],
            ),
          ),
        ),
      ),
    );
  }
}