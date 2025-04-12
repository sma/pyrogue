import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../beep/beep.dart' as b;
import 'rogue/ui.dart';

class TerminalUI with ChangeNotifier {
  TerminalUI(this.cols, this.rows)
    : _buffer = List.generate(rows, (_) => List.filled(cols, (' ', false)));

  final int cols;
  final int rows;
  final List<List<(String, bool)>> _buffer;
  final List<Completer<String>> _keyCompleters = [];

  int _row = 0;
  int _col = 0;
  int get row => _row;
  int get col => _col;

  // Clear the entire screen
  void clearScreen() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        _buffer[i][j] = (' ', false);
      }
    }
  }

  // Clear from current position to end of line
  void clearToEndOfLine() {
    for (int j = _col; j < cols; j++) {
      _buffer[_row][j] = (' ', false);
    }
  }

  // Move cursor position
  void move(int row, int col) {
    // Store current position for operations
    _row = row;
    _col = col;
  }

  // Read characters from the buffer
  String read(int row, int col, [int length = 1]) {
    String result = '';
    for (int i = 0; i < length && col + i < cols; i++) {
      result += _buffer[row][col + i].$1;
    }
    return result;
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
        _buffer[_row][_col++] = (s[i], inverse);
      }
    }
  }

  // Refresh the display
  void refresh() => notifyListeners();

  // Emit a beep sound
  void beep() {
    b.beep();
  }

  // Get a character input
  Future<String> getchar() {
    final completer = Completer<String>();
    _keyCompleters.add(completer);
    return completer.future;
  }

  // Used by widget to input keys
  void injectKey(String key) {
    if (_keyCompleters.isNotEmpty) {
      _keyCompleters.removeAt(0).complete(key);
    }
  }
}

/// TerminalWidget provides a terminal-like interface for Rogue
/// It renders the game screen and handles keyboard input
class TerminalWidget extends StatefulWidget {
  const TerminalWidget({super.key});

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    ui.addListener(_refresh);
  }

  @override
  void dispose() {
    ui.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChange(bool _) {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final key = event.character;
      if (key != null) {
        ui.injectKey(key);
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        onFocusChange: _onFocusChange,
        onKeyEvent: _handleKeyEvent,
        autofocus: true,
        child: GestureDetector(
          onTap: () {
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
          child: Container(
            color: _hasFocus ? Colors.black : Colors.black54,
            child: Stack(
              children: [
                // Terminal display
                Center(
                  child: Container(
                    width: 800, // Width for 80 columns with fixed-width font
                    height: 600, // Height for 25 rows with fixed-height font
                    padding: const EdgeInsets.all(10),
                    color: Colors.black,
                    child: CustomPaint(painter: TerminalPainter(ui)),
                  ),
                ),

                // Focus indicator
                if (!_hasFocus)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.black45,
                      child: const Text(
                        'Click to focus',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TerminalPainter extends CustomPainter {
  final TerminalUI ui;

  TerminalPainter(this.ui);

  @override
  void paint(Canvas canvas, Size size) {
    final buffer = ui._buffer;
    final double cellWidth = size.width / ui.cols;
    final double cellHeight = size.height / ui.rows;

    canvas.drawRect(
      Rect.fromLTWH(
        ui.col * cellWidth,
        ui.row * cellHeight,
        cellWidth,
        cellHeight,
      ),
      Paint()..color = Colors.orange.shade600,
    );

    final TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: cellHeight * 0.8,
      fontFamily: 'monospace',
    );

    final TextStyle inverseStyle = TextStyle(
      color: Colors.black,
      backgroundColor: Colors.white,
      fontSize: cellHeight * 0.8,
      fontFamily: 'monospace',
    );

    // Draw each character from the buffer
    for (int row = 0; row < buffer.length && row < ui.rows; row++) {
      for (int col = 0; col < buffer[row].length && col < ui.cols; col++) {
        final (char, inverse) = buffer[row][col];
        final TextSpan span = TextSpan(
          text: char,
          style: inverse ? inverseStyle : textStyle,
        );

        final TextPainter textPainter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        final double x = col * cellWidth;
        final double y = row * cellHeight;

        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
