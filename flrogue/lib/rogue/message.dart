import 'globals.dart';
import 'ui.dart';

Future<void> message(String msg, [bool intrpt = false]) async {
  if (intrpt) {
    interrupted = true;
  }

  if (!messageCleared) {
    ui.move(minRow - 1, messageCol);
    ui.write(more);
    ui.refresh();
    await waitForAck("");
    checkMessage();
  }

  ui.move(minRow - 1, 0);
  ui.write(msg);
  ui.write(' ');
  ui.refresh();
  messageCleared = false;
  messageCol = msg.length;
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
  await message(prompt);
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

Future<void> waitForAck(String prompt) async {
  if (prompt.isNotEmpty) {
    ui.write(more);
  }

  while (await ui.getchar() != ' ') {
    // Wait for space
  }
}
