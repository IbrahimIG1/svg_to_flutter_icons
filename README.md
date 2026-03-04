<h1 align="center">svg_to_flutter_icons</h1>

<p align="center">
A lightweight CLI tool that converts SVG icon folders into Flutter icon fonts.
</p>

<p align="center">
  <a href="https://pub.dev/packages/svg_to_flutter_icons">
    <img src="https://img.shields.io/pub/v/svg_to_flutter_icons.svg" alt="pub version">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="license MIT">
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/platform-flutter-blue.svg" alt="platform flutter">
  </a>
  <a href="https://dart.dev">
    <img src="https://img.shields.io/badge/sdk-dart-blue.svg" alt="dart sdk">
  </a>
</p>

---

Short docs: `docs.md`
Package: https://pub.dev/packages/svg_to_flutter_icons

## Why

- UI designs often include many SVG icons.
- Adding all SVGs as assets increases app size and maintenance.
- Icon fonts are smaller and behave like normal Flutter icons.

## What this tool does

1) Removes fixed `fill` attributes from SVGs (so Flutter controls color).
2) Generates a Dart icon class from IcoMoon `selection.json`.
3) Updates `pubspec.yaml` with the font entry.

## Requirements

- Dart SDK installed.
- IcoMoon web tool (no account required).
- No external tools installed (TTF is created manually in IcoMoon).

## Quick start

### 1) Clean SVGs

```bash
dart run svg_to_flutter_icons --input=assets/icons
```

Creates:

```
assets/icons/_cleaned
```

### 2) Generate the font (manual step)

Go to:
https://icomoon.io/app/#/select

- Import SVGs from `_cleaned`
- Generate Font
- Download the ZIP and extract:
  - `selection.json`
  - the `.ttf` file

Place them in your project, for example:

```
assets/fonts/selection.json
assets/fonts/custom_icons.ttf
```

### 3) Generate Dart class + update pubspec

```bash
dart run svg_to_flutter_icons --assets=assets/fonts
```

This will:
- Generate `lib/icons/custom_icons.dart`
- Add the font entry to `pubspec.yaml`

Then run:

```bash
flutter pub get
```

## Using the icons

```dart
import 'package:your_app/icons/custom_icons.dart';

Icon(CustomIcons.home, color: Colors.red);
```

## CLI options

### Clean SVGs
```bash
dart run svg_to_flutter_icons --input=assets/icons
```

### Generate from assets folder
```bash
dart run svg_to_flutter_icons --assets=assets/fonts
```

### Specify JSON and TTF manually
```bash
dart run svg_to_flutter_icons --assets=assets/fonts --json=selection.json --ttf=custom_icons.ttf
```

### Generate class only (skip pubspec update)
```bash
dart run svg_to_flutter_icons --json=assets/fonts/selection.json --output=lib/icons/custom_icons.dart
```

### Customize class and font family
```bash
dart run svg_to_flutter_icons --assets=assets/fonts --class=AppIcons --family=AppIcons
```

## Merge vs new class

If the class already exists, the CLI will ask:

- Merge: add new icons to the same class
- New class: create `CustomIcons1`, `CustomIcons2`, ...

When merging, each icon keeps its own `fontFamily` so old icons stay correct
even if a new TTF is different.

## Notes

- Icon fonts are single-color. If you need multi-color icons, use SVGs.
- If colors are not changing in Flutter, the SVG still contains fixed `fill`.
  Use the `_cleaned` folder.
- If your terminal does not accept interactive input, pass `--json` and `--ttf`.

## Troubleshooting

- `selection.json not found`: ensure the file is in the folder or pass `--json`.
- `No .ttf file found`: place the `.ttf` next to the JSON or pass `--ttf`.
- `Font already exists`: the tool will reuse or suffix the font family.

## Project structure

Key files and what they do:

- `bin/svg_to_flutter_icons.dart` - CLI entry point and argument parsing.
- `lib/src/svg_to_flutter_icons_base.dart` - Library entry and shared imports/constants.
- `lib/src/svg_to_flutter_icons_base.api.dart` - Public API used by the CLI.
- `lib/src/svg_to_flutter_icons_base.cleaner.dart` - SVG fill removal (color control).
- `lib/src/svg_to_flutter_icons_base.icons.dart` - JSON parsing and class parsing.
- `lib/src/svg_to_flutter_icons_base.writer.dart` - Class writing and merge logic.
- `lib/src/svg_to_flutter_icons_base.pubspec.dart` - pubspec font update helpers.
- `lib/src/svg_to_flutter_icons_base.picker.dart` - JSON/TTF file selection logic.
- `lib/src/svg_to_flutter_icons_base.terminal.dart` - Terminal UI helpers.
- `lib/src/svg_to_flutter_icons_base.utils.dart` - Console logging helpers.
- `lib/src/svg_to_flutter_icons_base.models.dart` - Data models.

## Roadmap

- Full automation (generate TTF without uploading SVGs to IcoMoon).
  - Planned options for full automation:
  - Run on a server to generate TTF from SVGs.
  - Run offline on your PC using Node.js (npx) so no website upload is needed.

## Contributing

Issues and PRs are welcome. Keep changes small and explain the workflow.
