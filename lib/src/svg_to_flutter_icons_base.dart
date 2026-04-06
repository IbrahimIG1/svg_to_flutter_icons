/// Core library for `svg_to_flutter_icons`.
///
/// Exposes the public API used by the CLI to:
/// - clean SVG files for color-ready icon fonts,
/// - generate `IconData` classes from IcoMoon JSON,
/// - update `pubspec.yaml` with font entries.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

part 'svg_to_flutter_icons_base.api.dart';
part 'svg_to_flutter_icons_base.cleaner.dart';
part 'svg_to_flutter_icons_base.icons.dart';
part 'svg_to_flutter_icons_base.models.dart';
part 'svg_to_flutter_icons_base.picker.dart';
part 'svg_to_flutter_icons_base.pubspec.dart';
part 'svg_to_flutter_icons_base.terminal.dart';
part 'svg_to_flutter_icons_base.utils.dart';
part 'svg_to_flutter_icons_base.writer.dart';

/// Default Dart class name used for generated icons.
const String defaultClassName = 'CustomIcons';

/// Default font family used for generated icons.
const String defaultFontFamily = 'CustomIcons';

/// Default output path for the generated icon class file.
const String defaultOutputPath = 'lib/icons/custom_icons.dart';
