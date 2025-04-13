import 'globals.dart';
import 'inventory.dart';
import 'level.dart';
import 'message.dart';
import 'monster.dart';
import 'move.dart';
import 'object.dart';
import 'ui.dart';

const String curseMessage = "you can't, it appears to be cursed";

GameObject addToPack(GameObject obj, List<GameObject> pack, bool condense) {
  if (condense) {
    GameObject? op = checkDuplicate(obj, pack);
    if (op != null) {
      return op;
    } else {
      obj.ichar = nextAvailIchar();
    }
  }
  pack.add(obj);
  return obj;
}

void removeFromPack(GameObject obj, List<GameObject> pack) {
  pack.remove(obj);
}

Future<(GameObject?, bool)> pickUp(int row, int col) async {
  GameObject? obj = objectAt(levelObjects, row, col);
  bool status = true;

  if (obj!.whatIs == Cell.scroll &&
      obj.whichKind == ScrollType.scareMonster.index &&
      obj.pickedUp > 0) {
    await message("the scroll turns to dust as you pick it up", true);
    removeFromPack(obj, levelObjects);
    removeMask(row, col, Cell.scroll);
    status = false;
    idScrolls[ScrollType.scareMonster.index].idStatus = IdStatus.identified;
    return (null, status);
  }

  if (obj.whatIs == Cell.gold) {
    rogue.gold += obj.quantity;
    removeMask(row, col, Cell.gold);
    removeFromPack(obj, levelObjects);
    printStats();
    return (obj, status);
  }

  if (getPackCount(obj) >= maxPackCount) {
    await message("Pack too full", true);
    return (null, status);
  }

  if (obj.whatIs == Cell.amulet) {
    hasAmulet = true;
  }

  removeMask(row, col, obj.whatIs);
  removeFromPack(obj, levelObjects);
  obj = addToPack(obj, rogue.pack, true);
  obj.pickedUp += 1;
  return (obj, status);
}

Future<void> drop() async {
  if (screen[rogue.row][rogue.col] & Cell.isObject != 0) {
    await message("There's already something there");
    return;
  }

  if (rogue.pack.isEmpty) {
    await message("You have nothing to drop");
    return;
  }

  String ch = await getPackLetter("drop what?", Cell.isObject);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.");
    return;
  }

  if (obj == rogue.weapon) {
    if (obj.isCursed != 0) {
      await message(curseMessage);
      return;
    }
    rogue.weapon = null;
  } else if (obj == rogue.armor) {
    if (obj.isCursed != 0) {
      await message(curseMessage);
      return;
    }
    rogue.armor = null;
    printStats();
  }

  obj.row = rogue.row;
  obj.col = rogue.col;

  if (obj.quantity > 1 && obj.whatIs != Cell.weapon) {
    obj.quantity -= 1;
    GameObject newObj = getAnObject();
    newObj = obj.copy();
    newObj.quantity = 1;
    obj = newObj;

    addToPack(obj, levelObjects, false);
    addMask(rogue.row, rogue.col, obj.whatIs);
    await message("dropped ${getDescription(obj)}");
    await registerMove();
    return;
  }

  if (obj.whatIs == Cell.amulet) {
    hasAmulet = false;
  }

  makeAvailIchar(obj.ichar);
  removeFromPack(obj, rogue.pack);

  addToPack(obj, levelObjects, false);
  addMask(rogue.row, rogue.col, obj.whatIs);
  await message("dropped ${getDescription(obj)}");
  await registerMove();
}

GameObject? checkDuplicate(GameObject obj, List<GameObject> pack) {
  if (!(obj.whatIs & (Cell.weapon | Cell.food | Cell.scroll | Cell.potion) !=
      0)) {
    return null;
  }

  for (GameObject op in pack) {
    if (op.whatIs == obj.whatIs && op.whichKind == obj.whichKind) {
      if (obj.whatIs != Cell.weapon ||
          (obj.whatIs == Cell.weapon &&
              (obj.whichKind == WeaponType.arrow.index ||
                  obj.whichKind == WeaponType.shuriken.index) &&
              obj.quiver == op.quiver)) {
        op.quantity += obj.quantity;
        return op;
      }
    }
  }

  return null;
}

String nextAvailIchar() {
  for (int i = 0; i < 26; i++) {
    if (!ichars[i]) {
      ichars[i] = true;
      return String.fromCharCode('a'.ascii + i);
    }
  }
  return '';
}

void makeAvailIchar(String ch) {
  ichars[ch.ascii - 'a'.ascii] = false;
}

Future<String> getPackLetter(String prompt, int mask) async {
  bool firstMiss = true;
  await message(prompt);
  String ch = await ui.getchar();

  while (true) {
    while (!isPackLetter(ch)) {
      if (ch.isNotEmpty) {
        ui.beep();
      }

      if (firstMiss) {
        await message(prompt);
        firstMiss = false;
      }

      ch = await ui.getchar();
    }

    if (ch == list) {
      checkMessage();
      await inventory(rogue.pack, mask);
      firstMiss = true;
      ch = ' ';
      continue;
    }

    break;
  }

  checkMessage();
  return ch;
}

Future<void> takeOff() async {
  if (rogue.armor != null) {
    if (rogue.armor!.isCursed != 0) {
      await message(curseMessage);
    } else {
      await mvAquatars();
      GameObject obj = rogue.armor!;
      rogue.armor = null;
      await message("was wearing ${getDescription(obj)}");
      printStats();
      await registerMove();
    }
  } else {
    await message("not wearing any");
  }
}

Future<void> wear() async {
  if (rogue.armor != null) {
    await message("your already wearing some");
    return;
  }

  String ch = await getPackLetter("wear what?", Cell.armor);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.");
    return;
  }

  if (obj.whatIs != Cell.armor) {
    await message("You can't wear that");
    return;
  }

  rogue.armor = obj;
  obj.identified = 1;
  await message(getDescription(obj));
  printStats();
  await registerMove();
}

Future<void> wield() async {
  if (rogue.weapon != null && rogue.weapon!.isCursed != 0) {
    await message(curseMessage);
    return;
  }

  String ch = await getPackLetter("wield what?", Cell.weapon);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.");
    return;
  }

  if (obj.whatIs != Cell.weapon) {
    await message("You can't wield that");
    return;
  }

  if (obj == rogue.weapon) {
    await message("in use");
  } else {
    rogue.weapon = obj;
    await message(getDescription(obj));
    await registerMove();
  }
}

Future<void> callIt() async {
  String ch = await getPackLetter(
    "call what?",
    Cell.scroll | Cell.potion | Cell.wand,
  );
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.");
    return;
  }

  if (!(obj.whatIs & (Cell.scroll | Cell.potion | Cell.wand) != 0)) {
    await message("surely you already know what that's called");
    return;
  }

  List<Identity> idTable = getIdTable(obj);

  String buf = await getInputLine("call it:", true);
  if (buf.isNotEmpty) {
    idTable[obj.whichKind].idStatus = IdStatus.called;
    idTable[obj.whichKind].title = buf;
  }
}

int getPackCount(GameObject newObj) {
  int count = 0;

  for (GameObject obj in rogue.pack) {
    if (obj.whatIs != Cell.weapon) {
      count += obj.quantity;
    } else {
      if (newObj.whatIs != Cell.weapon ||
          (newObj.whichKind != WeaponType.arrow.index &&
              newObj.whichKind != WeaponType.shuriken.index) ||
          newObj.whichKind != obj.whichKind ||
          newObj.quiver != obj.quiver) {
        count += 1;
      }
    }
  }

  return count;
}
