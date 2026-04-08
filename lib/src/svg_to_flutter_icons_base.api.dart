part of 'svg_to_flutter_icons_base.dart';

/// Compatibility entry point used by the CLI to clean SVG files.
///
/// This delegates to [cleanSvgFolder].
void generateIcons(String inputPath, {bool normalizeStroke = false}) {
  cleanSvgFolder(inputPath, normalizeStroke: normalizeStroke);
}

/// Cleans all `.svg` files inside [inputPath] by removing fixed `fill` values.
///
/// Cleaned files are written to a `_cleaned` folder under [inputPath].
/// This allows Flutter to control icon colors at runtime.
///
/// If [normalizeStroke] is true, fixed `stroke` values are normalized to
/// `currentColor` too, so stroke-based icons follow Flutter color updates.
void cleanSvgFolder(String inputPath, {bool normalizeStroke = false}) {
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
    final cleaned = _normalizeSvgColors(
      content,
      normalizeStroke: normalizeStroke,
    );
    final outputFile = File(
      '${outputDir.path}${Platform.pathSeparator}${file.uri.pathSegments.last}',
    );

    outputFile.writeAsStringSync(cleaned);
  }

  _logSuccess('Cleaned ${svgFiles.length} SVG file(s) into: ${outputDir.path}');
  if (normalizeStroke) {
    _logInfo('Stroke normalization enabled: fixed stroke colors -> currentColor');
  }
  _logInfo('IcoMoon: https://icomoon.io/');
}

/// Generates a Dart `IconData` class from an IcoMoon `selection.json` file.
///
/// The generated file is written to [outputPath], using [className] and
/// [fontFamily] as defaults unless overridden.
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

/// Generates icons from an assets folder that contains JSON and TTF files.
///
/// This workflow resolves JSON/TTF inputs, updates `pubspec.yaml` with
/// the selected font, and writes or merges the generated icon class.
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
