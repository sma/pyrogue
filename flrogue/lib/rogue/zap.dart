import 'globals.dart';
import 'hit.dart';
import 'level.dart';
import 'message.dart';
import 'monster.dart';
import 'move.dart';
import 'object.dart';
import 'pack.dart';
import 'room.dart';
import 'special_hit.dart';
import 'ui.dart';

Future<void> zapp() async {
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

  String wch = await getPackLetter("zap with what?", Cell.wand);
  if (wch == cancel) {
    checkMessage();
    return;
  }

  GameObject? wand = getLetterObject(wch);
  if (wand == null) {
    await message("no such item.");
    return;
  }

  if (wand.whatIs != Cell.wand) {
    await message("you can't zap with that");
    return;
  }

  if (wand.clasz <= 0) {
    await message("nothing happens");
  } else {
    wand.clasz -= 1;

    GameObject? monster = _getZappedMonster(dir, rogue.row, rogue.col);
    if (monster != null) {
      wakeUp(monster);
      await _zapMonster(monster, WandType.values[wand.whichKind]);
    }
  }

  await registerMove();
}

GameObject? _getZappedMonster(String dir, int row, int col) {
  while (true) {
    var (r, c) = getDirRc(dir, row, col);

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

Future<void> _zapMonster(GameObject monster, WandType kind) async {
  int row = monster.row;
  int col = monster.col;

  switch (kind) {
    case WandType.slowMonster:
      if (monster.flagsIs(MonsterFlags.hasted)) {
        monster.flagsRemove(MonsterFlags.hasted);
      } else {
        monster.quiver = 0;
        monster.flagsAdd(MonsterFlags.slowed);
      }
    case WandType.hasteMonster:
      if (monster.flagsIs(MonsterFlags.slowed)) {
        monster.flagsRemove(MonsterFlags.slowed);
      } else {
        monster.flagsAdd(MonsterFlags.hasted);
      }
    case WandType.teleportAway:
      _teleportAway(monster);
    case WandType.killMonster:
      rogue.expPoints -= monster.killExp;
      await monsterDamage(monster, monster.quantity);
    case WandType.invisibility:
      monster.flagsAdd(MonsterFlags.isInvis);
      ui.move(row, col).write(getMonsterChar(monster));
    case WandType.polymorph:
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
        ui.move(row, col).write(getMonsterChar(newMonster));
      }
    case WandType.putToSleep:
      monster.flagsAdd(MonsterFlags.isAsleep);
      monster.flagsRemove(MonsterFlags.wakens);
    case WandType.doNothing:
      await message("nothing happens");
  }

  // Set wand as identified
  if (idWands[kind.index].idStatus != IdStatus.called) {
    idWands[kind.index].idStatus = IdStatus.identified;
  }
}

void _teleportAway(GameObject monster) {
  if (monster.ichar == 'F') {
    beingHeld = false;
  }

  var (row, col) = getRandRowCol(Cell.floor | Cell.tunnel | Cell.isObject);

  removeMask(monster.row, monster.col, Cell.monster);

  ui
      .move(monster.row, monster.col)
      .write(
        getRoomChar(screen[monster.row][monster.col], monster.row, monster.col),
      );

  monster.row = row;
  monster.col = col;
  addMask(row, col, Cell.monster);

  if (canSee(row, col)) {
    ui.move(row, col).write(getMonsterChar(monster));
  }
}
