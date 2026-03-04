// Asset selection helpers.
// Problem: folders can contain multiple JSON/TTF files.
// Solution: auto-pick when possible or prompt the user to choose.
part of 'svg_to_flutter_icons_base.dart';

// Resolve a .ttf file from the assets folder (or prompt if multiple).
File? _resolveTtfFile(Directory assetsDir, String? ttfFileName) {
  if (ttfFileName != null && ttfFileName.trim().isNotEmpty) {
    final candidate = ttfFileName.trim();
    final file = path.isAbsolute(candidate)
        ? File(candidate)
        : File(path.join(assetsDir.path, candidate));
    if (!file.existsSync()) {
      _logError('TTF file not found: ${file.path}');
      return null;
    }
    return file;
  }

  final ttfFiles = assetsDir
      .listSync(followLinks: false)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.ttf'))
      .toList();

  if (ttfFiles.isEmpty) {
    _logError('No .ttf file found in: ${assetsDir.path}');
    return null;
  }

  if (ttfFiles.length == 1) {
    return ttfFiles.first;
  }

  return _pickFileFromList(ttfFiles, 'TTF', '--ttf');
}

// Resolve selection.json (or another IcoMoon JSON file) from a folder.
File? _resolveSelectionJson(Directory assetsDir, String? jsonFileName) {
  if (jsonFileName != null && jsonFileName.trim().isNotEmpty) {
    final candidate = jsonFileName.trim();
    final file = path.isAbsolute(candidate)
        ? File(candidate)
        : File(path.join(assetsDir.path, candidate));
    if (!file.existsSync()) {
      _logError('JSON file not found: ${file.path}');
      return null;
    }
    if (!_looksLikeIcoMoonJson(file)) {
      _logError('JSON file does not look like IcoMoon: ${file.path}');
      return null;
    }
    return file;
  }

  final jsonFiles = assetsDir
      .listSync(followLinks: false)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.json'))
      .toList();

  if (jsonFiles.isEmpty) {
    _logError('No .json file found in: ${assetsDir.path}');
    return null;
  }

  final candidates = jsonFiles.where(_looksLikeIcoMoonJson).toList();
  final list = candidates.isNotEmpty ? candidates : jsonFiles;

  if (list.length == 1) {
    return list.first;
  }

  return _pickFileFromList(list, 'JSON', '--json');
}

// Quick JSON validation to distinguish IcoMoon files.
bool _looksLikeIcoMoonJson(File file) {
  try {
    final data = json.decode(file.readAsStringSync());
    if (data is Map) {
      return data.containsKey('glyphs') || data.containsKey('icons');
    }
  } catch (_) {
    // Ignore invalid JSON files.
  }
  return false;
}

// Decide how to pick a file from a list based on terminal capabilities.
File? _pickFileFromList(List<File> files, String label, String hint) {
  if (_shouldUseInteractive()) {
    try {
      return _pickFileInteractive(files, label, hint);
    } on StdinException {
      _logWarn('Interactive selection not supported. Falling back to numbers.');
      return _pickFileByNumber(files, label, hint);
    } on IOException {
      _logWarn('Interactive selection not supported. Falling back to numbers.');
      return _pickFileByNumber(files, label, hint);
    }
  }

  return _pickFileByNumber(files, label, hint);
}

// Print file list with a numeric index.
void _printFileList(List<File> files, String label, String hint) {
  _logInfo('Multiple $label files found. Use $hint to pick one:');
  for (var i = 0; i < files.length; i++) {
    print('  [${i + 1}] ${files[i].path}');
  }
}

// Fallback selection method using numeric input.
File? _pickFileByNumber(List<File> files, String label, String hint) {
  _printFileList(files, label, hint);
  stderr.write('Enter $label file number (1-${files.length}): ');
  final input = stdin.readLineSync();
  if (input == null || input.trim().isEmpty) {
    _logWarn('No input detected. Use $hint to pass the file name directly.');
    return null;
  }
  final index = int.tryParse(input.trim());
  if (index == null || index < 1 || index > files.length) {
    _logWarn('Invalid selection.');
    return null;
  }
  return files[index - 1];
}
