// rogue/terminal_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rogue/ui.dart';

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
                    child: CustomPaint(painter: TerminalPainter(ui.buffer)),
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
  final List<List<String>> buffer;

  TerminalPainter(this.buffer);

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / ui.cols;
    final double cellHeight = size.height / ui.rows;
    final TextStyle textStyle = TextStyle(
      color: Colors.white,
      fontSize: cellHeight * 0.8,
      fontFamily: 'monospace',
    );
    // ignore: unused_local_variable
    final TextStyle inverseStyle = TextStyle(
      color: Colors.black,
      backgroundColor: Colors.white,
      fontSize: cellHeight * 0.8,
      fontFamily: 'monospace',
    );

    // Draw each character from the buffer
    for (int row = 0; row < buffer.length && row < ui.rows; row++) {
      for (int col = 0; col < buffer[row].length && col < ui.cols; col++) {
        final String char = buffer[row][col];
        final TextSpan span = TextSpan(
          text: char,
          style: textStyle, // In a real implementation, check for inverse text
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
