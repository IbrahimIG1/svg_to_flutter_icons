// Simple data models shared across the generator.
// Keeps the data flow clear between parsing, merging, and writing.
part of 'svg_to_flutter_icons_base.dart';

enum _ClassConflictDecision { merge, newClass }

class _ClassResolution {
  _ClassResolution({
    required this.className,
    required this.outputPath,
    required this.mergeExisting,
  });

  final String className;
  final String outputPath;
  final bool mergeExisting;
}

class _IconEntry {
  _IconEntry(this.name, this.codePoint, this.fontFamily);

  final String name;
  final int codePoint;
  final String fontFamily;
}

class _FontEntry {
  _FontEntry(this.family, this.assets);

  final String family;
  final Set<String> assets;
}
