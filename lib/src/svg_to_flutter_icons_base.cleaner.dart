// SVG cleaning helpers.
// Problem: fixed fill colors prevent Flutter from changing icon colors.
// Solution: strip fill and inline fill styles before generating fonts.
part of 'svg_to_flutter_icons_base.dart';

// Strip fill attributes to make icons colorable in Flutter.
String _stripFillAttributes(String svgContent) {
  var output = svgContent.replaceAll(
    RegExp(r'\sfill\s*=\s*"[^"]*"', caseSensitive: false),
    '',
  );
  output = output.replaceAll(
    RegExp(r"\sfill\s*=\s*'[^']*'", caseSensitive: false),
    '',
  );
  output = output.replaceAll(
    RegExp(r'\bfill\s*:\s*[^;"]+;?', caseSensitive: false),
    '',
  );

  return output;
}
