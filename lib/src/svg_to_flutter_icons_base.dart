// Core library entry that wires all parts together.
// This file only declares shared imports, defaults, and part files.
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

// Default values used by the generator when not provided by the user.
const String defaultClassName = 'CustomIcons';
const String defaultFontFamily = 'CustomIcons';
const String defaultOutputPath = 'lib/icons/custom_icons.dart';
