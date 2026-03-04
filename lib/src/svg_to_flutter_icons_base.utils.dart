// Console logging helpers.
// Problem: mixed output makes CLI logs hard to read.
// Solution: use consistent prefixes for info/warn/error/success.
part of 'svg_to_flutter_icons_base.dart';

// Simple console helpers for consistent output.
void _logInfo(String message) {
  print('[INFO] $message');
}

void _logWarn(String message) {
  print('[WARN] $message');
}

void _logError(String message) {
  print('[ERR ] $message');
}

void _logSuccess(String message) {
  print('[OK  ] $message');
}
