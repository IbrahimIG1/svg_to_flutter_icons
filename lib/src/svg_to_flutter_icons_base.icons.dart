// Icon parsing helpers.
// Problem: IcoMoon JSON format varies and class files may be edited manually.
// Solution: parse both JSON shapes and read IconData entries with best effort.
part of 'svg_to_flutter_icons_base.dart';

// Parse icon entries from IcoMoon JSON.
List<_IconEntry> _readIconEntriesFromJson(String jsonPath, String fontFamily) {
  final jsonFile = File(jsonPath);
  if (!jsonFile.existsSync()) {
    _logError('selection.json not found: $jsonPath');
    return [];
  }

  final jsonData = json.decode(jsonFile.readAsStringSync());
  final glyphs = jsonData['glyphs'];
  final icons = jsonData['icons'];

  final entries = <_IconEntry>[];

  if (glyphs is List) {
    for (final item in glyphs) {
      final extras = item is Map ? item['extras'] : null;
      final name = extras is Map ? extras['name'] : null;
      final codePoint = extras is Map ? extras['codePoint'] : null;
      final entry = _parseEntry(name, codePoint, fontFamily);
      if (entry != null) {
        entries.add(entry);
      }
    }
  } else if (icons is List) {
    for (final item in icons) {
      final props = item is Map ? item['properties'] : null;
      final name = props is Map ? props['name'] : null;
      final code = props is Map ? props['code'] : null;
      final entry = _parseEntry(name, code, fontFamily);
      if (entry != null) {
        entries.add(entry);
      }
    }
  }

  return entries;
}

// Best-effort parser for manually edited icon classes.
List<_IconEntry> _readIconEntriesFromClassFile(
  String outputPath,
  String className,
) {
  final outputFile = File(outputPath);
  if (!outputFile.existsSync()) {
    return [];
  }

  final content = outputFile.readAsStringSync();
  final classRegex = RegExp(r'\bclass\s+' + RegExp.escape(className) + r'\b');
  if (!classRegex.hasMatch(content)) {
    return [];
  }

  final constants = _extractStringConstants(content);
  final entryRegex = RegExp(
    r'(?:static\s+)?(?:const|final)\s+IconData\s+(\w+)\s*='
    r'\s*IconData\((.*?)\);',
    dotAll: true,
  );

  final entries = <_IconEntry>[];
  for (final match in entryRegex.allMatches(content)) {
    final name = match.group(1);
    final args = match.group(2);
    if (name == null || args == null) {
      continue;
    }

    final code = _parseCodePointFromArgs(args);
    if (code == null) {
      continue;
    }

    var family = _parseFontFamilyFromArgs(args, constants);
    family ??= _resolveDefaultFamily(constants);

    entries.add(_IconEntry(name, code, family ?? ''));
  }

  return entries;
}

// Merge new icons into an existing list, replacing duplicates by name.
List<_IconEntry> _mergeIconEntries(
  List<_IconEntry> existing,
  List<_IconEntry> incoming,
) {
  final entriesByName = <String, _IconEntry>{};
  final order = <String>[];

  for (final entry in existing) {
    if (!entriesByName.containsKey(entry.name)) {
      order.add(entry.name);
    }
    entriesByName[entry.name] = _IconEntry(
      entry.name,
      entry.codePoint,
      entry.fontFamily,
    );
  }

  for (final entry in incoming) {
    if (!entriesByName.containsKey(entry.name)) {
      order.add(entry.name);
    }
    entriesByName[entry.name] = _IconEntry(
      entry.name,
      entry.codePoint,
      entry.fontFamily,
    );
  }

  return order.map((name) => entriesByName[name]!).toList();
}

// Parse a name + code point pair from selection.json.
_IconEntry? _parseEntry(Object? name, Object? codePoint, String fontFamily) {
  if (name == null || codePoint == null) {
    return null;
  }

  final parsedName = name.toString().trim();
  if (parsedName.isEmpty) {
    return null;
  }

  int? parsedCode;
  if (codePoint is int) {
    parsedCode = codePoint;
  } else {
    final value = codePoint.toString().trim();
    if (value.isEmpty) {
      return null;
    }
    parsedCode = int.tryParse(value);
    parsedCode ??= int.tryParse(value, radix: 16);
  }

  if (parsedCode == null) {
    return null;
  }

  final normalizedName = _toLowerCamel(parsedName);
  return _IconEntry(normalizedName, parsedCode, fontFamily);
}

// Convert a raw icon name to lowerCamelCase.
String _toLowerCamel(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'[^a-zA-Z0-9]+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'icon';
  }

  final first = parts.first.toLowerCase();
  final rest = parts
      .skip(1)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join();

  var name = '$first$rest';
  if (RegExp(r'^[0-9]').hasMatch(name)) {
    name = 'icon$name';
  }

  return name;
}

// Extract String constants so IconData can reference shared values.
Map<String, String> _extractStringConstants(String content) {
  final constants = <String, String>{};
  final constRegex = RegExp(
    '(?:static\\s+)?const\\s+String\\s+(\\w+)\\s*=\\s*([\'"])(.*?)\\2',
    dotAll: true,
  );
  for (final match in constRegex.allMatches(content)) {
    final name = match.group(1);
    final value = match.group(3);
    if (name == null || value == null) {
      continue;
    }
    constants[name] = value;
  }
  return constants;
}

// Read the code point from IconData arguments.
int? _parseCodePointFromArgs(String args) {
  final codeMatch = RegExp(r'0x[0-9a-fA-F]+|\d+').firstMatch(args);
  if (codeMatch == null) {
    return null;
  }
  final value = codeMatch.group(0);
  if (value == null) {
    return null;
  }
  if (value.toLowerCase().startsWith('0x')) {
    return int.tryParse(value.substring(2), radix: 16);
  }
  return int.tryParse(value);
}

// Read the font family from IconData arguments.
String? _parseFontFamilyFromArgs(String args, Map<String, String> constants) {
  final match = RegExp(r'fontFamily\s*:\s*([^,\)]+)').firstMatch(args);
  if (match == null) {
    return null;
  }
  final raw = match.group(1)?.trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  final quoted = _stripQuotes(raw);
  if (quoted != null) {
    return quoted;
  }

  final identifier = raw.split('.').last;
  return constants[identifier];
}

// Resolve a default fontFamily constant from a class file.
String? _resolveDefaultFamily(Map<String, String> constants) {
  if (constants.containsKey('fontFamily')) {
    return constants['fontFamily'];
  }
  if (constants.containsKey('_fontFamily')) {
    return constants['_fontFamily'];
  }
  return null;
}

// Strip single/double quotes from a literal.
String? _stripQuotes(String value) {
  if (value.length < 2) {
    return null;
  }
  final first = value[0];
  final last = value[value.length - 1];
  if ((first == "'" && last == "'") || (first == '"' && last == '"')) {
    return value.substring(1, value.length - 1);
  }
  return null;
}
