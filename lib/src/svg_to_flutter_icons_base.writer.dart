// Icon class writer and conflict resolution.
// Problem: class files can already exist or contain old icons.
// Solution: prompt to merge or create a new class, then write the output file.
part of 'svg_to_flutter_icons_base.dart';

// Write icon entries into a Dart class file.
void _writeIconClassFile({
  required String outputPath,
  required String className,
  required String fontFamily,
  required List<_IconEntry> entries,
}) {
  final entriesByName = <String, _IconEntry>{};
  final order = <String>[];

  for (final entry in entries) {
    final name = entry.name.trim();
    if (name.isEmpty) {
      continue;
    }
    if (!entriesByName.containsKey(name)) {
      order.add(name);
    }
    entriesByName[name] = entry;
  }

  final buffer = StringBuffer();
  buffer.writeln("import 'package:flutter/widgets.dart';");
  buffer.writeln('');
  buffer.writeln('class $className {');
  buffer.writeln('  $className._();');

  for (final name in order) {
    final entry = entriesByName[name]!;
    final hex = entry.codePoint.toRadixString(16);
    final family = entry.fontFamily.isNotEmpty ? entry.fontFamily : fontFamily;
    buffer.writeln(
      "  static const IconData $name = IconData(0x$hex, fontFamily: '$family');",
    );
  }

  buffer.writeln('}');

  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(buffer.toString());

  _logSuccess('Generated icon class: $outputPath');
}

// Decide whether to merge into a class or create a new one.
_ClassResolution _resolveClassConflict({
  required String outputPath,
  required String className,
}) {
  final outputFile = File(outputPath);
  if (!outputFile.existsSync()) {
    return _ClassResolution(
      className: className,
      outputPath: outputPath,
      mergeExisting: false,
    );
  }

  final content = outputFile.readAsStringSync();
  final classRegex = RegExp(r'\bclass\s+' + RegExp.escape(className) + r'\b');
  if (!classRegex.hasMatch(content)) {
    return _ClassResolution(
      className: className,
      outputPath: outputPath,
      mergeExisting: false,
    );
  }

  final decision = _promptClassConflict(className);
  if (decision == _ClassConflictDecision.merge) {
    return _ClassResolution(
      className: className,
      outputPath: outputPath,
      mergeExisting: true,
    );
  }

  final resolved = _resolveNewClassOutput(outputPath, className);
  return _ClassResolution(
    className: resolved.className,
    outputPath: resolved.outputPath,
    mergeExisting: false,
  );
}

// Prompt the user to merge or create a new class.
_ClassConflictDecision _promptClassConflict(String className) {
  stderr.writeln('Class "$className" already exists.');
  stderr.writeln('  [1] Add new icons to the same class');
  stderr.writeln('  [2] Create a new class with a numeric suffix');
  stderr.write('Choose (1/2): ');
  final input = stdin.readLineSync();
  if (input == '1') {
    return _ClassConflictDecision.merge;
  }
  if (input == '2') {
    return _ClassConflictDecision.newClass;
  }
  _logWarn('Invalid selection. Using option 2.');
  return _ClassConflictDecision.newClass;
}

// Find a new file path and class name with an incremental suffix.
_ClassResolution _resolveNewClassOutput(String outputPath, String baseName) {
  var index = 1;
  while (true) {
    final className = '$baseName$index';
    final candidatePath = _appendSuffixToPath(outputPath, '_$index');
    if (!File(candidatePath).existsSync()) {
      return _ClassResolution(
        className: className,
        outputPath: candidatePath,
        mergeExisting: false,
      );
    }
    index++;
  }
}

// Build a new output path by adding a suffix before the extension.
String _appendSuffixToPath(String filePath, String suffix) {
  final dir = path.dirname(filePath);
  final ext = path.extension(filePath);
  final base = path.basenameWithoutExtension(filePath);
  return path.join(dir, '$base$suffix$ext');
}
