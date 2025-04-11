import 'package:flutter/material.dart';
import 'dart:async';

// Terminal UI interface
class UI with ChangeNotifier {
  final int rows = 25;
  final int cols = 80;

  // Screen buffer
  late List<List<String>> buffer;

  // Terminal controller - would be implemented to connect to a widget
  final List<Completer<String>> _keyCompleters = [];

  UI() {
    buffer = List.generate(rows, (_) => List.filled(cols, ' '));
  }

  // Clear the entire screen
  void clearScreen() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        buffer[i][j] = ' ';
      }
    }
  }

  // Clear from current position to end of line
  void clearToEndOfLine() {
    for (int j = _col; j < cols; j++) {
      buffer[_row][j] = ' ';
    }
  }

  // Move cursor position
  void move(int row, int col) {
    // Store current position for operations
    _row = row;
    _col = col;
  }

  // Read characters from the buffer
  String read(int row, int col, [int? length]) {
    if (length == null) {
      return buffer[row][col];
    } else {
      String result = '';
      for (int i = 0; i < length && col + i < cols; i++) {
        result += buffer[row][col + i];
      }
      return result;
    }
  }

  // Write string to buffer
  void write(String s, {bool inverse = false}) {
    for (int i = 0; i < s.length; i++) {
      if (s[i] == '\b') {
        _col--;
      } else if (s[i] == '\n') {
        _row++;
        _col = 0;
      } else {
        buffer[_row][_col++] = s[i];
      }
    }
  }

  // Refresh the display
  void refresh() {
    notifyListeners();
  }

  // Emit a beep sound
  void beep() {
    // Implementation would depend on platform
    print('BEEP!');
  }

  // Get a character input (async)
  Future<String> getchar() async {
    final completer = Completer<String>();
    _keyCompleters.add(completer);
    return completer.future;
  }

  // Used by widget to input keys
  void injectKey(String key) {
    if (_keyCompleters.isNotEmpty) {
      final completer = _keyCompleters.removeAt(0);
      completer.complete(key);
    } else {
      beep();
    }
  }

  // Track current cursor position
  int _row = 0;
  int _col = 0;
}

// Global UI instance
final UI ui = UI();
