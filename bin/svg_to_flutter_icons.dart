import 'package:args/args.dart';

import 'package:svg_to_flutter_icons/svg_to_flutter_icons.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Path to the folder that contains SVG files',
    );
  parser
    ..addOption(
      'assets',
      abbr: 'a',
      help: 'Path to folder that contains IcoMoon JSON and a .ttf file',
    )
    ..addOption(
      'json',
      abbr: 'j',
      help: 'Path to IcoMoon JSON (or file name inside --assets folder)',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output Dart file path for the generated class',
    )
    ..addOption(
      'pubspec',
      abbr: 'p',
      help: 'Path to pubspec.yaml (defaults to ./pubspec.yaml)',
    )
    ..addOption(
      'ttf',
      abbr: 't',
      help: 'TTF file name inside the assets folder',
    )
    ..addOption(
      'class',
      abbr: 'c',
      defaultsTo: defaultClassName,
      help: 'Dart class name',
    )
    ..addOption(
      'family',
      abbr: 'f',
      defaultsTo: defaultFontFamily,
      help: 'Font family name used in IconData',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

  final results = parser.parse(arguments);

  final inputPath = results['input'];
  final assetsPath = results['assets'];
  final jsonPath = results['json'];
  final outputPath = results['output'];
  final pubspecPath = results['pubspec'];
  final ttfFileName = results['ttf'];
  final className = results['class'];
  final familyName = results['family'];

  if (results['help'] == true ||
      (inputPath == null && jsonPath == null && assetsPath == null)) {
    print('Usage:');
    print('  dart run svg_to_flutter_icons --input=assets/icons');
    print('  dart run svg_to_flutter_icons --assets=assets/fonts');
    print(
      '  dart run svg_to_flutter_icons --json=assets/fonts/selection.json '
      '--output=lib/icons/custom_icons.dart',
    );
    print('');
    print(parser.usage);
    return;
  }

  if (inputPath != null) {
    print('Input folder: $inputPath');
    cleanSvgFolder(inputPath);
  }

  if (assetsPath != null) {
    generateIconsFromAssets(
      assetsPath: assetsPath,
      outputPath: outputPath ?? defaultOutputPath,
      className: className ?? defaultClassName,
      fontFamily: familyName ?? defaultFontFamily,
      jsonFileName: jsonPath,
      pubspecPath: pubspecPath,
      ttfFileName: ttfFileName,
    );
  } else if (jsonPath != null) {
    generateIconsClass(
      jsonPath: jsonPath,
      outputPath: outputPath ?? defaultOutputPath,
      className: className ?? defaultClassName,
      fontFamily: familyName ?? defaultFontFamily,
    );
  }
}
