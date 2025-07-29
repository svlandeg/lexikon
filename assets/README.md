# Assets Directory

This directory contains static assets used by the Flutter application.

## Structure

```
assets/
├── images/          # Image files for vocabulary entries and UI
│   ├── vocabulary/  # Vocabulary-specific images (optional subdirectory)
│   └── ui/         # UI-related images (optional subdirectory)
└── README.md       # This file
```

## Usage

Images in this directory can be referenced in the vocabulary entries using:

```dart
Entry imageEntry = Entry(
  source: SourceContent.image("assets/images/vocabulary/cat.png"),
  target: "قطة"
);
```

## Guidelines

- Use descriptive filenames
- Prefer PNG format for images with transparency
- Use JPG for photographs
- Keep file sizes reasonable for mobile performance
- Consider organizing vocabulary images in subdirectories if you have many
