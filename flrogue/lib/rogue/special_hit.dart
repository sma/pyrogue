// rogue/special_hit.dart

import 'package:flrogue/rogue/hit.dart';
import 'package:flrogue/rogue/score.dart';

import 'globals.dart';
import 'message.dart';
import 'ui.dart';
import 'room.dart';
import 'monster.dart';
import 'level.dart' hide levelPoints;
import 'object.dart';
import 'pack.dart';
import 'use.dart';

void specialHit(GameObject monster) {
  String k = monster.ichar;
  if (k == 'A') {
    rust(monster);
  } else if (k == 'F') {
    g.beingHeld = 1;
  } else if (k == 'I') {
    freeze(monster);
  } else if (k == 'L') {
    stealGold(monster);
  } else if (k == 'N') {
    stealItem(monster);
  } else if (k == 'R') {
    sting(monster);
  } else if (k == 'V') {
    drainLife();
  } else if (k == 'W') {
    drainLevel();
  }
}

void rust(GameObject monster) {
  if (rogue.armor == null ||
      getArmorClass(rogue.armor) <= 1 ||
      rogue.armor!.whichKind == ArmorType.leather.index) {
    return;
  }

  if (rogue.armor!.isProtected != 0) {
    if (monster.identified == 0) {
      message("the rust vanishes instantly", 0);
      monster.identified = 1;
    }
  } else {
    rogue.armor!.damageEnchantment -= 1;
    message("your armor weakens", 0);
    printStats();
  }
}

void freeze(GameObject monster) {
  if (!randPercent(12)) return;

  int freezePercent = 99;
  freezePercent -= rogue.strengthCurrent + rogue.strengthCurrent ~/ 2;
  freezePercent -= rogue.exp * 4;
  freezePercent -= getArmorClass(rogue.armor) * 5;
  freezePercent -= rogue.hpMax ~/ 3;

  if (freezePercent > 10) {
    monster.identified = 1;
    message("you are frozen", 1);

    int n = getRand(5, 9);
    for (int i = 0; i < n; i++) {
      moveMonsters();
    }

    if (randPercent(freezePercent)) {
      for (int i = 0; i < 50; i++) {
        moveMonsters();
      }
      killedBy(null, DeathCause.hypothermia);
    }

    message("you can move again", 1);
    monster.identified = 0;
  }
}

void stealGold(GameObject monster) {
  if (!randPercent(15)) return;

  int amount;
  if (rogue.gold > 50) {
    amount = rogue.gold > 1000 ? getRand(8, 15) : getRand(2, 5);
    amount = rogue.gold ~/ amount;
  } else {
    amount = rogue.gold ~/ 2;
  }

  amount += (getRand(0, 2) - 1) * (rogue.exp + g.currentLevel);

  if (amount <= 0 && rogue.gold > 0) {
    amount = rogue.gold;
  }

  if (amount > 0) {
    rogue.gold -= amount;
    message("your purse feels lighter", 0);
    printStats();
  }

  disappear(monster);
}

void stealItem(GameObject monster) {
  if (!randPercent(15)) return;

  bool hasSomething = false;
  GameObject? obj = rogue.pack.nextObject;

  while (obj != null) {
    if (obj != rogue.armor && obj != rogue.weapon) {
      hasSomething = true;
      break;
    }
    obj = obj.nextObject;
  }

  if (hasSomething) {
    int n = getRand(0, maxPackCount);
    obj = rogue.pack.nextObject;

    for (int i = 0; i < n + 1; i++) {
      obj = obj!.nextObject;
      while (obj == null || obj == rogue.armor || obj == rogue.weapon) {
        if (obj == null) {
          obj = rogue.pack.nextObject;
        } else {
          obj = obj.nextObject;
        }
      }
    }

    message("she stole ${getDescription(obj!)}", 0);

    if (obj.whatIs == Cell.amulet) {
      g.hasAmulet = 0;
    }

    vanish(obj, false);
  }

  disappear(monster);
}

void disappear(GameObject monster) {
  int row = monster.row;
  int col = monster.col;

  removeMask(row, col, Cell.monster);
  if (canSee(row, col)) {
    ui.move(row, col);
    ui.write(getRoomChar(screen[row][col], row, col));
  }

  removeFromPack(monster, g.levelMonsters);
}

void coughUp(GameObject monster) {
  if (g.currentLevel < g.maxLevel) return;

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
      if (tryToCough(row + n, col + i, obj)) {
        return;
      }
      if (tryToCough(row - n, col + i, obj)) {
        return;
      }
    }

    for (int i = -n; i <= n; i++) {
      if (tryToCough(row + i, col - n, obj)) {
        return;
      }
      if (tryToCough(row + i, col + n, obj)) {
        return;
      }
    }
  }
}

bool tryToCough(int row, int col, GameObject obj) {
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

bool orcGold(GameObject monster) {
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
        monster.mFlags |= MonsterFlags.canGo;
        bool s = monsterCanGo(monster, i, j);
        monster.mFlags &= ~MonsterFlags.canGo;

        if (s) {
          moveMonsterTo(monster, i, j);
          monster.mFlags |= MonsterFlags.isAsleep;
          monster.mFlags &= ~MonsterFlags.wakens;
          monster.identified = 1;
          return true;
        }

        monster.identified = 1;
        monster.mFlags |= MonsterFlags.canGo;
        mvMonster(monster, i, j);
        monster.mFlags &= ~MonsterFlags.canGo;
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

bool checkXeroc(GameObject monster) {
  if (monster.ichar == 'X' && monster.identified != 0) {
    wakeUp(monster);
    monster.identified = 0;
    ui.move(monster.row, monster.col);
    ui.write(
      getRoomChar(screen[monster.row][monster.col], monster.row, monster.col),
    );
    checkMessage();
    message("wait, that's a ${monsterName(monster)}!", 1);
    return true;
  }
  return false;
}

bool hidingXeroc(int row, int col) {
  if (g.currentLevel < xeroc1 ||
      g.currentLevel > xeroc2 ||
      !(screen[row][col] & Cell.monster != 0)) {
    return false;
  }

  GameObject monster = objectAt(g.levelMonsters, row, col)!;
  return monster.ichar == 'X' && monster.identified != 0;
}

void sting(GameObject monster) {
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
    message("the ${monsterName(monster)}'s bite has weakened you", 0);
    rogue.strengthCurrent -= 1;
    printStats();
  }
}

void drainLevel() {
  if (!randPercent(20) || rogue.exp < 8) {
    return;
  }

  rogue.expPoints = levelPoints[rogue.exp - 2] - getRand(10, 50);
  rogue.exp -= 2;
  addExp(1);
}

void drainLife() {
  if (!randPercent(25) || rogue.hpMax <= 30 || rogue.hpCurrent < 10) {
    return;
  }

  message("you feel weaker", 0);
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

bool mConfuse(GameObject monster) {
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
    message("the gaze of the ${monsterName(monster)} has confused you", 1);
    confuse();
    return true;
  }

  return false;
}

bool flameBroil(GameObject monster) {
  if (!randPercent(50)) {
    return false;
  }

  int row = monster.row, col = monster.col;
  if (!canSee(row, col)) {
    return false;
  }

  if (!rogueIsAround(row, col)) {
    Tuple2<int, int> pos = getCloser(row, col, rogue.row, rogue.col);
    row = pos.item1;
    col = pos.item2;

    ui.move(row, col);
    ui.write('*', inverse: true);

    while (row != rogue.row || col != rogue.col) {
      pos = getCloser(row, col, rogue.row, rogue.col);
      row = pos.item1;
      col = pos.item2;

      if (row == rogue.row && col == rogue.col) break;

      ui.move(row, col);
      ui.write('*', inverse: true);
      ui.refresh();
    }

    row = monster.row;
    col = monster.col;
    pos = getCloser(row, col, rogue.row, rogue.col);
    row = pos.item1;
    col = pos.item2;

    while (row != rogue.row || col != rogue.col) {
      ui.move(row, col);
      ui.write(getRoomChar(screen[row][col], row, col));
      ui.refresh();

      pos = getCloser(row, col, rogue.row, rogue.col);
      row = pos.item1;
      col = pos.item2;

      if (row == rogue.row && col == rogue.col) break;
    }
  }

  monsterHit(monster, "flame");
  return true;
}

Tuple2<int, int> getCloser(int row, int col, int trow, int tcol) {
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

  return Tuple2(row, col);
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}
