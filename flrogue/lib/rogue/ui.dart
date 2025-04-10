import 'package:flutter/material.dart';
import 'dart:async';

// Terminal UI interface
class UI with ChangeNotifier {
  final int rows = 25;
  final int cols = 80;

  // Screen buffer
  late List<List<String>> buffer;

  // Terminal controller - would be implemented to connect to a widget
  final StreamController<String> _keyController =
      StreamController<String>.broadcast();
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
    notifyListeners();
  }

  // Clear from current position to end of line
  void clearToEndOfLine() {
    final (row, col) = _getCurrentPosition();

    for (int j = col; j < cols; j++) {
      buffer[row][j] = ' ';
    }
    notifyListeners();
  }

  // Move cursor position
  void move(int row, int col) {
    // Store current position for operations
    _currentRow = row;
    _currentCol = col;
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
    final (row, col) = _getCurrentPosition();

    for (int i = 0; i < s.length && col + i < cols; i++) {
      buffer[row][col + i] = s[i];
    }
    _currentCol += s.length;
    notifyListeners();
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
    }
  }

  // Track current cursor position
  int _currentRow = 0;
  int _currentCol = 0;

  (int, int) _getCurrentPosition() {
    return (_currentRow, _currentCol);
  }

  // Clean up resources
  @override
  void dispose() {
    _keyController.close();
    super.dispose();
  }
}

// Global UI instance
final UI ui = UI();
