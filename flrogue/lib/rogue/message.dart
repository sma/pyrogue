import 'package:flrogue/rogue/init.dart';

import 'globals.dart';
import 'ui.dart';

void message(String msg, [int intrpt = 0]) {
  if (intrpt != 0) {
    g.interrupted = 1;
  }
  g.cantInt = 1;
  slurp();

  if (g.messageCleared == 0) {
    ui.move(minRow - 1, g.messageCol);
    ui.write(more);
    ui.refresh();
    waitForAck("");
    checkMessage();
  }

  g.messageLine = msg;
  ui.move(minRow - 1, 0);
  ui.write(msg);
  ui.write(' ');
  ui.refresh();
  g.messageCleared = 0;
  g.messageCol = msg.length;

  if (g.didInt != 0) {
    onintr();
  }
  g.cantInt = 0;
}

void remessage() {
  if (g.messageLine.isNotEmpty) {
    message(g.messageLine, 0);
  }
}

void checkMessage() {
  if (g.messageCleared != 0) {
    return;
  }
  ui.move(minRow - 1, 0);
  ui.clearToEndOfLine();
  ui.move(rogue.row, rogue.col);
  ui.refresh();
  g.messageCleared = 1;
}

Future<String> getInputLine(String prompt, bool echo) async {
  message(prompt, 0);
  String buf = "";
  // ignore: unused_local_variable
  int n = prompt.length;

  while (true) {
    String ch = await ui.getchar();

    if (ch == cancel) {
      buf = "";
      break;
    }

    if (ch == '\n' || ch == '\r') {
      break;
    }

    if (ch == '\b' || ch == '\u007F') {
      // backspace or delete
      if (buf.isNotEmpty) {
        buf = buf.substring(0, buf.length - 1);
        if (echo) {
          ui.write('\b \b');
        }
      }
    }

    if (ch.codeUnitAt(0) >= ' '.codeUnitAt(0) &&
        ch.codeUnitAt(0) <= '~'.codeUnitAt(0)) {
      buf += ch;
      if (echo) {
        ui.write(ch);
      }
    }

    ui.refresh();
  }

  checkMessage();
  return buf;
}

void slurp() {
  // In the original this would clear the input buffer
  // In our async implementation, this isn't necessary
}

void waitForAck(String prompt) async {
  if (prompt.isNotEmpty) {
    ui.write(more);
  }

  while (await ui.getchar() != ' ') {
    // Wait for space
  }
}
