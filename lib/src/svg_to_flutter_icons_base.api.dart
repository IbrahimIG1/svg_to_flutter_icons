// Public API used by the CLI.
// Responsibilities:
// - Clean SVG fills to allow color control in Flutter.
// - Generate icon classes from IcoMoon JSON.
// - Update pubspec.yaml and resolve merge/new-class conflicts.
// Handles common problems like missing files, font family conflicts, and
// existing class name collisions.
part of 'svg_to_flutter_icons_base.dart';

// Entry point used by the CLI to clean SVG files.
void generateIcons(String inputPath) {
  cleanSvgFolder(inputPath);
}

// Read SVG files from a folder, strip fill attributes, and write cleaned files.
void cleanSvgFolder(String inputPath) {
  final directory = Directory(inputPath);

  if (!directory.existsSync()) {
    _logError('Folder does not exist.');
    return;
  }

  final svgFiles = directory
      .listSync(followLinks: false)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.svg'))
      .toList();

  if (svgFiles.isEmpty) {
    _logWarn('No SVG files found in: $inputPath');
    return;
  }

  final outputDir = Directory('$inputPath/_cleaned');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  for (final file in svgFiles) {
    final content = file.readAsStringSync();
    final cleaned = _stripFillAttributes(content);
    final outputFile = File(
      '${outputDir.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
    );

    outputFile.writeAsStringSync(cleaned);
  }

  _logSuccess('Cleaned ${svgFiles.length} SVG file(s) into: ${outputDir.path}');
  _logInfo('IcoMoon: https://icomoon.io/');
}

// Generate a Dart class from selection.json (IcoMoon).
void generateIconsClass({
  required String jsonPath,
  required String outputPath,
  String className = defaultClassName,
  String fontFamily = defaultFontFamily,
}) {
  final entries = _readIconEntriesFromJson(jsonPath, fontFamily);
  if (entries.isEmpty) {
    _logWarn('No icons found in: $jsonPath');
    return;
  }

  _writeIconClassFile(
    outputPath: outputPath,
    className: className,
    fontFamily: fontFamily,
    entries: entries,
  );
}

// Generate the icon class and update pubspec.yaml using an assets folder.
void generateIconsFromAssets({
  required String assetsPath,
  String? outputPath,
  String className = defaultClassName,
  String fontFamily = defaultFontFamily,
  String? jsonFileName,
  String? pubspecPath,
  String? ttfFileName,
}) {
  final assetsDir = Directory(assetsPath);
  if (!assetsDir.existsSync()) {
    _logError('Assets folder not found: $assetsPath');
    return;
  }

  final selectionJson = _resolveSelectionJson(assetsDir, jsonFileName);
  if (selectionJson == null) {
    return;
  }

  final ttfFile = _resolveTtfFile(assetsDir, ttfFileName);
  if (ttfFile == null) {
    return;
  }

  final pubspecFilePath = pubspecPath ?? 'pubspec.yaml';
  final assetPath = _toPubspecAssetPath(pubspecFilePath, ttfFile.path);
  if (assetPath == null) {
    return;
  }

  final existingFonts = _readFontEntriesFromPubspec(pubspecFilePath);
  final existingFamily = _findFamilyForAsset(existingFonts, assetPath);

  var resolvedFontFamily = fontFamily;
  if (existingFamily != null) {
    resolvedFontFamily = existingFamily;
    _logInfo(
      'Font asset already registered. Using family: $resolvedFontFamily',
    );
  } else {
    resolvedFontFamily = _resolveUniqueFamilyName(existingFonts, fontFamily);
    if (resolvedFontFamily != fontFamily) {
      _logWarn(
        'Font family "$fontFamily" already exists. Using "$resolvedFontFamily".',
      );
    }
  }

  if (existingFamily == null) {
    _updatePubspecFont(
      pubspecPath: pubspecFilePath,
      fontFamily: resolvedFontFamily,
      assetPath: assetPath,
    );
  }

  final outputFilePath = outputPath ?? defaultOutputPath;
  final jsonEntries = _readIconEntriesFromJson(
    selectionJson.path,
    resolvedFontFamily,
  );
  if (jsonEntries.isEmpty) {
    _logWarn('No icons found in: ${selectionJson.path}');
    return;
  }

  final resolution = _resolveClassConflict(
    outputPath: outputFilePath,
    className: className,
  );

  final resolvedClassName = resolution.className;
  final resolvedOutputPath = resolution.outputPath;

  if (resolution.mergeExisting) {
    final existingEntries = _readIconEntriesFromClassFile(
      resolvedOutputPath,
      className,
    );
    final hasUnknownFamily = existingEntries.any(
      (entry) => entry.fontFamily.isEmpty,
    );
    if (hasUnknownFamily) {
      _logWarn(
        'Could not read fontFamily for existing icons. '
        'Creating a new class instead.',
      );
      final fallback = _resolveNewClassOutput(outputFilePath, className);
      _writeIconClassFile(
        outputPath: fallback.outputPath,
        className: fallback.className,
        fontFamily: resolvedFontFamily,
        entries: jsonEntries,
      );
      return;
    }

    final mergedEntries = _mergeIconEntries(existingEntries, jsonEntries);
    _writeIconClassFile(
      outputPath: resolvedOutputPath,
      className: resolvedClassName,
      fontFamily: resolvedFontFamily,
      entries: mergedEntries,
    );
  } else {
    _writeIconClassFile(
      outputPath: resolvedOutputPath,
      className: resolvedClassName,
      fontFamily: resolvedFontFamily,
      entries: jsonEntries,
    );
  }
}
