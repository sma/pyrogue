// rogue/throw.dart

import 'package:flrogue/rogue/level.dart';
import 'package:flrogue/rogue/object.dart';
import 'package:flrogue/rogue/use.dart';

import 'globals.dart';
import 'hit.dart';
import 'message.dart';
import 'ui.dart';
import 'pack.dart';
import 'room.dart';
import 'monster.dart';
import 'special_hit.dart';

Future<void> throwItem() async {
  bool firstMiss = true;

  String dir = await ui.getchar();
  while (!isDirection(dir)) {
    ui.beep();
    if (firstMiss) {
      await message("direction? ");
      firstMiss = false;
    }
    dir = await ui.getchar();
  }

  if (dir == cancel) {
    checkMessage();
    return;
  }

  String wch = await getPackLetter("throw what?", Cell.weapon);
  if (wch == cancel) {
    checkMessage();
    return;
  }

  checkMessage();

  GameObject? weapon = getLetterObject(wch);
  if (weapon == null) {
    await message("no such item.");
    return;
  }

  if (weapon.whatIs != Cell.weapon) {
    int k = getRand(0, 2);
    if (k == 0) {
      await message("if you don't want it, drop it!");
    } else if (k == 1) {
      await message("throwing that would do noone any good");
    } else {
      await message("why would you want to throw that?");
    }
    return;
  }

  if (weapon == rogue.weapon && weapon.isCursed != 0) {
    await message("you can't, it appears to be cursed");
    return;
  }

  var result = await getThrownAtMonster(dir, rogue.row, rogue.col);
  GameObject? monster = result.item1;
  int row = result.item2;
  int col = result.item3;

  ui.move(rogue.row, rogue.col);
  ui.write(rogue.fchar);
  ui.refresh();

  if (canSee(row, col) && (row != rogue.row || col != rogue.col)) {
    ui.move(row, col);
    ui.write(getRoomChar(screen[row][col], row, col));
  }

  if (monster != null) {
    wakeUp(monster);
    checkOrc(monster);

    if (!await throwAtMonster(monster, weapon)) {
      await flopWeapon(weapon, row, col);
    }
  } else {
    await flopWeapon(weapon, row, col);
  }

  await vanish(weapon, true);
}

Future<bool> throwAtMonster(GameObject monster, GameObject weapon) async {
  int hitChance = getHitChance(weapon);
  int t = weapon.quantity;
  weapon.quantity = 1;
  hitMessage = "the ${nameOf(weapon)}";
  weapon.quantity = t;

  if (!randPercent(hitChance)) {
    hitMessage += "misses  ";
    return false;
  }

  hitMessage += "hit  ";
  int damage = getWeaponDamage(weapon);

  if ((weapon.whichKind == WeaponType.arrow.index &&
          rogue.weapon != null &&
          rogue.weapon!.whichKind == WeaponType.bow.index) ||
      (weapon.whichKind == WeaponType.shuriken.index &&
          rogue.weapon == weapon)) {
    damage += getWeaponDamage(rogue.weapon);
    damage = damage * 2 ~/ 3;
  }

  await monsterDamage(monster, damage);
  return true;
}

Future<Tuple3<GameObject?, int, int>> getThrownAtMonster(
  String dir,
  int row,
  int col,
) async {
  int orow = row;
  int ocol = col;

  int i = 0;
  while (i < 24) {
    var pos = getDirRc(dir, row, col);
    row = pos.item1;
    col = pos.item2;

    if (screen[row][col] == Cell.blank ||
        screen[row][col] & (Cell.horWall | Cell.vertWall) != 0) {
      return Tuple3(null, orow, ocol);
    }

    if (i != 0 && canSee(orow, ocol)) {
      ui.move(orow, ocol);
      ui.write(getRoomChar(screen[orow][ocol], orow, ocol));
    }

    if (canSee(row, col)) {
      if (!(screen[row][col] & Cell.monster != 0)) {
        ui.move(row, col);
        ui.write(')');
      }
      ui.refresh();
    }

    orow = row;
    ocol = col;

    if (screen[row][col] & Cell.monster != 0) {
      if (!hidingXeroc(row, col)) {
        return Tuple3(objectAt(levelMonsters, row, col), row, col);
      }
    }

    if (screen[row][col] & Cell.tunnel != 0) {
      i += 2;
    }

    i += 1;
  }

  return Tuple3(null, row, col);
}

Future<bool> flopWeapon(GameObject weapon, int row, int col) async {
  int inc1 = getRand(0, 1) != 0 ? 1 : -1;
  int inc2 = getRand(0, 1) != 0 ? 1 : -1;

  int r = row;
  int c = col;

  bool found = false;

  if ((screen[r][c] & ~(Cell.floor | Cell.tunnel | Cell.door) != 0) ||
      (row == rogue.row && col == rogue.col)) {
    for (int i = inc1; i != 2 * -inc1; i -= inc1) {
      for (int j = inc2; j != 2 * -inc2; j -= inc2) {
        r = row + i;
        c = col + j;

        if (r > ui.rows - 2 || r < minRow || c > ui.cols - 1 || c < 0) {
          continue;
        }

        found = true;
        break;
      }
      if (found) break;
    }
  } else {
    found = true;
  }

  if (found) {
    GameObject newWeapon = getAnObject();
    newWeapon = weapon.copy();
    newWeapon.quantity = 1;
    newWeapon.row = r;
    newWeapon.col = c;
    addMask(r, c, Cell.weapon);
    addToPack(newWeapon, levelObjects, false);

    if (canSee(r, c)) {
      ui.move(r, c);
      ui.write(getRoomChar(screen[r][c], r, c));
    }
  } else {
    int t = weapon.quantity;
    weapon.quantity = 1;
    String msg = "the ${nameOf(weapon)}vanishes as it hits the ground";
    weapon.quantity = t;
    await message(msg);
  }

  return found;
}

class Tuple3<T1, T2, T3> {
  final T1 item1;
  final T2 item2;
  final T3 item3;

  Tuple3(this.item1, this.item2, this.item3);
}
