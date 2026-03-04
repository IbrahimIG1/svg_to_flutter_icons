# svg_to_flutter_icons (Quick Docs)

Simple guide to use the package fast.

## 1) Clean SVGs

```bash
dart run svg_to_flutter_icons --input=assets/icons
```

Output:
```
assets/icons/_cleaned
```

## 2) Generate the font (IcoMoon)

Open:
https://icomoon.io/app/#/select

Steps:
1) Import all SVGs from `_cleaned`
2) Generate Font
3) Download

You need:
- `selection.json`
- the `.ttf` file

Place them (example):
```
assets/fonts/selection.json
assets/fonts/custom_icons.ttf
```

## 3) Generate Dart class + update pubspec

```bash
dart run svg_to_flutter_icons --assets=assets/fonts
```

Then:
```bash
flutter pub get
```

## 4) Use in Flutter

```dart
import 'package:your_app/icons/custom_icons.dart';

Icon(CustomIcons.home, color: Colors.blue);
```

## Useful options

Pick specific files:
```bash
dart run svg_to_flutter_icons --assets=assets/fonts --json=selection.json --ttf=custom_icons.ttf
```

Generate class only (no pubspec update):
```bash
dart run svg_to_flutter_icons --json=assets/fonts/selection.json --output=lib/icons/custom_icons.dart
```

Custom class/family names:
```bash
dart run svg_to_flutter_icons --assets=assets/fonts --class=AppIcons --family=AppIcons
```
