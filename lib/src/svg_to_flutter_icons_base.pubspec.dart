// pubspec.yaml helpers.
// Problem: fonts can be duplicated or stored outside the project.
// Solution: normalize asset paths, detect duplicates, and update safely.
part of 'svg_to_flutter_icons_base.dart';

// Convert a TTF absolute path to a pubspec.yaml asset path.
String? _toPubspecAssetPath(String pubspecPath, String ttfPath) {
  final pubspecFile = File(pubspecPath);
  if (!pubspecFile.existsSync()) {
    _logError('pubspec.yaml not found: $pubspecPath');
    return null;
  }

  final pubspecDir = path.dirname(path.absolute(pubspecPath));
  final ttfAbsolute = path.absolute(ttfPath);
  var relative = path.relative(ttfAbsolute, from: pubspecDir);
  relative = relative.replaceAll('\\', '/');
  relative = path.posix.normalize(relative);

  if (relative.startsWith('..')) {
    _logError('TTF file is outside the project: $relative');
    return null;
  }

  return relative;
}

// Read font entries from pubspec.yaml.
List<_FontEntry> _readFontEntriesFromPubspec(String pubspecPath) {
  final pubspecFile = File(pubspecPath);
  if (!pubspecFile.existsSync()) {
    return [];
  }

  final contents = pubspecFile.readAsStringSync();
  final yaml = loadYaml(contents);
  if (yaml is! YamlMap) {
    return [];
  }

  final flutter = yaml['flutter'];
  if (flutter is! YamlMap) {
    return [];
  }

  final fonts = flutter['fonts'];
  if (fonts is! YamlList) {
    return [];
  }

  final entries = <_FontEntry>[];
  for (final item in fonts) {
    if (item is! YamlMap) {
      continue;
    }
    final family = item['family'];
    if (family is! String || family.trim().isEmpty) {
      continue;
    }
    final fontsList = item['fonts'];
    final assets = <String>{};
    if (fontsList is YamlList) {
      for (final fontItem in fontsList) {
        if (fontItem is YamlMap) {
          final asset = fontItem['asset'];
          if (asset is String && asset.trim().isNotEmpty) {
            assets.add(asset);
          }
        }
      }
    }
    entries.add(_FontEntry(family.trim(), assets));
  }

  return entries;
}

// Find the font family for a given asset path.
String? _findFamilyForAsset(List<_FontEntry> entries, String assetPath) {
  for (final entry in entries) {
    if (entry.assets.contains(assetPath)) {
      return entry.family;
    }
  }
  return null;
}

// Create a unique font family name when a conflict exists.
String _resolveUniqueFamilyName(List<_FontEntry> entries, String baseName) {
  final existingNames = entries.map((entry) => entry.family).toSet();
  if (!existingNames.contains(baseName)) {
    return baseName;
  }

  var index = 1;
  while (true) {
    final candidate = '$baseName$index';
    if (!existingNames.contains(candidate)) {
      return candidate;
    }
    index++;
  }
}

// Update pubspec.yaml and add the font entry if missing.
void _updatePubspecFont({
  required String pubspecPath,
  required String fontFamily,
  required String assetPath,
}) {
  final pubspecFile = File(pubspecPath);
  if (!pubspecFile.existsSync()) {
    _logError('pubspec.yaml not found: $pubspecPath');
    return;
  }

  final contents = pubspecFile.readAsStringSync();
  final editor = YamlEditor(contents);
  final yaml = loadYaml(contents);

  final entry = {
    'family': fontFamily,
    'fonts': [
      {'asset': assetPath},
    ],
  };

  if (yaml is! YamlMap) {
    _logError('pubspec.yaml has an unexpected format.');
    return;
  }

  final flutter = yaml['flutter'];
  if (flutter == null) {
    editor.update(
      ['flutter'],
      {
        'fonts': [entry],
      },
    );
  } else if (flutter is YamlMap) {
    final fonts = flutter['fonts'];
    if (fonts == null) {
      editor.update(['flutter', 'fonts'], [entry]);
    } else if (fonts is YamlList) {
      final exists = fonts.any(
        (item) => _fontEntryMatches(item, fontFamily, assetPath),
      );
      if (exists) {
        _logInfo('Font already exists in pubspec.yaml.');
        return;
      }
      editor.update(['flutter', 'fonts'], [...fonts, entry]);
    } else {
      _logError('flutter.fonts has an unexpected format.');
      return;
    }
  } else {
    _logError('flutter has an unexpected format.');
    return;
  }

  pubspecFile.writeAsStringSync(editor.toString());
  _logSuccess('Updated pubspec.yaml with font family: $fontFamily');
}

// Check if a pubspec font entry already matches this asset.
bool _fontEntryMatches(Object? entry, String fontFamily, String assetPath) {
  if (entry is! Map) {
    return false;
  }

  final fonts = entry['fonts'];
  if (fonts is List) {
    for (final item in fonts) {
      if (item is Map) {
        final asset = item['asset'];
        if (asset is String && asset == assetPath) {
          return true;
        }
      }
    }
  }

  return false;
}
