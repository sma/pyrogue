import 'package:flrogue/rogue/init.dart';

import 'globals.dart';
import 'ui.dart';

Future<void> message(String msg, [int intrpt = 0]) async {
  if (intrpt != 0) {
    interrupted = true;
  }
  cantInt = true;
  slurp();

  if (!messageCleared) {
    ui.move(minRow - 1, messageCol);
    ui.write(more);
    ui.refresh();
    await waitForAck("");
    checkMessage();
  }

  messageLine = msg;
  ui.move(minRow - 1, 0);
  ui.write(msg);
  ui.write(' ');
  ui.refresh();
  messageCleared = false;
  messageCol = msg.length;

  if (didInt) {
    await onintr();
  }
  cantInt = false;
}

Future<void> remessage() async {
  if (messageLine.isNotEmpty) {
    await message(messageLine, 0);
  }
}

void checkMessage() {
  if (messageCleared) {
    return;
  }
  ui.move(minRow - 1, 0);
  ui.clearToEndOfLine();
  ui.move(rogue.row, rogue.col);
  ui.refresh();
  messageCleared = true;
}

Future<String> getInputLine(String prompt, bool echo) async {
  await message(prompt, 0);
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

Future<void> waitForAck(String prompt) async {
  if (prompt.isNotEmpty) {
    ui.write(more);
  }

  while (await ui.getchar() != ' ') {
    // Wait for space
  }
}
