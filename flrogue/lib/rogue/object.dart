import 'package:flrogue/rogue/level.dart';

import 'globals.dart';
import 'room.dart';
import 'ui.dart';
import 'monster.dart';
import 'pack.dart';

void putObjects() {
  if (currentLevel < maxLevel) return;

  int n = getRand(2, 4);
  if (randPercent(35)) n += 1;

  if (randPercent(50)) {
    idWeapons[WeaponType.shuriken.index].title = "daggers ";
  }

  if (randPercent(5)) {
    makeParty();
  }

  for (int i = 0; i < n; i++) {
    GameObject obj = getRandObject();
    putObjectRandLocation(obj);
    addToPack(obj, levelObjects, false);
  }

  putGold();
}

void putGold() {
  for (int i = 0; i < maxRooms; i++) {
    Room r = rooms[i];
    if (r.isRoom && randPercent(goldPercent)) {
      for (int j = 0; j < 25; j++) {
        int row = getRand(r.topRow + 1, r.bottomRow - 1);
        int col = getRand(r.leftCol + 1, r.rightCol - 1);

        if (screen[row][col] == Cell.floor || screen[row][col] == passage) {
          putGoldAt(row, col);
          break;
        }
      }
    }
  }
}

void putGoldAt(int row, int col) {
  GameObject obj = getAnObject();
  obj.row = row;
  obj.col = col;
  obj.whatIs = Cell.gold;
  obj.quantity = getRand(2 * currentLevel, 16 * currentLevel);
  addMask(row, col, Cell.gold);
  addToPack(obj, levelObjects, false);
}

void putObjectAt(GameObject obj, int row, int col) {
  obj.row = row;
  obj.col = col;
  addMask(row, col, obj.whatIs);
  addToPack(obj, levelObjects, false);
}

GameObject? objectAt(List<GameObject> pack, int row, int col) {
  for (GameObject obj in pack) {
    if (obj.row == row && obj.col == col) {
      return obj;
    }
  }
  return null;
}

GameObject? getLetterObject(String ch) {
  for (GameObject obj in rogue.pack) {
    if (obj.ichar == ch) {
      return obj;
    }
  }
  return null;
}

String nameOf(GameObject obj) {
  int w = obj.whatIs;

  if (w == Cell.scroll) {
    return obj.quantity > 1 ? "scrolls " : "scroll ";
  }

  if (w == Cell.potion) {
    return obj.quantity > 1 ? "potions " : "potion ";
  }

  if (w == Cell.food) {
    return obj.quantity > 1 ? "rations " : "ration ";
  }

  if (w == Cell.wand) {
    return "wand ";
  }

  if (w == Cell.weapon) {
    int k = obj.whichKind;
    if (k == WeaponType.arrow.index) {
      return obj.quantity > 1 ? "arrows " : "arrow ";
    }

    if (k == WeaponType.shuriken.index) {
      if (idWeapons[k].title[0] == 'd') {
        return obj.quantity > 1 ? "daggers " : "dagger ";
      } else {
        return obj.quantity > 1 ? "shurikens " : "shuriken ";
      }
    }

    return idWeapons[k].title;
  }

  if (w == Cell.armor) {
    return idArmors[obj.whichKind].title;
  }

  return "unknown ";
}

GameObject getRandObject() {
  GameObject obj = getAnObject();

  if (foods < currentLevel ~/ 2) {
    obj.whatIs = Cell.food;
  } else {
    obj.whatIs = getRandWhatIs();
  }

  obj.identified = 0;

  int w = obj.whatIs;
  if (w == Cell.scroll) {
    getRandScroll(obj);
  } else if (w == Cell.potion) {
    getRandPotion(obj);
  } else if (w == Cell.weapon) {
    getRandWeapon(obj);
  } else if (w == Cell.armor) {
    getRandArmor(obj);
  } else if (w == Cell.wand) {
    getRandWand(obj);
  } else if (w == Cell.food) {
    foods += 1;
    getFood(obj);
  }

  return obj;
}

int getRandWhatIs() {
  int percent = getRand(1, 92);

  if (percent <= 30) return Cell.scroll;
  if (percent <= 60) return Cell.potion;
  if (percent <= 65) return Cell.wand;
  if (percent <= 75) return Cell.weapon;
  if (percent <= 85) return Cell.armor;
  return Cell.food;
}

void getRandScroll(GameObject obj) {
  int percent = getRand(0, 82);

  if (percent <= 5) {
    obj.whichKind = ScrollType.protectArmor.index;
  } else if (percent <= 11) {
    obj.whichKind = ScrollType.holdMonster.index;
  } else if (percent <= 20) {
    obj.whichKind = ScrollType.createMonster.index;
  } else if (percent <= 35) {
    obj.whichKind = ScrollType.identify.index;
  } else if (percent <= 43) {
    obj.whichKind = ScrollType.teleport.index;
  } else if (percent <= 52) {
    obj.whichKind = ScrollType.sleep.index;
  } else if (percent <= 57) {
    obj.whichKind = ScrollType.scareMonster.index;
  } else if (percent <= 66) {
    obj.whichKind = ScrollType.removeCurse.index;
  } else if (percent <= 71) {
    obj.whichKind = ScrollType.enchantArmor.index;
  } else if (percent <= 76) {
    obj.whichKind = ScrollType.enchantWeapon.index;
  } else {
    obj.whichKind = ScrollType.aggravateMonster.index;
  }
}

void getRandPotion(GameObject obj) {
  int percent = getRand(1, 105);

  if (percent <= 5) {
    obj.whichKind = PotionType.raiseLevel.index;
  } else if (percent <= 15) {
    obj.whichKind = PotionType.detectObjects.index;
  } else if (percent <= 25) {
    obj.whichKind = PotionType.detectMonster.index;
  } else if (percent <= 35) {
    obj.whichKind = PotionType.increaseStrength.index;
  } else if (percent <= 45) {
    obj.whichKind = PotionType.restoreStrength.index;
  } else if (percent <= 55) {
    obj.whichKind = PotionType.healing.index;
  } else if (percent <= 65) {
    obj.whichKind = PotionType.extraHealing.index;
  } else if (percent <= 75) {
    obj.whichKind = PotionType.blindness.index;
  } else if (percent <= 85) {
    obj.whichKind = PotionType.hallucination.index;
  } else if (percent <= 95) {
    obj.whichKind = PotionType.confusion.index;
  } else {
    obj.whichKind = PotionType.poison.index;
  }
}

void getRandWeapon(GameObject obj) {
  obj.whichKind = getRand(0, WeaponType.values.length - 1);

  if (obj.whichKind == WeaponType.arrow.index ||
      obj.whichKind == WeaponType.shuriken.index) {
    obj.quantity = getRand(3, 15);
    obj.quiver = getRand(0, 126);
  } else {
    obj.quantity = 1;
  }

  obj.identified = 0;
  obj.toHitEnchantment = 0;
  obj.damageEnchantment = 0;

  // Long swords are ALWAYS cursed or blessed
  int percent = getRand(
    1,
    obj.whichKind == WeaponType.longSword.index ? 32 : 96,
  );
  int blessing = getRand(1, 3);
  obj.isCursed = 0;

  if (percent <= 16) {
    int increment = 1;
    for (int i = 0; i < blessing; i++) {
      if (randPercent(50)) {
        obj.toHitEnchantment += increment;
      } else {
        obj.damageEnchantment += increment;
      }
    }
  } else if (percent <= 32) {
    int increment = -1;
    obj.isCursed = 1;
    for (int i = 0; i < blessing; i++) {
      if (randPercent(50)) {
        obj.toHitEnchantment += increment;
      } else {
        obj.damageEnchantment += increment;
      }
    }
  }

  int k = obj.whichKind;
  if (k == WeaponType.bow.index) {
    obj.damage = "1d2";
  } else if (k == WeaponType.arrow.index) {
    obj.damage = "1d2";
  } else if (k == WeaponType.shuriken.index) {
    obj.damage = "1d4";
  } else if (k == WeaponType.mace.index) {
    obj.damage = "2d3";
  } else if (k == WeaponType.longSword.index) {
    obj.damage = "3d4";
  } else if (k == WeaponType.twoHandedSword.index) {
    obj.damage = "4d5";
  }
}

void getRandArmor(GameObject obj) {
  obj.whichKind = getRand(0, ArmorType.values.length - 1);
  obj.clasz = obj.whichKind + 2;

  if (obj.whichKind == ArmorType.plate.index ||
      obj.whichKind == ArmorType.splint.index) {
    obj.clasz -= 1;
  }

  obj.isCursed = 0;
  obj.isProtected = 0;
  obj.damageEnchantment = 0;

  int percent = getRand(1, 100);
  int blessing = getRand(1, 3);

  if (percent <= 16) {
    obj.isCursed = 1;
    obj.damageEnchantment -= blessing;
  } else if (percent <= 33) {
    obj.damageEnchantment += blessing;
  }
}

void getRandWand(GameObject obj) {
  obj.whichKind = getRand(0, WandType.values.length - 1);
  obj.clasz = getRand(3, 7);
}

void getFood(GameObject obj) {
  obj.whichKind = Cell.food;
  obj.whatIs = Cell.food;
}

void putStairs() {
  var pos = getRandRowCol(Cell.floor | Cell.tunnel);
  screen[pos.$1][pos.$2] |= Cell.stairs;
}

int getArmorClass(GameObject? obj) {
  if (obj != null) {
    return obj.clasz + obj.damageEnchantment;
  }
  return 0;
}

GameObject getAnObject() {
  return GameObject(0, "", 1, 'L', 0, 0, 0, 0, 0, 0);
}

void makeParty() {
  partyRoom = getRandRoom();
  fillRoomWithMonsters(partyRoom, fillRoomWithObjects(partyRoom));
}

void showObjects() {
  for (GameObject obj in levelObjects) {
    ui.move(obj.row, obj.col);
    ui.write(getRoomChar(obj.whatIs, obj.row, obj.col));
  }
}

void putAmulet() {
  GameObject obj = getAnObject();
  obj.whatIs = Cell.amulet;
  putObjectRandLocation(obj);
  addToPack(obj, levelObjects, false);
}

void putObjectRandLocation(GameObject obj) {
  var pos = getRandRowCol(Cell.floor | Cell.tunnel);
  addMask(pos.$1, pos.$2, obj.whatIs);
  obj.row = pos.$1;
  obj.col = pos.$2;
}

String getDescription(GameObject obj) {
  if (obj.whatIs == Cell.amulet) {
    return "the amulet of Yendor";
  }

  if (obj.whatIs == Cell.gold) {
    return "${obj.quantity} pieces of gold";
  }

  String description = "";

  if (obj.whatIs != Cell.armor) {
    if (obj.quantity == 1) {
      description = "a ";
    } else {
      description = "${obj.quantity} ";
    }
  }

  String itemName = nameOf(obj);

  if (obj.whatIs == Cell.food) {
    description += itemName;
    description += "of food ";
    return description;
  }

  List<Identity> idTable = getIdTable(obj);
  String title = idTable[obj.whichKind].title;

  IdStatus k = idTable[obj.whichKind].idStatus;
  if (k == IdStatus.unidentified &&
      !(obj.whatIs & (Cell.weapon | Cell.armor | Cell.wand) != 0 &&
          obj.identified != 0)) {
    // CHECK:
    int kk = obj.whatIs;
    if (kk == Cell.scroll) {
      description += itemName;
      description += "entitled: ";
      description += title;
    } else if (kk == Cell.potion) {
      description += title;
      description += itemName;
    } else if (kk == Cell.wand) {
      description += title;
      description += itemName;
    } else if (kk == Cell.armor) {
      description = title;
      if (obj == rogue.armor) {
        description += "being worn";
      }
    } else if (kk == Cell.weapon) {
      description += itemName;
      if (obj == rogue.weapon) {
        description += "in hand";
      }
    }
  } else if (k == IdStatus.called) {
    // CALL:
    int kk = obj.whatIs;
    if (kk == Cell.scroll || kk == Cell.potion || kk == Cell.wand) {
      description += itemName;
      description += "called ";
      description += title;
      // goto MI
      if (obj.identified != 0) {
        description += "[${obj.clasz}]";
      }
    }
  } else if (k == IdStatus.identified ||
      (obj.whatIs & (Cell.weapon | Cell.armor | Cell.wand) != 0 &&
          obj.identified != 0)) {
    // ID:
    int kk = obj.whatIs;
    if (kk == Cell.scroll || kk == Cell.potion || kk == Cell.wand) {
      description += itemName;
      description += idTable[obj.whichKind].real;
      if (kk == Cell.wand) {
        // MI:
        if (obj.identified != 0) {
          description += "[${obj.clasz}]";
        }
      }
    } else if (kk == Cell.armor) {
      description =
          "${obj.damageEnchantment >= 0 ? '+' : ''}${obj.damageEnchantment} ";
      description += title;
      description += "[${getArmorClass(obj)}] ";
      if (obj == rogue.armor) {
        description += "being worn";
      }
    } else if (kk == Cell.weapon) {
      description +=
          "${obj.toHitEnchantment >= 0 ? '+' : ''}${obj.toHitEnchantment},";
      description +=
          "${obj.damageEnchantment >= 0 ? '+' : ''}${obj.damageEnchantment} ";
      description += itemName;
      if (obj == rogue.weapon) {
        description += "in hand";
      }
    }
  }

  return description;
}

List<Identity> getIdTable(GameObject obj) {
  int k = obj.whatIs;
  if (k == Cell.scroll) {
    return idScrolls;
  }
  if (k == Cell.potion) {
    return idPotions;
  }
  if (k == Cell.wand) {
    return idWands;
  }
  if (k == Cell.weapon) {
    return idWeapons;
  }
  if (k == Cell.armor) {
    return idArmors;
  }
  throw Exception("Unknown object type");
}

int fillRoomWithObjects(int rn) {
  Room r = rooms[rn];
  int N = (r.bottomRow - r.topRow - 1) * (r.rightCol - r.leftCol - 1);
  int n = getRand(5, 10);
  if (n > N) n = N - 2;

  for (int i = 0; i < n; i++) {
    int row, col;
    while (true) {
      row = getRand(r.topRow + 1, r.bottomRow - 1);
      col = getRand(r.leftCol + 1, r.rightCol - 1);
      if (screen[row][col] == Cell.floor) break;
    }

    GameObject obj = getRandObject();
    putObjectAt(obj, row, col);
  }

  return n;
}
