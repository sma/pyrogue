// rogue/play.dart

import 'dart:async';
import 'package:flrogue/rogue/inventory.dart';
import 'package:flrogue/rogue/score.dart';

import 'globals.dart';
import 'move.dart';
import 'message.dart';
import 'use.dart';
import 'throw.dart';
import 'pack.dart';
import 'hit.dart';
import 'level.dart';
import 'ui.dart';
import 'zap.dart';

Future<void> playLevel() async {
  int count = 0;

  while (true) {
    g.interrupted = 0;
    if (g.hitMessage.isNotEmpty) {
      message(g.hitMessage, 0);
      g.hitMessage = "";
    }

    ui.move(rogue.row, rogue.col);
    ui.refresh();

    String ch = await ui.getchar();
    checkMessage();

    while (true) {
      // for "goto CH"
      if (ch == '.') {
        rest(count > 0 ? count : 1);
      } else if (ch == 'i') {
        inventory(rogue.pack, Cell.isObject);
      } else if (ch == 'f') {
        await fight(false);
      } else if (ch == 'F') {
        await fight(true);
      } else if ('hjklyunb'.contains(ch)) {
        await singleMoveRogue(ch, 1);
      } else if ('HJKLYUNB\x08\x0a\x0b\x0c\x19\x15\x0e\x02'.contains(ch)) {
        await multipleMoveRogue(ch);
      } else if (ch == 'e') {
        await eat();
      } else if (ch == 'q') {
        await quaff();
      } else if (ch == 'r') {
        await readScroll();
      } else if (ch == 'm') {
        await moveOnto();
      } else if (ch == 'd') {
        await drop();
      } else if (ch == '\x10') {
        remessage();
      } else if (ch == '>') {
        if (checkDown()) {
          return;
        }
      } else if (ch == '<') {
        if (checkUp()) {
          return;
        }
      } else if (ch == 'I') {
        singleInventory();
      } else if (ch == '\x12') {
        ui.refresh();
      } else if (ch == 'T') {
        await takeOff();
      } else if (ch == 'W' || ch == 'P') {
        await wear();
      } else if (ch == 'w') {
        await wield();
      } else if (ch == 'c') {
        await callIt();
      } else if (ch == 'z') {
        await zapp();
      } else if (ch == 't') {
        await throwItem();
      } else if (ch == '\x1a') {
        tstp();
      } else if (ch == '!') {
        shell();
      } else if (ch == 'v') {
        message("pyrogue: Version 1.0 (dart port)", 0);
      } else if (ch == 'Q') {
        await quit();
      } else if ('0123456789'.contains(ch)) {
        count = 0;
        while (true) {
          count = 10 * count + (ch.codeUnitAt(0) - '0'.codeUnitAt(0));
          ch = await ui.getchar();
          if (!('0123456789'.contains(ch))) break;
        }
        continue; // goto CH
      } else if (ch == ' ') {
        // Do nothing
      } else {
        message("unknown command");
      }
      break;
    }
  }
}

void tstp() {
  // Implement terminal stop functionality if needed
}

void shell() {
  // Implement shell functionality if needed
}
