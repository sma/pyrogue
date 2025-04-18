import 'globals.dart';
import 'level.dart';
import 'message.dart';
import 'monster.dart';
import 'move.dart';
import 'object.dart';
import 'pack.dart';
import 'room.dart';
import 'score.dart';
import 'special_hit.dart';
import 'ui.dart';

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

Future<void> monsterHit(GameObject monster, String? other) async {
  if (fightMonster != null && monster != fightMonster) {
    fightMonster = null;
  }
  monster.trow = -1;

  int hitChance = monster.clasz;
  hitChance -= rogue.exp + rogue.exp;
  if (hitChance < 0) hitChance = 0;

  if (fightMonster == null) {
    interrupted = true;
  }

  String mn = monsterName(monster);

  if (!randPercent(hitChance)) {
    if (fightMonster == null) {
      hitMessage += "the ${other ?? mn} misses";
      await message(hitMessage);
      hitMessage = "";
    }
    return;
  }

  if (fightMonster == null) {
    hitMessage += "the ${other ?? mn} hit";
    await message(hitMessage);
    hitMessage = "";
  }

  int damage;
  if (monster.ichar != 'F') {
    damage = _getDamage(monster.damage, true);
    double minus = (getArmorClass(rogue.armor) * 3.0) / 100.0 * damage;
    damage -= minus.toInt();
  } else {
    damage = monster.identified;
    monster.identified += 1;
  }

  if (damage > 0) {
    await _rogueDamage(damage, monster);
  }

  await specialHit(monster);
}

Future<void> rogueHit(GameObject monster) async {
  if (await checkXeroc(monster)) {
    return;
  }

  int hitChance = getHitChance(rogue.weapon);
  if (!randPercent(hitChance)) {
    if (fightMonster == null) {
      hitMessage = "you miss  ";
    }
    checkOrc(monster);
    wakeUp(monster);
    return;
  }

  int damage = getWeaponDamage(rogue.weapon);
  if (await monsterDamage(monster, damage)) {
    // still alive?
    if (fightMonster == null) {
      hitMessage = "you hit  ";
    }
  }

  checkOrc(monster);
  wakeUp(monster);
}

Future<void> _rogueDamage(int d, GameObject monster) async {
  if (d >= rogue.hpCurrent) {
    rogue.hpCurrent = 0;
    printStats();
    await killedBy(monster, DeathCause.monster);
  }
  rogue.hpCurrent -= d;
  printStats();
}

int _getDamage(String ds, bool r) {
  int total = 0;
  int i = 0;

  while (i < ds.length) {
    int n = _getNumber(ds.substring(i));
    while (i < ds.length && ds[i] != 'd') {
      i++;
    }
    i++;
    int d = _getNumber(ds.substring(i));
    while (i < ds.length && ds[i] != '/') {
      i++;
    }
    for (int j = 0; j < n; j++) {
      if (r) {
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

int _getWDamage(GameObject? obj) {
  if (obj == null) {
    return -1;
  }

  int toHit = _getNumber(obj.damage) + obj.toHitEnchantment;
  int i = 0;

  while (i < obj.damage.length && obj.damage[i] != 'd') {
    i++;
  }
  i++;

  int damage = _getNumber(obj.damage.substring(i)) + obj.damageEnchantment;

  return _getDamage("${toHit}d$damage", true);
}

int _getNumber(String s) {
  int total = 0;
  int i = 0;

  while (i < s.length && s[i].between('0', '9')) {
    total = 10 * total + (s[i].ascii - '0'.ascii);
    i++;
  }

  return total;
}

int _toHit(GameObject? obj) {
  if (obj == null) {
    return 1;
  }
  return _getNumber(obj.damage) + obj.toHitEnchantment;
}

int _damageForStrength(int s) {
  if (s <= 6) return s - 5;
  if (s <= 14) return 1;
  if (s <= 17) return 3;
  if (s <= 18) return 4;
  if (s <= 20) return 5;
  if (s <= 21) return 6;
  if (s <= 30) return 7;
  return 8;
}

Future<bool> monsterDamage(GameObject monster, int damage) async {
  monster.quantity -= damage;

  if (monster.quantity <= 0) {
    int row = monster.row;
    int col = monster.col;
    removeMask(row, col, Cell.monster);
    ui.move(row, col).write(getRoomChar(screen[row][col], row, col));
    ui.refresh();

    fightMonster = null;
    coughUp(monster);
    hitMessage += "defeated the ${monsterName(monster)}";
    await message(hitMessage, true);
    hitMessage = "";
    await addExp(monster.killExp);
    printStats();
    removeFromPack(monster, levelMonsters);

    if (monster.ichar == 'F') {
      beingHeld = false;
    }

    return false;
  }
  return true;
}

Future<void> fight(bool toTheDeath) async {
  bool firstMiss = true;
  String ch = await ui.getchar();

  while (!isDirection(ch)) {
    ui.beep();
    if (firstMiss) {
      await message("direction?");
      firstMiss = false;
    }
    ch = await ui.getchar();
  }

  checkMessage();
  if (ch == cancel) {
    return;
  }

  final (row, col) = getDirRc(ch, rogue.row, rogue.col);

  if (!(screen[row][col] & Cell.monster != 0) ||
      blind != 0 ||
      hidingXeroc(row, col)) {
    await message("I see no monster there");
    return;
  }

  fightMonster = objectAt(levelMonsters, row, col);
  if (fightMonster!.flagsIs(MonsterFlags.isInvis) && !detectMonster) {
    await message("I see no monster there");
    return;
  }

  int possibleDamage = _getDamage(fightMonster!.damage, false) * 2 ~/ 3;

  while (fightMonster != null) {
    await singleMoveRogue(ch, false);
    if (!toTheDeath && rogue.hpCurrent <= possibleDamage) {
      fightMonster = null;
    }
    if (!(screen[row][col] & Cell.monster != 0) || interrupted) {
      fightMonster = null;
    }
  }
}

(int, int) getDirRc(String dir, int row, int col) {
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
  return (row, col);
}

int getHitChance(GameObject? weapon) {
  int hitChance = 40;
  hitChance += 3 * _toHit(weapon);
  hitChance += (rogue.exp + rogue.exp);
  if (hitChance > 100) hitChance = 100;
  return hitChance;
}

int getWeaponDamage(GameObject? weapon) {
  int damage = _getWDamage(weapon);
  damage += _damageForStrength(rogue.strengthCurrent);
  damage += (rogue.exp + 1) ~/ 2;
  return damage;
}
