// Terminal UI helpers.
// Problem: arrow-key menus do not work in all terminals (e.g., VSCode).
// Solution: use interactive mode when supported and fall back to numeric input.
part of 'svg_to_flutter_icons_base.dart';

// Interactive selection using arrow keys and Enter.
File? _pickFileInteractive(List<File> files, String label, String hint) {
  final previousLineMode = stdin.lineMode;
  final previousEchoMode = stdin.echoMode;
  stdin.lineMode = false;
  stdin.echoMode = false;

  try {
    var selectedIndex = 0;
    final lineCount = _renderSelectionMenu(
      files,
      label,
      hint,
      selectedIndex,
      clearLines: false,
    );

    while (true) {
      final key = stdin.readByteSync();
      final direction = _readArrowDirection(key);

      if (direction != 0) {
        selectedIndex = (selectedIndex + direction) % files.length;
        if (selectedIndex < 0) {
          selectedIndex += files.length;
        }
        _redrawSelectionMenu(files, label, hint, selectedIndex, lineCount);
        continue;
      }

      if (_isDigitKey(key)) {
        final digit = key - 48;
        if (digit >= 1 && digit <= files.length) {
          selectedIndex = digit - 1;
          _redrawSelectionMenu(files, label, hint, selectedIndex, lineCount);
        }
        continue;
      }

      if (_isEnterKey(key)) {
        stdout.writeln();
        return files[selectedIndex];
      }
    }
  } finally {
    stdin.lineMode = previousLineMode;
    stdin.echoMode = previousEchoMode;
  }
}

// Render the menu and return the number of lines printed.
int _renderSelectionMenu(
  List<File> files,
  String label,
  String hint,
  int selectedIndex, {
  required bool clearLines,
}) {
  _writeMenuLine(
    'Multiple $label files found. Use arrow keys or 1-9, then Enter.',
    clearLines: clearLines,
  );
  _writeMenuLine(
    'Tip: pass $hint to pick a file directly.',
    clearLines: clearLines,
  );

  for (var i = 0; i < files.length; i++) {
    final prefix = i == selectedIndex ? '> ' : '  ';
    _writeMenuLine('$prefix${files[i].path}', clearLines: clearLines);
  }

  return files.length + 2;
}

// Redraw the menu after moving the cursor up.
void _redrawSelectionMenu(
  List<File> files,
  String label,
  String hint,
  int selectedIndex,
  int lineCount,
) {
  _moveCursorUp(lineCount);
  _renderSelectionMenu(files, label, hint, selectedIndex, clearLines: true);
}

// Write a line and clear existing content if needed.
void _writeMenuLine(String line, {required bool clearLines}) {
  if (clearLines) {
    stdout.write('\r\x1B[2K');
  }
  stdout.writeln(line);
}

// Move the terminal cursor up by N lines.
void _moveCursorUp(int lines) {
  if (lines <= 0) {
    return;
  }
  stdout.write('\x1B[${lines}A');
}

// Check whether a key press is Enter.
bool _isEnterKey(int key) {
  return key == 10 || key == 13;
}

bool _isDigitKey(int key) {
  return key >= 48 && key <= 57;
}

// Use interactive mode only when the terminal supports it.
bool _shouldUseInteractive() {
  if (!stdin.hasTerminal) {
    return false;
  }

  if (!stdout.hasTerminal || !stdout.supportsAnsiEscapes) {
    return false;
  }

  if (_isVsCodeTerminal()) {
    return false;
  }

  return true;
}

bool _isVsCodeTerminal() {
  final env = Platform.environment;
  final termProgram = env['TERM_PROGRAM']?.toLowerCase();
  return env.containsKey('VSCODE_PID') || termProgram == 'vscode';
}

// Read arrow key direction from ANSI or Windows sequences.
int _readArrowDirection(int key) {
  if (key == 224) {
    final next = stdin.readByteSync();
    if (next == 72) {
      return -1;
    }
    if (next == 80) {
      return 1;
    }
    return 0;
  }

  if (key == 27) {
    final second = stdin.readByteSync();
    if (second != 91) {
      return 0;
    }
    final third = stdin.readByteSync();
    if (third == 65) {
      return -1;
    }
    if (third == 66) {
      return 1;
    }
  }

  return 0;
}
