This directory contains images that can be used in vocabulary entries.

## Usage Examples

### Text Entry (Traditional)
```dart
Entry(
  source: SourceContent.text("cat"),
  target: "قطة"
)
```

### Image Entry (New Feature)
```dart
Entry(
  source: SourceContent.image("assets/images/vocabulary/cat.png"),
  target: "قطة"
)
```

## Supported Formats

- PNG (recommended for transparency)
- JPG (good for photographs)
- WebP (good compression)

## Guidelines

1. Use descriptive filenames
2. Keep file sizes reasonable for mobile performance
3. Use consistent naming conventions
4. Consider organizing by language or topic

## Example Image Entry

To create a vocabulary entry with an image:

1. Place your image in this directory (e.g., `cat.png`)
2. Reference it in your vocabulary:
   ```dart
   Entry(
     source: SourceContent.image("assets/images/vocabulary/cat.png"),
     target: "قطة"
   )
   ```
3. The image will be displayed instead of text in all practice modes 