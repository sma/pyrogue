import 'globals.dart';
import 'hit.dart';
import 'level.dart';
import 'message.dart';
import 'move.dart';
import 'object.dart';
import 'pack.dart';
import 'room.dart';
import 'special_hit.dart';
import 'ui.dart';

void putMonsters() {
  int n = getRand(3, 7);

  for (int i = 0; i < n; i++) {
    GameObject monster = _getRandMonster();
    if (monster.flagsIs(MonsterFlags.wanders) && randPercent(50)) {
      wakeUp(monster);
    }
    _putMonsterRandLocation(monster);
    addToPack(monster, levelMonsters, false);
  }
}

GameObject _getRandMonster() {
  GameObject monster = getAnObject();

  int mn;
  while (true) {
    mn = getRand(0, monsterCount - 1);
    if (currentLevel >= monsterTab[mn].isProtected &&
        currentLevel <= monsterTab[mn].isCursed) {
      break;
    }
  }

  monster = monsterTab[mn].copy();
  monster.whatIs = Cell.monster;

  if (monster.ichar == 'X') {
    monster.identified = getRandObjChar().ascii;
  }

  if (currentLevel > amuletLevel + 2) {
    monster.flagsAdd(MonsterFlags.hasted);
  }

  monster.trow = -1;
  return monster;
}

Future<void> moveMonsters() async {
  for (GameObject monster in levelMonsters.toList()) {
    if (monster.flagsIs(MonsterFlags.hasted)) {
      await mvMonster(monster, rogue.row, rogue.col);
    } else if (monster.flagsIs(MonsterFlags.slowed)) {
      monster.quiver = monster.quiver == 0 ? 1 : 0;
      if (monster.quiver != 0) {
        continue;
      }
    }

    bool flew = false;
    if (monster.flagsIs(MonsterFlags.flies) &&
        !monsterCanGo(monster, rogue.row, rogue.col)) {
      flew = true;
      await mvMonster(monster, rogue.row, rogue.col);
    }

    if (!flew || !monsterCanGo(monster, rogue.row, rogue.col)) {
      await mvMonster(monster, rogue.row, rogue.col);
    }
  }
}

void fillRoomWithMonsters(int rn, int n) {
  Room r = rooms[rn];

  for (int i = 0; i < n + n ~/ 2; i++) {
    if (noRoomForMonster(rn)) break;

    int row, col;
    while (true) {
      row = getRand(r.topRow + 1, r.bottomRow - 1);
      col = getRand(r.leftCol + 1, r.rightCol - 1);
      if (!(screen[row][col] & Cell.monster != 0)) break;
    }

    _putMonsterAt(row, col, _getRandMonster());
  }
}

String getMonsterCharRowCol(int row, int col) {
  GameObject monster = objectAt(levelMonsters, row, col)!;

  if ((!detectMonster && monster.flagsIs(MonsterFlags.isInvis)) || blind != 0) {
    return getRoomChar(screen[row][col] & ~Cell.monster, row, col);
  }

  if (monster.ichar == 'X' && monster.identified != 0) {
    return String.fromCharCode(monster.identified);
  }

  return monster.ichar;
}

String getMonsterChar(GameObject monster) {
  if ((!detectMonster && monster.flagsIs(MonsterFlags.isInvis)) || blind != 0) {
    return getRoomChar(
      screen[monster.row][monster.col] & ~Cell.monster,
      monster.row,
      monster.col,
    );
  }

  if (monster.ichar == 'X' && monster.identified != 0) {
    return String.fromCharCode(monster.identified);
  }

  return monster.ichar;
}

Future<void> mvMonster(GameObject monster, int row, int col) async {
  if (monster.flagsIs(MonsterFlags.isAsleep)) {
    if (monster.flagsIs(MonsterFlags.wakens) &&
        rogueIsAround(monster.row, monster.col) &&
        randPercent(wakePercent)) {
      wakeUp(monster);
    }
    return;
  }

  if (monster.flagsIs(MonsterFlags.flits) && _flit(monster)) {
    return;
  }

  if (monster.ichar == 'F' && !monsterCanGo(monster, rogue.row, rogue.col)) {
    return;
  }

  if (monster.ichar == 'I' && monster.identified == 0) {
    return;
  }

  if (monster.ichar == 'M' && !(await mConfuse(monster))) {
    return;
  }

  if (monsterCanGo(monster, rogue.row, rogue.col)) {
    await monsterHit(monster, null);
    return;
  }

  if (monster.ichar == 'D' && await flameBroil(monster)) {
    return;
  }

  if (monster.ichar == 'O' && await orcGold(monster)) {
    return;
  }

  if (monster.trow == monster.row && monster.tcol == monster.col) {
    monster.trow = -1;
  } else if (monster.trow != -1) {
    row = monster.trow;
    col = monster.tcol;
  }

  if (monster.row > row) {
    row = monster.row - 1;
  } else if (monster.row < row) {
    row = monster.row + 1;
  }

  if (screen[row][monster.col] & Cell.door != 0 &&
      _mtry(monster, row, monster.col)) {
    return;
  }

  if (monster.col > col) {
    col = monster.col - 1;
  } else if (monster.col < col) {
    col = monster.col + 1;
  }

  if (screen[monster.row][col] & Cell.door != 0 &&
      _mtry(monster, monster.row, col)) {
    return;
  }

  if (_mtry(monster, row, col)) {
    return;
  }

  List<bool> tried = List.filled(6, false);
  for (int i = 0; i < 6; i++) {
    int n = getRand(0, 5);
    if (n == 0) {
      if (!tried[n] && _mtry(monster, row, monster.col - 1)) {
        return;
      }
    } else if (n == 1) {
      if (!tried[n] && _mtry(monster, row, monster.col)) {
        return;
      }
    } else if (n == 2) {
      if (!tried[n] && _mtry(monster, row, monster.col + 1)) {
        return;
      }
    } else if (n == 3) {
      if (!tried[n] && _mtry(monster, monster.row - 1, col)) {
        return;
      }
    } else if (n == 4) {
      if (!tried[n] && _mtry(monster, monster.row, col)) {
        return;
      }
    } else if (n == 5) {
      if (!tried[n] && _mtry(monster, monster.row + 1, col)) {
        return;
      }
    }
    tried[n] = true;
  }
}

bool _mtry(GameObject monster, int row, int col) {
  if (monsterCanGo(monster, row, col)) {
    moveMonsterTo(monster, row, col);
    return true;
  }
  return false;
}

void moveMonsterTo(GameObject monster, int row, int col) {
  addMask(row, col, Cell.monster);
  removeMask(monster.row, monster.col, Cell.monster);

  String c = ui.read(monster.row, monster.col, 1);

  if (c.between('A', 'Z')) {
    ui.move(monster.row, monster.col);
    ui.write(
      getRoomChar(screen[monster.row][monster.col], monster.row, monster.col),
    );
  }

  if (blind == 0 && (detectMonster || canSee(row, col))) {
    if (monster.flagsIsnt(MonsterFlags.isInvis) || detectMonster) {
      ui.move(row, col);
      ui.write(getMonsterChar(monster));
    }
  }

  if (screen[row][col] & Cell.door != 0 &&
      getRoomNumber(row, col) != currentRoom &&
      screen[monster.row][monster.col] == Cell.floor) {
    if (blind == 0) {
      ui.move(monster.row, monster.col);
      ui.write(' ');
    }
  }

  if (screen[row][col] & Cell.door != 0) {
    doorCourse(
      monster,
      screen[monster.row][monster.col] & Cell.tunnel != 0,
      row,
      col,
    );
  } else {
    monster.row = row;
    monster.col = col;
  }
}

bool monsterCanGo(GameObject monster, int row, int col) {
  int dr = monster.row - row;
  if (dr <= -2 || dr >= 2) return false;

  int dc = monster.col - col;
  if (dc <= -2 || dc >= 2) return false;

  if (!(screen[monster.row][col] != 0) || !(screen[row][monster.col] != 0)) {
    return false;
  }

  if (!isPassable(row, col) || screen[row][col] & Cell.monster != 0) {
    return false;
  }

  if (monster.row != row &&
      monster.col != col &&
      (screen[row][col] & Cell.door != 0 ||
          screen[monster.row][monster.col] & Cell.door != 0)) {
    return false;
  }

  if (monster.flagsIsnt(MonsterFlags.flits) &&
      monster.flagsIsnt(MonsterFlags.canGo) &&
      monster.trow == -1) {
    if (monster.row < rogue.row && row < monster.row) return false;
    if (monster.row > rogue.row && row > monster.row) return false;
    if (monster.col < rogue.col && col < monster.col) return false;
    if (monster.col > rogue.col && col > monster.col) return false;
  }

  if (screen[row][col] & Cell.scroll != 0) {
    GameObject obj = objectAt(levelObjects, row, col)!;
    if (obj.whichKind == ScrollType.scareMonster.index) {
      return false;
    }
  }

  return true;
}

void wakeUp(GameObject monster) {
  monster.flagsRemove(MonsterFlags.isAsleep);
}

void wakeRoom(int rn, bool entering, int row, int col) {
  int wakePercent_ = rn == partyRoom ? partyWakePercent : wakePercent;

  for (GameObject monster in levelMonsters) {
    if ((monster.flagsIs(MonsterFlags.wakens) || rn == partyRoom) &&
        rn == getRoomNumber(monster.row, monster.col)) {
      if (monster.ichar == 'X' && rn == partyRoom) {
        monster.flagsAdd(MonsterFlags.wakens);
      }

      if (entering) {
        monster.trow = -1;
      } else {
        monster.trow = row;
        monster.tcol = col;
      }

      if (randPercent(wakePercent_) && monster.flagsIs(MonsterFlags.wakens)) {
        if (monster.ichar != 'X') {
          wakeUp(monster);
        }
      }
    }
  }
}

String monsterName(GameObject monster) {
  if (blind != 0 || (monster.flagsIs(MonsterFlags.isInvis) && !detectMonster)) {
    return "something";
  }

  if (halluc != 0) {
    return monsterNames[getRand(0, 25)];
  }

  return monsterNames[monster.ichar.ascii - 'A'.ascii];
}

bool rogueIsAround(int row, int col) {
  int rdif = (row - rogue.row).abs();
  int cdif = (col - rogue.col).abs();
  return rdif < 2 && cdif < 2;
}

void startWanderer() {
  GameObject monster;

  while (true) {
    monster = _getRandMonster();
    if (monster.flagsIs(MonsterFlags.wakens) ||
        monster.flagsIs(MonsterFlags.wanders)) {
      break;
    }
  }

  wakeUp(monster);

  for (int i = 0; i < 12; i++) {
    var (row, col) = getRandRowCol(Cell.floor | Cell.tunnel | Cell.isObject);

    if (!canSee(row, col)) {
      _putMonsterAt(row, col, monster);
      return;
    }
  }
}

void showMonsters() {
  if (blind != 0) return;

  for (GameObject monster in levelMonsters) {
    ui.move(monster.row, monster.col);
    ui.write(monster.ichar);

    if (monster.ichar == 'X') {
      monster.identified = 0;
    }
  }
}

Future<void> createMonster() async {
  int inc1 = getRand(0, 1) != 0 ? 1 : -1;
  int inc2 = getRand(0, 1) != 0 ? 1 : -1;

  bool found = false;
  int row = 0, col = 0;

  for (int i = inc1; i != 2 * -inc1; i -= inc1) {
    for (int j = inc2; j != 2 * -inc2; j -= inc2) {
      if (i == 0 && j == 0) continue;

      row = rogue.row + i;
      col = rogue.col + j;

      if (row < minRow || row > ui.rows - 2 || col < 0 || col > ui.cols - 1) {
        continue;
      }

      if (!(screen[row][col] & Cell.monster != 0) &&
          screen[row][col] & (Cell.floor | Cell.tunnel | Cell.stairs) != 0) {
        found = true;
        break;
      }
    }
    if (found) break;
  }

  if (found) {
    GameObject monster = _getRandMonster();
    _putMonsterAt(row, col, monster);

    ui.move(row, col);
    ui.write(getMonsterChar(monster));

    if (monster.flagsIs(MonsterFlags.wanders)) {
      wakeUp(monster);
    }
  } else {
    await message("you hear a faint cry of anguish in the distance");
  }
}

void _putMonsterAt(int row, int col, GameObject monster) {
  monster.row = row;
  monster.col = col;
  addMask(row, col, Cell.monster);
  addToPack(monster, levelMonsters, false);
}

bool canSee(int row, int col) {
  return blind == 0 &&
      (getRoomNumber(row, col) == currentRoom || rogueIsAround(row, col));
}

bool _flit(GameObject monster) {
  if (!randPercent(flitPercent)) {
    return false;
  }

  int inc1 = getRand(0, 1) != 0 ? 1 : -1;
  int inc2 = getRand(0, 1) != 0 ? 1 : -1;

  if (randPercent(10)) {
    return true;
  }

  for (int i = inc1; i != 2 * -inc1; i -= inc1) {
    for (int j = inc2; j != 2 * -inc2; j -= inc2) {
      int row = monster.row + i;
      int col = monster.col + j;

      if (row == rogue.row && col == rogue.col) {
        continue;
      }

      if (_mtry(monster, row, col)) {
        return true;
      }
    }
  }

  return true;
}

void _putMonsterRandLocation(GameObject monster) {
  var (row, col) = getRandRowCol(Cell.floor | Cell.tunnel | Cell.isObject);

  addMask(row, col, Cell.monster);
  monster.row = row;
  monster.col = col;
}

String getRandObjChar() {
  return "%!?]/):*"[getRand(0, 7)];
}

bool noRoomForMonster(int rn) {
  Room r = rooms[rn];

  for (int i = r.leftCol + 1; i < r.rightCol; i++) {
    for (int j = r.topRow + 1; j < r.bottomRow; j++) {
      if (!(screen[j][i] & Cell.monster != 0)) {
        return false;
      }
    }
  }

  return true;
}

Future<void> aggravate() async {
  await message("you hear a high pitched humming noise");

  for (GameObject monster in levelMonsters) {
    wakeUp(monster);
    if (monster.ichar == 'X') {
      monster.identified = 0;
    }
  }
}

bool monsterCanSee(GameObject monster, int row, int col) {
  int rn = getRoomNumber(row, col);

  if (rn != noRoom && rn == getRoomNumber(monster.row, monster.col)) {
    return true;
  }

  return (row - monster.row).abs() < 2 && (col - monster.col).abs() < 2;
}

Future<void> mvAquatars() async {
  for (GameObject monster in levelMonsters) {
    if (monster.ichar == 'A') {
      await mvMonster(monster, rogue.row, rogue.col);
    }
  }
}

void doorCourse(GameObject monster, bool entering, int row, int col) {
  monster.row = row;
  monster.col = col;

  if (monsterCanSee(monster, rogue.row, rogue.col)) {
    monster.trow = -1;
    return;
  }

  int rn = getRoomNumber(row, col);

  if (entering) {
    for (int i = 0; i < maxRooms; i++) {
      if (!rooms[i].isRoom || i == rn) continue;

      for (int j = 0; j < 4; j++) {
        Door d = rooms[i].doors[j];
        if (d.otherRoom == rn) {
          monster.trow = d.otherRow;
          monster.tcol = d.otherCol;

          if (monster.trow == row && monster.tcol == col) {
            continue;
          }

          return;
        }
      }
    }
  } else {
    var (b, rrow, ccol) = getOtherRoom(rn, row, col);

    if (b) {
      monster.trow = rrow;
      monster.tcol = ccol;
    } else {
      monster.trow = -1;
    }
  }
}

(bool, int, int) getOtherRoom(int rn, int row, int col) {
  int d = -1;

  if (screen[row][col - 1] & Cell.horWall != 0 &&
      screen[row][col + 1] & Cell.horWall != 0) {
    if (screen[row + 1][col] & Cell.floor != 0) {
      d = Direction.up.index ~/ 2;
    } else {
      d = Direction.down.index ~/ 2;
    }
  } else {
    if (screen[row][col + 1] & Cell.floor != 0) {
      d = Direction.left.index ~/ 2;
    } else {
      d = Direction.right.index ~/ 2;
    }
  }

  if (d != -1 && rooms[rn].doors[d].otherRoom > 0) {
    return (true, rooms[rn].doors[d].otherRow, rooms[rn].doors[d].otherCol);
  }

  return (false, 0, 0);
}
