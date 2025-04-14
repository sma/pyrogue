import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flrogue/rogue/main.dart' as rogue;
import 'package:flrogue/rogue/ui.dart';

Future<void> main() async {
  ui = StdioUI();
  await rogue.main();
}

class StdioUI implements UI {
  StdioUI() : _screen = List.generate(25, (_) => List.filled(80, ' ')) {
    stdin.echoMode = false;
    stdin.lineMode = false;
    _ss = stdin
        .transform(utf8.decoder)
        .listen((data) => _input.removeAt(0).complete(data));
  }

  final List<List<String>> _screen;
  final List<Completer<String>> _input = [];

  StreamSubscription<String>? _ss;

  int _cx = 0;
  int _cy = 0;

  @override
  int get rows => 25; // stdout.terminalLines;

  @override
  int get cols => 80; // stdout.terminalColumns;

  @override
  int get col => _cx;

  @override
  int get row => _cy;

  @override
  void clearScreen() {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        _screen[y][x] = ' ';
      }
    }
  }

  @override
  void clearToEndOfLine() {
    for (var x = _cx; x < cols; x++) {
      _screen[_cy][x] = ' ';
    }
  }

  @override
  UI move(int row, int col) {
    _cy = row;
    _cx = col;
    return this;
  }

  @override
  String read([int length = 1]) {
    if (length == 1) {
      return _screen[_cy][_cx];
    } else {
      return _screen[_cy].sublist(_cx, _cx + length).join();
    }
  }

  @override
  void write(String s, {bool inverse = false}) {
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '\n') {
        _cx = 0;
        _cy++;
      } else if (ch == '\b') {
        if (_cx > 0) {
          _cx--;
          if (_cx < 0) {
            _cx += cols;
            _cy--;
          }
        }
      } else {
        _screen[_cy][_cx] = ch;
        _cx++;
        if (_cx == cols) {
          _cx = 0;
          _cy++;
        }
      }
    }
  }

  @override
  void refresh() {
    final sb = StringBuffer();
    sb.write('\x1b[?1049h\x1b[?25l\x1b[2J');
    for (var y = 0; y < rows; y++) {
      sb.write('\x1b[${y + 1}H');
      for (var x = 0; x < cols; x++) {
        sb.write(_screen[y][x]);
      }
    }
    sb.write('\x1b[${_cy + 1};${_cx + 1}H\x1b[?25h');
    stdout.write(sb);
  }

  @override
  void beep() {
    stdout.write('\b');
  }

  @override
  Future<String> getchar() {
    final completer = Completer<String>();
    _input.add(completer);
    return completer.future;
  }

  @override
  void end() {
    stdout.write('\x1b[?1049l');
    stdin.echoMode = true;
    stdin.lineMode = true;
    unawaited(_ss?.cancel());
  }
}
