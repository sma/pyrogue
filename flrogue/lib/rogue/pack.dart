// rogue/pack.dart

import 'package:flrogue/rogue/inventory.dart';
import 'package:flrogue/rogue/level.dart';

import 'globals.dart';
import 'object.dart';
import 'ui.dart';
import 'message.dart';
import 'move.dart';
import 'monster.dart';

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

Future<Tuple2<GameObject?, int>> pickUp(int row, int col) async {
  GameObject? obj = objectAt(levelObjects, row, col);
  int status = 1;

  if (obj!.whatIs == Cell.scroll &&
      obj.whichKind == ScrollType.scareMonster.index &&
      obj.pickedUp > 0) {
    await message("the scroll turns to dust as you pick it up", 1);
    removeFromPack(obj, levelObjects);
    removeMask(row, col, Cell.scroll);
    status = 0;
    idScrolls[ScrollType.scareMonster.index].idStatus = IdStatus.identified;
    return Tuple2(null, status);
  }

  if (obj.whatIs == Cell.gold) {
    rogue.gold += obj.quantity;
    removeMask(row, col, Cell.gold);
    removeFromPack(obj, levelObjects);
    printStats();
    return Tuple2(obj, status);
  }

  if (getPackCount(obj) >= maxPackCount) {
    await message("Pack too full", 1);
    return Tuple2(null, status);
  }

  if (obj.whatIs == Cell.amulet) {
    hasAmulet = 1;
  }

  removeMask(row, col, obj.whatIs);
  removeFromPack(obj, levelObjects);
  obj = addToPack(obj, rogue.pack, true);
  obj.pickedUp += 1;
  return Tuple2(obj, status);
}

Future<void> drop() async {
  if (screen[rogue.row][rogue.col] & Cell.isObject != 0) {
    await message("There's already something there", 0);
    return;
  }

  if (rogue.pack.isEmpty) {
    await message("You have nothing to drop", 0);
    return;
  }

  String ch = await getPackLetter("drop what? ", Cell.isObject);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.", 0);
    return;
  }

  if (obj == rogue.weapon) {
    if (obj.isCursed != 0) {
      await message(curseMessage, 0);
      return;
    }
    rogue.weapon = null;
  } else if (obj == rogue.armor) {
    if (obj.isCursed != 0) {
      await message(curseMessage, 0);
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
    await message("dropped ${getDescription(obj)}", 0);
    await registerMove();
    return;
  }

  if (obj.whatIs == Cell.amulet) {
    hasAmulet = 0;
  }

  makeAvailIchar(obj.ichar);
  removeFromPack(obj, rogue.pack);

  addToPack(obj, levelObjects, false);
  addMask(rogue.row, rogue.col, obj.whatIs);
  await message("dropped ${getDescription(obj)}", 0);
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
    if (ichars[i] == 0) {
      ichars[i] = 1;
      return String.fromCharCode('a'.codeUnitAt(0) + i);
    }
  }
  return '';
}

void makeAvailIchar(String ch) {
  ichars[ch.codeUnitAt(0) - 'a'.codeUnitAt(0)] = 0;
}

Future<String> getPackLetter(String prompt, int mask) async {
  int firstMiss = 1;
  await message(prompt, 0);
  String ch = await ui.getchar();

  while (true) {
    while (!isPackLetter(ch)) {
      if (ch.isNotEmpty) {
        ui.beep();
      }

      if (firstMiss != 0) {
        await message(prompt, 0);
        firstMiss = 0;
      }

      ch = await ui.getchar();
    }

    if (ch == list) {
      checkMessage();
      await inventory(rogue.pack, mask);
      firstMiss = 1;
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
      await message(curseMessage, 0);
    } else {
      await mvAquatars();
      GameObject obj = rogue.armor!;
      rogue.armor = null;
      await message("was wearing ${getDescription(obj)}", 0);
      printStats();
      await registerMove();
    }
  } else {
    await message("not wearing any", 0);
  }
}

Future<void> wear() async {
  if (rogue.armor != null) {
    await message("your already wearing some", 0);
    return;
  }

  String ch = await getPackLetter("wear what? ", Cell.armor);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.", 0);
    return;
  }

  if (obj.whatIs != Cell.armor) {
    await message("You can't wear that", 0);
    return;
  }

  rogue.armor = obj;
  obj.identified = 1;
  await message(getDescription(obj), 0);
  printStats();
  await registerMove();
}

Future<void> wield() async {
  if (rogue.weapon != null && rogue.weapon!.isCursed != 0) {
    await message(curseMessage, 0);
    return;
  }

  String ch = await getPackLetter("wield what? ", Cell.weapon);
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.", 0);
    return;
  }

  if (obj.whatIs != Cell.weapon) {
    await message("You can't wield that", 0);
    return;
  }

  if (obj == rogue.weapon) {
    await message("in use", 0);
  } else {
    rogue.weapon = obj;
    await message(getDescription(obj), 0);
    await registerMove();
  }
}

Future<void> callIt() async {
  String ch = await getPackLetter(
    "call what? ",
    Cell.scroll | Cell.potion | Cell.wand,
  );
  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.", 0);
    return;
  }

  if (!(obj.whatIs & (Cell.scroll | Cell.potion | Cell.wand) != 0)) {
    await message("surely you already know what that's called", 0);
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

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}
