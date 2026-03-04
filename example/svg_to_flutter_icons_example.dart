import 'package:svg_to_flutter_icons/svg_to_flutter_icons.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Example usage:');
    print('  dart run example clean assets/icons');
    print('  dart run example generate assets/fonts');
    return;
  }

  final command = args[0];
  final path = args.length > 1 ? args[1] : null;

  if (command == 'clean' && path != null) {
    cleanSvgFolder(path);
    return;
  }

  if (command == 'generate' && path != null) {
    generateIconsFromAssets(assetsPath: path);
    return;
  }

  print('Invalid command.');
  print('Use:');
  print('  dart run example clean <svg-folder>');
  print('  dart run example generate <fonts-folder>');
}
