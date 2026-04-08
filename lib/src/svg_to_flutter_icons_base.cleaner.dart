// SVG cleaning helpers.
// Problem: fixed fill/stroke colors prevent Flutter from changing icon colors.
// Solution: normalize fill and optional stroke color values before font export.
part of 'svg_to_flutter_icons_base.dart';

// Normalize fill and optional stroke colors to currentColor.
//
// This keeps icons colorable through Flutter's Icon(color: ...).
// Special values like "none" are preserved to avoid breaking outlines.
String _normalizeSvgColors(
  String svgContent, {
  required bool normalizeStroke,
}) {
  var output = _replaceAttrColor(
    svgContent,
    attribute: 'fill',
  );
  output = _replaceStyleColor(
    output,
    property: 'fill',
  );

  if (normalizeStroke) {
    output = _replaceAttrColor(
      output,
      attribute: 'stroke',
    );
    output = _replaceStyleColor(
      output,
      property: 'stroke',
    );
  }

  return output;
}

String _replaceAttrColor(
  String input, {
  required String attribute,
}) {
  final doubleQuoted = RegExp(
    '$attribute\\s*=\\s*"([^"]*)"',
    caseSensitive: false,
  );
  final singleQuoted = RegExp(
    "$attribute\\s*=\\s*'([^']*)'",
    caseSensitive: false,
  );

  var output = input.replaceAllMapped(doubleQuoted, (match) {
    final value = match.group(1) ?? '';
    final normalized = _normalizeColorValue(value);
    return '$attribute="$normalized"';
  });

  output = output.replaceAllMapped(singleQuoted, (match) {
    final value = match.group(1) ?? '';
    final normalized = _normalizeColorValue(value);
    return "$attribute='$normalized'";
  });

  return output;
}

String _replaceStyleColor(
  String input, {
  required String property,
}) {
  final styleRegExp = RegExp(
    '$property\\s*:\\s*([^;"]+)',
    caseSensitive: false,
  );

  return input.replaceAllMapped(styleRegExp, (match) {
    final value = match.group(1) ?? '';
    final normalized = _normalizeColorValue(value);
    return '$property: $normalized';
  });
}

String _normalizeColorValue(String value) {
  final trimmed = value.trim();
  final lower = trimmed.toLowerCase();
  if (lower == 'none') {
    return 'none';
  }
  if (lower == 'currentcolor') {
    return 'currentColor';
  }
  return 'currentColor';
}
