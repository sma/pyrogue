import 'package:flrogue/rogue/level.dart';
import 'package:flrogue/rogue/move.dart';
import 'package:flrogue/rogue/object.dart';
import 'package:flrogue/rogue/pack.dart';

import 'globals.dart';
import 'monster.dart';
import 'message.dart';
import 'ui.dart';
import 'room.dart';
import 'score.dart';
import 'special_hit.dart';

// Check if a character is a direction
bool isDirection(String ch) {
  return ch == 'h' ||
      ch == 'j' ||
      ch == 'k' ||
      ch == 'l' ||
      ch == 'y' ||
      ch == 'u' ||
      ch == 'n' ||
      ch == 'b' ||
      ch == cancel;
}

void monsterHit(GameObject monster, String? other) {
  if (g.fightMonster != null && monster != g.fightMonster) {
    g.fightMonster = null;
  }
  monster.trow = -1;

  int hitChance = monster.clasz;
  hitChance -= rogue.exp + rogue.exp;
  if (hitChance < 0) hitChance = 0;

  if (g.fightMonster == null) {
    g.interrupted = 1;
  }

  String mn = monsterName(monster);

  if (!randPercent(hitChance)) {
    if (g.fightMonster == null) {
      g.hitMessage += "the ${other ?? mn} misses";
      message(g.hitMessage, 0);
      g.hitMessage = "";
    }
    return;
  }

  if (g.fightMonster == null) {
    g.hitMessage += "the ${other ?? mn} hit";
    message(g.hitMessage, 0);
    g.hitMessage = "";
  }

  int damage;
  if (monster.ichar != 'F') {
    damage = getDamage(monster.damage, 1);
    double minus = (getArmorClass(rogue.armor) * 3.0) / 100.0 * damage;
    damage -= minus.toInt();
  } else {
    damage = monster.identified;
    monster.identified += 1;
  }

  if (damage > 0) {
    rogueDamage(damage, monster);
  }

  specialHit(monster);
}

void rogueHit(GameObject monster) {
  if (checkXeroc(monster)) {
    return;
  }

  int hitChance = getHitChance(rogue.weapon);
  if (!randPercent(hitChance)) {
    if (g.fightMonster == null) {
      g.hitMessage = "you miss  ";
    }
    checkOrc(monster);
    wakeUp(monster);
    return;
  }

  int damage = getWeaponDamage(rogue.weapon);
  if (monsterDamage(monster, damage)) {
    // still alive?
    if (g.fightMonster == null) {
      g.hitMessage = "you hit  ";
    }
  }

  checkOrc(monster);
  wakeUp(monster);
}

void rogueDamage(int d, GameObject monster) {
  if (d >= rogue.hpCurrent) {
    rogue.hpCurrent = 0;
    printStats();
    killedBy(monster, DeathCause.hypothermia);
  }
  rogue.hpCurrent -= d;
  printStats();
}

int getDamage(String ds, int r) {
  int total = 0;
  int i = 0;

  while (i < ds.length) {
    int n = getNumber(ds.substring(i));
    while (i < ds.length && ds[i] != 'd') {
      i++;
    }
    i++;
    int d = getNumber(ds.substring(i));
    while (i < ds.length && ds[i] != '/') {
      i++;
    }
    for (int j = 0; j < n; j++) {
      if (r != 0) {
        total += getRand(1, d);
      } else {
        total += d;
      }
    }
    if (i < ds.length && ds[i] == '/') {
      i++;
    }
  }
  return total;
}

int getWDamage(GameObject? obj) {
  if (obj == null) {
    return -1;
  }

  int toHit = getNumber(obj.damage) + obj.toHitEnchantment;
  int i = 0;

  while (i < obj.damage.length && obj.damage[i] != 'd') {
    i++;
  }
  i++;

  int damage = getNumber(obj.damage.substring(i)) + obj.damageEnchantment;

  return getDamage("${toHit}d$damage", 1);
}

int getNumber(String s) {
  int total = 0;
  int i = 0;

  while (i < s.length &&
      s[i].codeUnitAt(0) >= '0'.codeUnitAt(0) &&
      s[i].codeUnitAt(0) <= '9'.codeUnitAt(0)) {
    total = 10 * total + (s[i].codeUnitAt(0) - '0'.codeUnitAt(0));
    i++;
  }

  return total;
}

int toHit(GameObject? obj) {
  if (obj == null) {
    return 1;
  }
  return getNumber(obj.damage) + obj.toHitEnchantment;
}

int damageForStrength(int s) {
  if (s <= 6) return s - 5;
  if (s <= 14) return 1;
  if (s <= 17) return 3;
  if (s <= 18) return 4;
  if (s <= 20) return 5;
  if (s <= 21) return 6;
  if (s <= 30) return 7;
  return 8;
}

bool monsterDamage(GameObject monster, int damage) {
  monster.quantity -= damage;

  if (monster.quantity <= 0) {
    int row = monster.row;
    int col = monster.col;
    removeMask(row, col, Cell.monster);
    ui.move(row, col);
    ui.write(getRoomChar(screen[row][col], row, col));
    ui.refresh();

    g.fightMonster = null;
    coughUp(monster);
    g.hitMessage += "defeated the ${monsterName(monster)}";
    message(g.hitMessage, 1);
    g.hitMessage = "";
    addExp(monster.killExp);
    printStats();
    removeFromPack(monster, g.levelMonsters);

    if (monster.ichar == 'F') {
      g.beingHeld = 0;
    }

    return false;
  }
  return true;
}

Future<void> fight(bool toTheDeath) async {
  int firstMiss = 1;
  String ch = await ui.getchar();

  while (!isDirection(ch)) {
    ui.beep();
    if (firstMiss == 1) {
      message("direction?", 0);
      firstMiss = 0;
    }
    ch = await ui.getchar();
  }

  checkMessage();
  if (ch == cancel) {
    return;
  }

  var rowCol = getDirRc(ch, rogue.row, rogue.col);
  int row = rowCol.item1;
  int col = rowCol.item2;

  if (!(screen[row][col] & Cell.monster != 0) ||
      g.blind != 0 ||
      hidingXeroc(row, col)) {
    message("I see no monster there", 0);
    return;
  }

  g.fightMonster = objectAt(g.levelMonsters, row, col);
  if (g.fightMonster!.mFlags & MonsterFlags.isInvis != 0 &&
      g.detectMonster == 0) {
    message("I see no monster there", 0);
    return;
  }

  int possibleDamage = getDamage(g.fightMonster!.damage, 0) * 2 ~/ 3;

  while (g.fightMonster != null) {
    await singleMoveRogue(ch, 0);
    if (!toTheDeath && rogue.hpCurrent <= possibleDamage) {
      g.fightMonster = null;
    }
    if (!(screen[row][col] & Cell.monster != 0) || g.interrupted != 0) {
      g.fightMonster = null;
    }
  }
}

Tuple2<int, int> getDirRc(String dir, int row, int col) {
  if (dir == 'h' || dir == 'y' || dir == 'b') {
    if (col > 0) col -= 1;
  }
  if (dir == 'j' || dir == 'n' || dir == 'b') {
    if (row < ui.rows - 2) row += 1;
  }
  if (dir == 'k' || dir == 'y' || dir == 'u') {
    if (row > minRow) row -= 1;
  }
  if (dir == 'l' || dir == 'u' || dir == 'n') {
    if (col < ui.cols - 1) col += 1;
  }
  return Tuple2(row, col);
}

int getHitChance(GameObject? weapon) {
  int hitChance = 40;
  hitChance += 3 * toHit(weapon);
  hitChance += (rogue.exp + rogue.exp);
  if (hitChance > 100) hitChance = 100;
  return hitChance;
}

int getWeaponDamage(GameObject? weapon) {
  int damage = getWDamage(weapon);
  damage += damageForStrength(rogue.strengthCurrent);
  damage += (rogue.exp + 1) ~/ 2;
  return damage;
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}
