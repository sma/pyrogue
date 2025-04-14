import 'globals.dart';
import 'hit.dart';
import 'level.dart';
import 'message.dart';
import 'monster.dart';
import 'object.dart';
import 'pack.dart';
import 'room.dart';
import 'score.dart';
import 'ui.dart';
import 'use.dart';

Future<void> specialHit(GameObject monster) async {
  String k = monster.ichar;
  if (k == 'A') {
    await _rust(monster);
  } else if (k == 'F') {
    beingHeld = true;
  } else if (k == 'I') {
    await _freeze(monster);
  } else if (k == 'L') {
    await _stealGold(monster);
  } else if (k == 'N') {
    await _stealItem(monster);
  } else if (k == 'R') {
    await _sting(monster);
  } else if (k == 'V') {
    await _drainLife();
  } else if (k == 'W') {
    await _drainLevel();
  }
}

Future<void> _rust(GameObject monster) async {
  if (rogue.armor == null ||
      getArmorClass(rogue.armor) <= 1 ||
      rogue.armor!.whichKind == ArmorType.leather.index) {
    return;
  }

  if (rogue.armor!.isProtected != 0) {
    if (monster.identified == 0) {
      await message("the rust vanishes instantly");
      monster.identified = 1;
    }
  } else {
    rogue.armor!.damageEnchantment -= 1;
    await message("your armor weakens");
    printStats();
  }
}

Future<void> _freeze(GameObject monster) async {
  if (!randPercent(12)) return;

  int freezePercent = 99;
  freezePercent -= rogue.strengthCurrent + rogue.strengthCurrent ~/ 2;
  freezePercent -= rogue.exp * 4;
  freezePercent -= getArmorClass(rogue.armor) * 5;
  freezePercent -= rogue.hpMax ~/ 3;

  if (freezePercent > 10) {
    monster.identified = 1;
    await message("you are frozen", true);

    int n = getRand(5, 9);
    for (int i = 0; i < n; i++) {
      await moveMonsters();
    }

    if (randPercent(freezePercent)) {
      for (int i = 0; i < 50; i++) {
        await moveMonsters();
      }
      await killedBy(null, DeathCause.hypothermia);
    }

    await message("you can move again", true);
    monster.identified = 0;
  }
}

Future<void> _stealGold(GameObject monster) async {
  if (!randPercent(15)) return;

  int amount;
  if (rogue.gold > 50) {
    amount = rogue.gold > 1000 ? getRand(8, 15) : getRand(2, 5);
    amount = rogue.gold ~/ amount;
  } else {
    amount = rogue.gold ~/ 2;
  }

  amount += (getRand(0, 2) - 1) * (rogue.exp + currentLevel);

  if (amount <= 0 && rogue.gold > 0) {
    amount = rogue.gold;
  }

  if (amount > 0) {
    rogue.gold -= amount;
    await message("your purse feels lighter");
    printStats();
  }

  _disappear(monster);
}

Future<void> _stealItem(GameObject monster) async {
  if (!randPercent(15)) return;

  int items = 0;
  for (GameObject obj in rogue.pack) {
    if (obj != rogue.armor && obj != rogue.weapon) {
      items++;
    }
  }

  if (items > 0) {
    int n = getRand(0, items);

    GameObject obj = rogue.pack.first;
    for (obj in rogue.pack) {
      if (obj != rogue.armor && obj != rogue.weapon) {
        if (--n < 0) {
          break;
        }
      }
    }

    await message("she stole ${getDescription(obj)}");

    if (obj.whatIs == Cell.amulet) {
      hasAmulet = false;
    }

    await vanish(obj, false);
  }

  _disappear(monster);
}

void _disappear(GameObject monster) {
  int row = monster.row;
  int col = monster.col;

  removeMask(row, col, Cell.monster);
  if (canSee(row, col)) {
    ui.move(row, col);
    ui.write(getRoomChar(screen[row][col], row, col));
  }

  removeFromPack(monster, levelMonsters);
}

void coughUp(GameObject monster) {
  if (currentLevel < maxLevel) return;

  GameObject obj;

  if (monster.ichar == 'L') {
    obj = getAnObject();
    obj.whatIs = Cell.gold;
    obj.quantity = getRand(9, 599);
  } else {
    if (randPercent(monster.whichKind)) {
      obj = getRandObject();
    } else {
      return;
    }
  }

  int row = monster.row;
  int col = monster.col;

  for (int n = 0; n < 6; n++) {
    for (int i = -n; i <= n; i++) {
      if (_tryToCough(row + n, col + i, obj)) {
        return;
      }
      if (_tryToCough(row - n, col + i, obj)) {
        return;
      }
    }

    for (int i = -n; i <= n; i++) {
      if (_tryToCough(row + i, col - n, obj)) {
        return;
      }
      if (_tryToCough(row + i, col + n, obj)) {
        return;
      }
    }
  }
}

bool _tryToCough(int row, int col, GameObject obj) {
  if (row < minRow || row > ui.rows - 2 || col < 0 || col > ui.cols - 1) {
    return false;
  }

  if (!(screen[row][col] & Cell.isObject != 0) &&
      !(screen[row][col] & Cell.monster != 0) &&
      (screen[row][col] & (Cell.tunnel | Cell.floor | Cell.door) != 0)) {
    putObjectAt(obj, row, col);
    ui.move(row, col);
    ui.write(getRoomChar(screen[row][col], row, col));
    ui.refresh();
    return true;
  }

  return false;
}

Future<bool> orcGold(GameObject monster) async {
  if (monster.identified != 0) {
    return false;
  }

  int rn = getRoomNumber(monster.row, monster.col);
  if (rn < 0) {
    return false;
  }

  Room r = rooms[rn];
  for (int i = r.topRow + 1; i < r.bottomRow; i++) {
    for (int j = r.leftCol + 1; j < r.rightCol; j++) {
      if (screen[i][j] & Cell.gold != 0 &&
          !(screen[i][j] & Cell.monster != 0)) {
        monster.flagsAdd(MonsterFlags.canGo);
        bool s = monsterCanGo(monster, i, j);
        monster.flagsRemove(MonsterFlags.canGo);

        if (s) {
          moveMonsterTo(monster, i, j);
          monster.flagsAdd(MonsterFlags.isAsleep);
          monster.flagsRemove(MonsterFlags.wakens);
          monster.identified = 1;
          return true;
        }

        monster.identified = 1;
        monster.flagsAdd(MonsterFlags.canGo);
        await mvMonster(monster, i, j);
        monster.flagsRemove(MonsterFlags.canGo);
        monster.identified = 0;
        return true;
      }
    }
  }

  return false;
}

void checkOrc(GameObject monster) {
  if (monster.ichar == 'O') {
    monster.identified = 1;
  }
}

Future<bool> checkXeroc(GameObject monster) async {
  if (monster.ichar == 'X' && monster.identified != 0) {
    wakeUp(monster);
    monster.identified = 0;
    ui.move(monster.row, monster.col);
    ui.write(
      getRoomChar(screen[monster.row][monster.col], monster.row, monster.col),
    );
    checkMessage();
    await message("wait, that's a ${monsterName(monster)}!", true);
    return true;
  }
  return false;
}

bool hidingXeroc(int row, int col) {
  if (currentLevel < xeroc1 ||
      currentLevel > xeroc2 ||
      !(screen[row][col] & Cell.monster != 0)) {
    return false;
  }

  GameObject monster = objectAt(levelMonsters, row, col)!;
  return monster.ichar == 'X' && monster.identified != 0;
}

Future<void> _sting(GameObject monster) async {
  if (rogue.strengthCurrent < 5) return;

  int stingChance = 35;
  int ac = getArmorClass(rogue.armor);
  stingChance += 6 * (6 - ac);

  if (rogue.exp > 8) {
    stingChance -= 6 * (rogue.exp - 8);
  }

  stingChance = stingChance > 100 ? 100 : stingChance;
  stingChance = stingChance < 1 ? 1 : stingChance;

  if (randPercent(stingChance)) {
    await message("the ${monsterName(monster)}'s bite has weakened you");
    rogue.strengthCurrent -= 1;
    printStats();
  }
}

Future<void> _drainLevel() async {
  if (!randPercent(20) || rogue.exp < 8) {
    return;
  }

  rogue.expPoints = levelPoints[rogue.exp - 2] - getRand(10, 50);
  rogue.exp -= 2;
  await addExp(1);
}

Future<void> _drainLife() async {
  if (!randPercent(25) || rogue.hpMax <= 30 || rogue.hpCurrent < 10) {
    return;
  }

  await message("you feel weaker");
  rogue.hpMax -= 1;
  rogue.hpCurrent -= 1;

  if (randPercent(50)) {
    if (rogue.strengthCurrent >= 5) {
      rogue.strengthCurrent -= 1;
      if (randPercent(50)) {
        rogue.strengthMax -= 1;
      }
    }
  }

  printStats();
}

Future<bool> mConfuse(GameObject monster) async {
  if (monster.identified != 0) {
    return false;
  }

  if (!canSee(monster.row, monster.col)) {
    return false;
  }

  if (randPercent(45)) {
    monster.identified = 1;
    return false;
  }

  if (randPercent(55)) {
    monster.identified = 1;
    await message(
      "the gaze of the ${monsterName(monster)} has confused you",
      true,
    );
    confuse();
    return true;
  }

  return false;
}

Future<bool> flameBroil(GameObject monster) async {
  if (!randPercent(50)) {
    return false;
  }

  int row = monster.row, col = monster.col;
  if (!canSee(row, col)) {
    return false;
  }

  if (!rogueIsAround(row, col)) {
    (row, col) = _getCloser(row, col, rogue.row, rogue.col);

    ui.move(row, col);
    ui.write('*', inverse: true);

    while (row != rogue.row || col != rogue.col) {
      (row, col) = _getCloser(row, col, rogue.row, rogue.col);

      if (row == rogue.row && col == rogue.col) break;

      ui.move(row, col);
      ui.write('*', inverse: true);
      ui.refresh();
    }

    row = monster.row;
    col = monster.col;
    (row, col) = _getCloser(row, col, rogue.row, rogue.col);

    while (row != rogue.row || col != rogue.col) {
      ui.move(row, col);
      ui.write(getRoomChar(screen[row][col], row, col));
      ui.refresh();

      (row, col) = _getCloser(row, col, rogue.row, rogue.col);

      if (row == rogue.row && col == rogue.col) break;
    }
  }

  await monsterHit(monster, "flame");
  return true;
}

(int, int) _getCloser(int row, int col, int trow, int tcol) {
  if (row < trow) {
    row += 1;
  } else if (row > trow) {
    row -= 1;
  }

  if (col < tcol) {
    col += 1;
  } else if (col > tcol) {
    col -= 1;
  }

  return (row, col);
}
