import 'package:flrogue/rogue/level.dart';
import 'package:flrogue/rogue/move.dart';
import 'package:flrogue/rogue/object.dart';
import 'package:flrogue/rogue/room.dart';

import 'globals.dart';
import 'hit.dart';
import 'message.dart';
import 'ui.dart';
import 'pack.dart';
import 'monster.dart';
import 'special_hit.dart';

Future<void> zapp() async {
  int firstMiss = 1;

  String dir = await ui.getchar();
  while (!isDirection(dir)) {
    ui.beep();
    if (firstMiss != 0) {
      await message("direction? ", 0);
      firstMiss = 0;
    }
    dir = await ui.getchar();
  }

  if (dir == cancel) {
    checkMessage();
    return;
  }

  String wch = await getPackLetter("zap with what? ", Cell.wand);
  if (wch == cancel) {
    checkMessage();
    return;
  }

  GameObject? wand = getLetterObject(wch);
  if (wand == null) {
    await message("no such item.", 0);
    return;
  }

  if (wand.whatIs != Cell.wand) {
    await message("you can't zap with that", 0);
    return;
  }

  if (wand.clasz <= 0) {
    await message("nothing happens", 0);
  } else {
    wand.clasz -= 1;

    GameObject? monster = getZappedMonster(dir, rogue.row, rogue.col);
    if (monster != null) {
      wakeUp(monster);
      await zapMonster(monster, wand.whichKind);
    }
  }

  await registerMove();
}

GameObject? getZappedMonster(String dir, int row, int col) {
  while (true) {
    var pos = getDirRc(dir, row, col);
    int r = pos.item1;
    int c = pos.item2;

    if ((row == r && col == c) ||
        screen[r][c] & (Cell.horWall | Cell.vertWall) != 0 ||
        screen[r][c] == Cell.blank) {
      return null;
    }

    if (screen[r][c] & Cell.monster != 0) {
      if (!hidingXeroc(r, c)) {
        return objectAt(levelMonsters, r, c);
      }
    }

    row = r;
    col = c;
  }
}

Future<void> zapMonster(GameObject monster, int kind) async {
  int row = monster.row;
  int col = monster.col;

  if (kind == WandType.slowMonster.index) {
    if (monster.mFlags & MonsterFlags.hasted != 0) {
      monster.mFlags &= ~MonsterFlags.hasted;
    } else {
      monster.quiver = 0;
      monster.mFlags |= MonsterFlags.slowed;
    }
  } else if (kind == WandType.hasteMonster.index) {
    if (monster.mFlags & MonsterFlags.slowed != 0) {
      monster.mFlags &= ~MonsterFlags.slowed;
    } else {
      monster.mFlags |= MonsterFlags.hasted;
    }
  } else if (kind == WandType.teleportAway.index) {
    teleportAway(monster);
  } else if (kind == WandType.killMonster.index) {
    rogue.expPoints -= monster.killExp;
    await monsterDamage(monster, monster.quantity);
  } else if (kind == WandType.invisibility.index) {
    monster.mFlags |= MonsterFlags.isInvis;
    ui.move(row, col);
    ui.write(getMonsterChar(monster));
  } else if (kind == WandType.polymorph.index) {
    if (monster.ichar == 'F') {
      beingHeld = false;
    }

    GameObject newMonster;
    while (true) {
      newMonster = monsterTab[getRand(0, monsterCount - 1)].copy();
      if (!(newMonster.ichar == 'X' &&
          (currentLevel < xeroc1 || currentLevel > xeroc2))) {
        break;
      }
    }

    newMonster.whatIs = Cell.monster;
    newMonster.row = row;
    newMonster.col = col;
    int i = levelMonsters.indexOf(monster);
    levelMonsters[i] = newMonster;

    wakeUp(newMonster);

    if (canSee(row, col)) {
      ui.move(row, col);
      ui.write(getMonsterChar(newMonster));
    }
  } else if (kind == WandType.putToSleep.index) {
    monster.mFlags |= MonsterFlags.isAsleep;
    monster.mFlags &= ~MonsterFlags.wakens;
  } else if (kind == WandType.doNothing.index) {
    await message("nothing happens", 0);
  }

  // Set wand as identified
  if (idWands[kind].idStatus != IdStatus.called) {
    idWands[kind].idStatus = IdStatus.identified;
  }
}

void teleportAway(GameObject monster) {
  if (monster.ichar == 'F') {
    beingHeld = false;
  }

  var pos = getRandRowCol(Cell.floor | Cell.tunnel | Cell.isObject);
  int row = pos.item1;
  int col = pos.item2;

  removeMask(monster.row, monster.col, Cell.monster);

  ui.move(monster.row, monster.col);
  ui.write(
    getRoomChar(screen[monster.row][monster.col], monster.row, monster.col),
  );

  monster.row = row;
  monster.col = col;
  addMask(row, col, Cell.monster);

  if (canSee(row, col)) {
    ui.move(row, col);
    ui.write(getMonsterChar(monster));
  }
}
