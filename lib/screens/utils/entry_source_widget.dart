import 'package:flutter/material.dart';
import 'package:lexikon/voc/entry.dart';
import 'package:lexikon/voc/vocabulary.dart';
import 'dart:io';

// enum to determine size of image as large, medium, or small
enum ImageSize { large, medium, small }

// get image width depending on image size
double getImageWidth(ImageSize imageSize) {
  switch (imageSize) {
    case ImageSize.large:
      return 200;
    case ImageSize.medium:
      return 60;
    case ImageSize.small:
      return 20;
  }
}

// get image height depending on image size
double getImageHeight(ImageSize imageSize) {
  switch (imageSize) {
    case ImageSize.large:
      return 200;
    case ImageSize.medium:
      return 30;
    case ImageSize.small:
      return 20;
  }
}

// Widget for displaying entry sources (text or image)
class EntrySourceWidget extends StatelessWidget {
  final Entry entry;
  final Vocabulary vocabulary;
  final TextStyle? style;
  final ImageSize imageSize;
  final BoxFit imageFit = BoxFit.contain;

  const EntrySourceWidget({
    super.key,
    required this.entry,
    required this.vocabulary,
    this.style,
    this.imageSize = ImageSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (entry is TextEntry) {
      final textEntry = entry as TextEntry;
      return build_text_entry(
        textEntry,
        vocabulary as TextVocabulary,
        style ?? const TextStyle(fontSize: 16),
      );
    } else if (entry is ImageEntry) {
      final imageEntry = entry as ImageEntry;
      return build_image_entry(imageEntry, imageSize);
    } else {
      throw ArgumentError('Unknown entry type: ${entry.runtimeType}');
    }
  }

  build_text_entry(
    TextEntry textEntry,
    TextVocabulary vocabulary,
    TextStyle style,
  ) {
    final textDirection = vocabulary.sourceReadingDirection;
    return Text(textEntry.source, style: style, textDirection: textDirection);
  }

  build_image_entry(ImageEntry imageEntry, ImageSize imageSize) {
    final imageWidth = getImageWidth(imageSize);
    final imageHeight = getImageHeight(imageSize);

    // Check if file exists before trying to load it
    if (!File(imageEntry.imagePath).existsSync()) {
      return build_error_entry(imageEntry, imageWidth, imageHeight);
    }

    return Image.file(
      File(imageEntry.imagePath),
      width: imageWidth,
      height: imageHeight,
      fit: imageFit,
    );
  }

  build_error_entry(
    ImageEntry imageEntry,
    double imageWidth,
    double imageHeight,
  ) {
    return Container(
      width: imageWidth,
      height: imageHeight,
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
}
