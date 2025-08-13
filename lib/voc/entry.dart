// Base abstract class for all entries
abstract class Entry {
  final String target;

  const Entry({required this.target});

  Map<String, dynamic> toJson();
}

// Text entry with both source and target as text
class TextEntry extends Entry {
  final String source;

  const TextEntry({required this.source, required super.target});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'text',
    'source': source,
    'target': target,
  };

  factory TextEntry.fromJson(Map<String, dynamic> json) {
    if (json['source'] == null) {
      throw ArgumentError('TextEntry JSON is missing required field: source');
    }
    if (json['target'] == null) {
      throw ArgumentError('TextEntry JSON is missing required field: target');
    }
    return TextEntry(
      source: json['source'] as String,
      target: json['target'] as String,
    );
  }
}

// Image entry with image source and text target
class ImageEntry extends Entry {
  final String imagePath;

  const ImageEntry({required this.imagePath, required super.target});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'image',
    'imagePath': imagePath,
    'target': target,
  };

  factory ImageEntry.fromJson(Map<String, dynamic> json) {
    if (json['imagePath'] == null) {
      throw ArgumentError(
        'ImageEntry JSON is missing required field: imagePath',
      );
    }
    if (json['target'] == null) {
      throw ArgumentError('ImageEntry JSON is missing required field: target');
    }
    return ImageEntry(
      imagePath: json['imagePath'] as String,
      target: json['target'] as String,
    );
  }
}

// Factory method for creating entries from JSON
Entry entryFromJson(Map<String, dynamic> json) {
  if (json['type'] == null) {
    throw ArgumentError('Entry JSON is missing required field: type');
  }
  final type = json['type'] as String;
  switch (type) {
    case 'text':
      return TextEntry.fromJson(json);
    case 'image':
      return ImageEntry.fromJson(json);
    default:
      throw ArgumentError('Unknown entry type: $type');
  }
}
