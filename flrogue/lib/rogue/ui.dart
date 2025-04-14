abstract interface class UI {
  /// The number of terminal lines.
  int get rows;

  /// The number of terminal columns.
  int get cols;

  /// The cursor's row; use [move] to change.
  int get row;

  /// The cursor's column; use [move] to change.
  int get col;

  /// Clears the whole screen; cursor position is not affected.
  void clearScreen();

  /// Clears from the cursor position to the end of the current line.
  void clearToEndOfLine();

  /// Moves the cursors, also see [row], [col].
  UI move(int row, int col);

  /// Reads up to [length] characters at the cursor position.
  String read([int length = 1]);

  /// Writes [s] at the cursor position which is changed.
  void write(String s, {bool inverse = false});

  /// Flushes all changes to the "real" terminal.
  void refresh();

  /// Rings a bell or something.
  void beep();

  /// Returns the next character entered on the terminal; no echo.
  Future<String> getchar();

  /// Stop ot.
  void end();
}

late UI ui;
