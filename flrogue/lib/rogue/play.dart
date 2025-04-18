import 'dart:async';

import 'globals.dart';
import 'hit.dart';
import 'inventory.dart';
import 'level.dart';
import 'message.dart';
import 'move.dart';
import 'pack.dart';
import 'room.dart';
import 'score.dart';
import 'throw.dart';
import 'ui.dart';
import 'use.dart';
import 'zap.dart';

Future<void> playLevel() async {
  int count = 0;

  while (true) {
    interrupted = false;
    if (hitMessage.isNotEmpty) {
      await message(hitMessage);
      hitMessage = "";
    }

    ui.move(rogue.row, rogue.col).refresh();

    String ch = await ui.getchar();
    checkMessage();

    while (true) {
      // for "goto CH"
      if (ch == '.') {
        await rest(count > 0 ? count : 1);
      } else if (ch == 'i') {
        await inventory(rogue.pack, Cell.isObject);
      } else if (ch == 'f') {
        await fight(false);
      } else if (ch == 'F') {
        await fight(true);
      } else if ('hjklyunb'.contains(ch)) {
        await singleMoveRogue(ch, true);
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
      } else if (ch == '>') {
        if (await checkDown()) {
          return;
        }
      } else if (ch == '<') {
        if (await checkUp()) {
          return;
        }
      } else if (ch == 'I') {
        await singleInventory();
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
      } else if (ch == '\x17') {
        drawMagicMap();
      } else if (ch == 'v') {
        await message("pyrogue: Version 1.0 (dart port)");
      } else if (ch == 'Q') {
        await quit();
      } else if ('0123456789'.contains(ch)) {
        count = 0;
        while (true) {
          count = 10 * count + (ch.ascii - '0'.ascii);
          ch = await ui.getchar();
          if (!('0123456789'.contains(ch))) break;
        }
        continue; // goto CH
      } else if (ch == ' ') {
        // Do nothing
      } else {
        await message("unknown command");
      }
      break;
    }
  }
}
