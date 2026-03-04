# svg_to_flutter_icons

CLI helper that turns SVG icon folders into Flutter icon fonts.
It cleans SVG fills, guides you to generate a TTF in IcoMoon, then generates a
Dart `IconData` class and updates `pubspec.yaml` automatically.

## Why

- Design files often have many SVG icons.
- Using all SVGs as assets can increase app size and maintenance.
- Icon fonts are lighter and behave like normal Flutter `Icon`s.

## What this tool does

1) Clean SVGs by removing `fill` attributes so Flutter can control color.
2) Generate a Dart icon class from IcoMoon `selection.json`.
3) Update `pubspec.yaml` with the font entry.

## Requirements

- Dart SDK installed.
- IcoMoon account not required (web tool).
- No external tools installed (TTF is created manually in IcoMoon).

## Quick start

### 1) Clean SVGs

```bash
dart run svg_to_flutter_icons --input=assets/icons
```

This creates `assets/icons/_cleaned` with fill-free SVGs.

### 2) Generate the font (manual step)

Go to IcoMoon:
https://icomoon.io/app/#/select

- Import all SVGs from `_cleaned`
- Generate Font
- Download and extract:
  - `selection.json`
  - the `.ttf` file

Place both in your project, for example:

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
- Add the font to `pubspec.yaml`

Run:

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

### Specify JSON/TTF explicitly
```bash
dart run svg_to_flutter_icons --assets=assets/fonts --json=selection.json --ttf=custom_icons.ttf
```

### Generate class only (no pubspec update)
```bash
dart run svg_to_flutter_icons --json=assets/fonts/selection.json --output=lib/icons/custom_icons.dart
```

### Customize names
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

## Contributing

Issues and PRs are welcome. Keep changes small and explain the workflow.

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

## How it works (short)

1) Clean SVGs (remove fill) -> `_cleaned` folder.
2) Generate TTF + selection.json in IcoMoon.
3) Generate Dart icon class + update `pubspec.yaml`.
