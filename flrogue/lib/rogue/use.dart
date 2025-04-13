import 'globals.dart';
import 'level.dart' hide levelPoints;
import 'message.dart';
import 'monster.dart';
import 'move.dart';
import 'object.dart';
import 'pack.dart';
import 'room.dart';
import 'ui.dart';

Future<void> quaff() async {
  String ch = await getPackLetter("quaff what?", Cell.potion);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("no such item.");
    return;
  }

  if (obj.whatIs != Cell.potion) {
    await message("you can't drink that");
    return;
  }

  int k = obj.whichKind;
  if (k == PotionType.increaseStrength.index) {
    await message("you feel stronger now, what bulging muscles!");
    rogue.strengthCurrent += 1;
    if (rogue.strengthCurrent > rogue.strengthMax) {
      rogue.strengthMax = rogue.strengthCurrent;
    }
  } else if (k == PotionType.restoreStrength.index) {
    await message("this tastes great, you feel warm all over");
    rogue.strengthCurrent = rogue.strengthMax;
  } else if (k == PotionType.healing.index) {
    await message("you begin to feel better");
    await potionHeal(false);
  } else if (k == PotionType.extraHealing.index) {
    await message("you begin to feel much better");
    await potionHeal(true);
  } else if (k == PotionType.poison.index) {
    rogue.strengthCurrent -= getRand(1, 3);
    if (rogue.strengthCurrent < 0) {
      rogue.strengthCurrent = 0;
    }
    await message("you feel very sick now");
    if (halluc != 0) {
      await unhallucinate();
    }
  } else if (k == PotionType.raiseLevel.index) {
    await message("you feel more experienced");
    await addExp(levelPoints[rogue.exp - 1] - rogue.expPoints + 1);
  } else if (k == PotionType.blindness.index) {
    await goBlind();
  } else if (k == PotionType.hallucination.index) {
    await message("oh wow, everything seems so cosmic");
    halluc += getRand(500, 800);
  } else if (k == PotionType.detectMonster.index) {
    if (levelMonsters.isNotEmpty) {
      showMonsters();
    } else {
      await message("you have a strange feeling for a moment, then it passes");
    }
    detectMonster = true;
  } else if (k == PotionType.detectObjects.index) {
    if (levelObjects.isNotEmpty) {
      if (blind == 0) {
        showObjects();
      }
    } else {
      await message("you have a strange feeling for a moment, then it passes");
    }
  } else if (k == PotionType.confusion.index) {
    await message(halluc != 0 ? "what a trippy feeling" : "you feel confused");
    confuse();
  }

  printStats();

  if (idPotions[k].idStatus != IdStatus.called) {
    idPotions[k].idStatus = IdStatus.identified;
  }

  await vanish(obj, true);
}

Future<void> readScroll() async {
  String ch = await getPackLetter("read what?", Cell.scroll);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("no such item.");
    return;
  }

  if (obj.whatIs != Cell.scroll) {
    await message("you can't read that");
    return;
  }

  var k = ScrollType.values[obj.whichKind];
  switch (k) {
    case ScrollType.scareMonster:
      await message("you hear a maniacal laughter in the distance");
    case ScrollType.holdMonster:
      await holdMonster();
    case ScrollType.enchantWeapon:
      if (rogue.weapon case final weapon?) {
        await message(
          "your ${nameOf(weapon)}glow${weapon.quantity > 1 ? '' : 's'} ${getEnchColor()}for a moment",
        );
        if (getRand(0, 1) != 0) {
          weapon.toHitEnchantment += 1;
        } else {
          weapon.damageEnchantment += 1;
        }
        weapon.isCursed = 0;
      } else {
        await message("your hands tingle");
      }
    case ScrollType.enchantArmor:
      if (rogue.armor case final armor?) {
        await message("your armor glows ${getEnchColor()}for a moment");
        armor.damageEnchantment += 1;
        armor.isCursed = 0;
        printStats();
      } else {
        await message("your skin crawls");
      }
    case ScrollType.identify:
      await message("this is a scroll of identify");
      await message("what would you like to identify?");
      obj.identified = 1;
      idScrolls[k.index].idStatus = IdStatus.identified;
      await identify();
    case ScrollType.teleport:
      teleport();
    case ScrollType.sleep:
      await sleepScroll();
    case ScrollType.protectArmor:
      if (rogue.armor case final armor?) {
        await message("your armor is covered by a shimmering gold shield");
        armor.isProtected = 1;
        armor.isCursed = 0;
      } else {
        await message("your acne seems to have disappeared");
      }
    case ScrollType.removeCurse:
      await message(
        halluc == 0
            ? "you feel as though someone is watching over you"
            : "you feel in touch with the universal oneness",
      );
      rogue.armor?.isCursed = 0;
      rogue.weapon?.isCursed = 0;
    case ScrollType.createMonster:
      await createMonster();
    case ScrollType.aggravateMonster:
      await aggravate();
    case ScrollType.magicMapping:
      await message("this scroll seems to have a map on it");
      drawMagicMap();
  }

  if (idScrolls[k.index].idStatus != IdStatus.called) {
    idScrolls[k.index].idStatus = IdStatus.identified;
  }

  await vanish(obj, true);
}

Future<void> vanish(GameObject obj, bool rm) async {
  if (obj.quantity > 1) {
    obj.quantity -= 1;
  } else {
    removeFromPack(obj, rogue.pack);
    makeAvailIchar(obj.ichar);
  }

  if (rm) {
    await registerMove();
  }
}

Future<void> potionHeal(bool extra) async {
  double ratio = rogue.hpCurrent / rogue.hpMax;

  if (ratio >= 0.9) {
    rogue.hpMax += extra ? 2 : 1;
    rogue.hpCurrent = rogue.hpMax;
  } else {
    if (ratio < 0.33) {
      ratio = 0.33;
    }

    if (extra) {
      ratio += ratio;
    }

    int add = (ratio * (rogue.hpMax - rogue.hpCurrent)).toInt();
    rogue.hpCurrent = [
      rogue.hpCurrent + add,
      rogue.hpMax,
    ].reduce((a, b) => a > b ? a : b);
  }

  if (blind != 0) {
    await unblind();
  }

  if (confused != 0 && extra) {
    await unconfuse();
  } else if (confused != 0) {
    confused = (confused - 9) ~/ 2;
    if (confused <= 0) {
      await unconfuse();
    }
  }

  if (halluc != 0 && extra) {
    await unhallucinate();
  } else if (halluc != 0) {
    halluc = halluc ~/ 2 + 1;
  }
}

Future<void> identify() async {
  while (true) {
    String ch = await getPackLetter("identify what?", Cell.isObject);
    if (ch == cancel) {
      return;
    }

    GameObject? obj = getLetterObject(ch);
    if (obj == null) {
      await message("no such item, try again");
      checkMessage();
      continue;
    }

    obj.identified = 1;
    if (obj.whatIs &
            (Cell.scroll |
                Cell.potion |
                Cell.weapon |
                Cell.armor |
                Cell.wand) !=
        0) {
      List<Identity> idTable = getIdTable(obj);
      idTable[obj.whichKind].idStatus = IdStatus.identified;
    }

    await message(getDescription(obj));
    return;
  }
}

Future<void> eat() async {
  String ch = await getPackLetter("eat what?", Cell.food);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("no such item.");
    return;
  }

  if (obj.whatIs != Cell.food) {
    await message("you can't eat that");
    return;
  }

  int moves = getRand(800, 1000);
  if (moves >= 900) {
    await message("yum, that tasted good");
  } else {
    await message("yuk, that food tasted awful");
    await addExp(3);
  }

  rogue.movesLeft ~/= 2;
  rogue.movesLeft += moves;
  hungerStr = "";
  printStats();

  await vanish(obj, true);
}

Future<void> holdMonster() async {
  int mcount = 0;

  for (int i = -2; i < 3; i++) {
    for (int j = -2; j < 3; j++) {
      int row = rogue.row + i;
      int col = rogue.col + j;

      if (row < minRow || row > ui.rows - 2 || col < 0 || col > ui.cols - 1) {
        continue;
      }

      if (screen[row][col] & Cell.monster != 0) {
        GameObject monster = objectAt(levelMonsters, row, col)!;
        monster.mFlags |= MonsterFlags.isAsleep;
        monster.mFlags &= ~MonsterFlags.wakens;
        mcount += 1;
      }
    }
  }

  if (mcount == 0) {
    await message("you feel a strange sense of loss");
  } else if (mcount == 1) {
    await message("the monster freezes");
  } else {
    await message("the monsters around you freeze");
  }
}

void teleport() {
  if (currentRoom >= 0) {
    darkenRoom(currentRoom);
  } else {
    ui.move(rogue.row, rogue.col);
    ui.write(getRoomChar(screen[rogue.row][rogue.col], rogue.row, rogue.col));
  }

  putPlayer();
  lightUpRoom();
  beingHeld = false;
}

void hallucinate() {
  if (blind != 0) {
    return;
  }

  for (GameObject obj in levelObjects) {
    String ch = ui.read(obj.row, obj.col, 1);

    if (!ch.between('A', 'Z') &&
        (obj.row != rogue.row || obj.col != rogue.col)) {
      if (ch != ' ' && ch != '.' && ch != '#' && ch != '+') {
        ui.move(obj.row, obj.col);
        ui.write(getRandObjChar());
      }
    }
  }

  for (GameObject obj in levelMonsters) {
    String ch = ui.read(obj.row, obj.col, 1);

    if (ch.between('A', 'Z')) {
      ui.move(obj.row, obj.col);
      ui.write(String.fromCharCode(getRand('A'.ascii, 'Z'.ascii)));
    }
  }
}

Future<void> unhallucinate() async {
  halluc = 0;

  if (currentRoom == passage) {
    lightPassage(rogue.row, rogue.col);
  } else {
    lightUpRoom();
  }

  await message("everything looks SO boring now");
}

Future<void> unblind() async {
  blind = 0;
  await message("the veil of darkness lifts");

  if (currentRoom == passage) {
    lightPassage(rogue.row, rogue.col);
  } else {
    lightUpRoom();
  }

  if (detectMonster) {
    showMonsters();
  }

  if (halluc != 0) {
    hallucinate();
  }
}

Future<void> sleepScroll() async {
  await message("you fall asleep");

  int i = getRand(4, 10);
  while (i > 0) {
    await moveMonsters();
    i -= 1;
  }

  await message("you can move again");
}

Future<void> goBlind() async {
  if (blind == 0) {
    await message("a cloak of darkness falls around you");
  }

  blind += getRand(500, 800);

  if (currentRoom >= 0) {
    Room r = rooms[currentRoom];

    for (int i = r.topRow + 1; i < r.bottomRow; i++) {
      for (int j = r.leftCol + 1; j < r.rightCol; j++) {
        ui.move(i, j);
        ui.write(' ');
      }
    }
  }

  ui.move(rogue.row, rogue.col);
  ui.write(rogue.fchar);
  ui.refresh();
}

String getEnchColor() {
  if (halluc != 0) {
    return idPotions[getRand(0, PotionType.values.length - 1)].title;
  }
  return "blue ";
}

void confuse() {
  confused = getRand(12, 22);
}

Future<void> unconfuse() async {
  confused = 0;
  await message("you feel less ${halluc != 0 ? 'trippy' : 'confused'} now");
}
