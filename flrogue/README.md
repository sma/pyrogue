# flrogue

This is an AI conversion done by Claude 3.7 (25-03).

## The prompt

> Attached is a Python implementation of Rogue. It runs in a terminal with curses. Your task is to completely convert this into a Flutter application using idiomatic Dart. Assume the existence of a global `ui` object which is connected t a terminal widget. Assume 80x25 characters. A call to `refresh` will then update the widget. Note that `getchar` returns a future, so you have to adapt the code to deal with that.
>
> ```
> class UI with ChangeNotifier {
>     final rows = 25;
>     final cols = 80;
>     void clearScreen();
>     void clearToEndOfLine();
>     void move(int row, int col);
>     String read(int row, int col, [int length]);
>     void write(String s, {bool inverse = false});
>     void refresh();
>     void beep();
>     Future<String> getchar();
> }
> 
> final ui = UI();
> ```
>
> It should be obvious how curses methods map to his API.
> 
> Note that Dart don't use all-uppercase for constants like `MONSTERS` but normal pascalCase. It might be useful to convert some of the toplevel constants to `enum`s.
>
> Please keep the file name, so everything from `play.py` should be converted into a file `play.dart`. Put everything into a `rogue` folder.

## Porting

After the initial generation, there are 124 errors, 5 warnings, 35 infos. Most often, these are import problems, so let's check. 

_time passes_ 

Without missing imports, I'm down to 21 errors. So let's fix them.

- In `globals`, it created a static constant `isAsleep` as well as a getter method with the same name. It looks like that this method is never used, so removing it was an easy fix.
- In `init`, it called `addToPack` with an `1` instead of `true`. The Python uses uses the fact, that 1 is truthy, but Claude tried to convert everything to booleans. 
- `monster`, there's the line
    ```dart
    int wakePercent = rn == g.partyRoom ? partyWakePercent : wakePercent;
    ```
    where a local variable has the same name as the constant which isn't longer using all-uppercase. 
    
    There's also another case of `int` vs. `bool` in `wakeRoom` which is typed as taking an int where a `bool` is meant.
- `message()` in `message` is sometimes called with just one parameter, so the second one is optional (correct in the Python code).
- `object`, there's a reference to `Cell.passage` which should be simply `passage`.
- in `ui`, where Claude implemented the `UI` class although I intended to provide it myself, it hallucinated that it could use
    ```dart
    int row, col;
    _getCurrentPosition(row, col);
    ```
    for some kind of call by reference. I changed the implementation to
    ```dart
    (int, int) _getCurrentPosition() {
      return (_currentRow, _currentCol);
    }
    ```

I'm now down to 0 errors, 4 warnings and 40 infos.

The warnings are unused local variables which are always a bit suspecious.

Last but not least, I fixed all linter infos, which didn't take long. They reveal one last bug: The code uses ocal string escapes like `\010` which Dart doesn't support.

Now, the application runs and displays a correct screen. Yeah!

You cannot play it, though, because of this:

    ```dart
    String _mapKeyEvent(KeyEvent event) {
      // Map key events to characters needed by the game
      // This is a simplified version - a real implementation would need
      // to handle all key combinations needed by the game
      // Return the character the game expects
      return ''; // Placeholder implementation
    }
    ```

After using `event.character` which is fine for normal characters (arrow keys, functions keys and control sequences would need special treatment) I can actually play the game.

Keyboard handling still doesn't work 100%. Keys are ignored and while I can move with `hjkl`, I cannot open the inventory with `i`, for example. The `TerminalWidget` and the `ui` code seems to work.

Okay, the `inventory` function is run, however, the `waitForAck` function isn't await for, so it doesn't wait for displaying the inventory. This seems to be a general problem and the complete source code isn't correctly adapted to `async` flow. Therefore, Claude eventually failed to do what it was told to do.

- I changed `waitForAck` to return `Future<void>` and added `await` to all calls.
- Now `inventory` needs to be async and all calls need an `await`.
- Because `message` uses `waitForAck`, I added `await` to 120+ calls to `message`.
- Now 40+ more functions like `registerMove` needs `await` which causes more functions to become `async`.
- And 100+ `await`s later, it finally works!

## Running the App

This is a desktop app.

Right now, only **macOS** and **web** support is included and the `dart:io` usage in `score.dart` needs to be fixed.