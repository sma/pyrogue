import 'package:flrogue/rogue/hit.dart';
import 'package:flrogue/rogue/level.dart';
import 'package:flrogue/rogue/move.dart';

import 'globals.dart';
import 'room.dart';
import 'ui.dart';
import 'object.dart';
import 'pack.dart';
import 'message.dart';
import 'special_hit.dart';

void putMonsters() {
  int n = getRand(3, 7);

  for (int i = 0; i < n; i++) {
    GameObject monster = getRandMonster();
    if (monster.mFlags & MonsterFlags.wanders != 0 && randPercent(50)) {
      wakeUp(monster);
    }
    putMonsterRandLocation(monster);
    addToPack(monster, levelMonsters, false);
  }
}

GameObject getRandMonster() {
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
    monster.identified = getRandObjChar().codeUnitAt(0);
  }

  if (currentLevel > amuletLevel + 2) {
    monster.mFlags |= MonsterFlags.hasted;
  }

  monster.trow = -1;
  return monster;
}

Future<void> moveMonsters() async {
  GameObject? monster = levelMonsters.nextObject;

  while (monster != null) {
    if (monster.mFlags & MonsterFlags.hasted != 0) {
      await mvMonster(monster, rogue.row, rogue.col);
    } else if (monster.mFlags & MonsterFlags.slowed != 0) {
      monster.quiver = monster.quiver == 0 ? 1 : 0;
      if (monster.quiver != 0) {
        monster = monster.nextObject;
        continue;
      }
    }

    bool flew = false;
    if (monster.mFlags & MonsterFlags.flies != 0 &&
        !monsterCanGo(monster, rogue.row, rogue.col)) {
      flew = true;
      await mvMonster(monster, rogue.row, rogue.col);
    }

    if (!flew || !monsterCanGo(monster, rogue.row, rogue.col)) {
      await mvMonster(monster, rogue.row, rogue.col);
    }

    monster = monster.nextObject;
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

    putMonsterAt(row, col, getRandMonster());
  }
}

String getMonsterCharRowCol(int row, int col) {
  GameObject monster = objectAt(levelMonsters, row, col)!;

  if ((detectMonster == 0 && monster.mFlags & MonsterFlags.isInvis != 0) ||
      blind != 0) {
    return getRoomChar(screen[row][col] & ~Cell.monster, row, col);
  }

  if (monster.ichar == 'X' && monster.identified != 0) {
    return String.fromCharCode(monster.identified);
  }

  return monster.ichar;
}

String getMonsterChar(GameObject monster) {
  if ((detectMonster == 0 && monster.mFlags & MonsterFlags.isInvis != 0) ||
      blind != 0) {
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
  if (monster.mFlags & MonsterFlags.isAsleep != 0) {
    if (monster.mFlags & MonsterFlags.wakens != 0 &&
        rogueIsAround(monster.row, monster.col) &&
        randPercent(wakePercent)) {
      wakeUp(monster);
    }
    return;
  }

  if (monster.mFlags & MonsterFlags.flits != 0 && flit(monster)) {
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
    await monsterHit(monster, "");
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
      mtry(monster, row, monster.col)) {
    return;
  }

  if (monster.col > col) {
    col = monster.col - 1;
  } else if (monster.col < col) {
    col = monster.col + 1;
  }

  if (screen[monster.row][col] & Cell.door != 0 &&
      mtry(monster, monster.row, col)) {
    return;
  }

  if (mtry(monster, row, col)) {
    return;
  }

  List<int> tried = List.filled(6, 0);
  for (int i = 0; i < 6; i++) {
    int n = getRand(0, 5);
    if (n == 0) {
      if (tried[n] == 0 && mtry(monster, row, monster.col - 1)) {
        return;
      }
    } else if (n == 1) {
      if (tried[n] == 0 && mtry(monster, row, monster.col)) {
        return;
      }
    } else if (n == 2) {
      if (tried[n] == 0 && mtry(monster, row, monster.col + 1)) {
        return;
      }
    } else if (n == 3) {
      if (tried[n] == 0 && mtry(monster, monster.row - 1, col)) {
        return;
      }
    } else if (n == 4) {
      if (tried[n] == 0 && mtry(monster, monster.row, col)) {
        return;
      }
    } else if (n == 5) {
      if (tried[n] == 0 && mtry(monster, monster.row + 1, col)) {
        return;
      }
    }
    tried[n] = 1;
  }
}

bool mtry(GameObject monster, int row, int col) {
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

  if (c.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
      c.codeUnitAt(0) <= 'Z'.codeUnitAt(0)) {
    ui.move(monster.row, monster.col);
    ui.write(
      getRoomChar(screen[monster.row][monster.col], monster.row, monster.col),
    );
  }

  if (blind == 0 && (detectMonster != 0 || canSee(row, col))) {
    if (monster.mFlags & MonsterFlags.isInvis == 0 || detectMonster != 0) {
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

  if (monster.mFlags & MonsterFlags.flits == 0 &&
      monster.mFlags & MonsterFlags.canGo == 0 &&
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
  monster.mFlags &= ~MonsterFlags.isAsleep;
}

void wakeRoom(int rn, bool entering, int row, int col) {
  int wakePercent_ = rn == partyRoom ? partyWakePercent : wakePercent;

  GameObject? monster = levelMonsters.nextObject;
  while (monster != null) {
    if ((monster.mFlags & MonsterFlags.wakens != 0 || rn == partyRoom) &&
        rn == getRoomNumber(monster.row, monster.col)) {
      if (monster.ichar == 'X' && rn == partyRoom) {
        monster.mFlags |= MonsterFlags.wakens;
      }

      if (entering) {
        monster.trow = -1;
      } else {
        monster.trow = row;
        monster.tcol = col;
      }

      if (randPercent(wakePercent_) &&
          monster.mFlags & MonsterFlags.wakens != 0) {
        if (monster.ichar != 'X') {
          wakeUp(monster);
        }
      }
    }
    monster = monster.nextObject;
  }
}

String monsterName(GameObject monster) {
  if (blind != 0 ||
      (monster.mFlags & MonsterFlags.isInvis != 0 && detectMonster == 0)) {
    return "something";
  }

  if (halluc != 0) {
    return monsterNames[getRand(0, 25)];
  }

  return monsterNames[monster.ichar.codeUnitAt(0) - 'A'.codeUnitAt(0)];
}

bool rogueIsAround(int row, int col) {
  int rdif = (row - rogue.row).abs();
  int cdif = (col - rogue.col).abs();
  return rdif < 2 && cdif < 2;
}

void startWanderer() {
  GameObject monster;

  while (true) {
    monster = getRandMonster();
    if (monster.mFlags & MonsterFlags.wakens != 0 ||
        monster.mFlags & MonsterFlags.wanders != 0) {
      break;
    }
  }

  wakeUp(monster);

  for (int i = 0; i < 12; i++) {
    var pos = getRandRowCol(Cell.floor | Cell.tunnel | Cell.isObject);
    int row = pos.item1;
    int col = pos.item2;

    if (!canSee(row, col)) {
      putMonsterAt(row, col, monster);
      return;
    }
  }
}

void showMonsters() {
  if (blind != 0) return;

  GameObject? monster = levelMonsters.nextObject;
  while (monster != null) {
    ui.move(monster.row, monster.col);
    ui.write(monster.ichar);

    if (monster.ichar == 'X') {
      monster.identified = 0;
    }

    monster = monster.nextObject;
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
    GameObject monster = getRandMonster();
    putMonsterAt(row, col, monster);

    ui.move(row, col);
    ui.write(getMonsterChar(monster));

    if (monster.mFlags & MonsterFlags.wanders != 0) {
      wakeUp(monster);
    }
  } else {
    await message("you hear a faint cry of anguish in the distance", 0);
  }
}

void putMonsterAt(int row, int col, GameObject monster) {
  monster.row = row;
  monster.col = col;
  addMask(row, col, Cell.monster);
  addToPack(monster, levelMonsters, false);
}

bool canSee(int row, int col) {
  return blind == 0 &&
      (getRoomNumber(row, col) == currentRoom || rogueIsAround(row, col));
}

bool flit(GameObject monster) {
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

      if (mtry(monster, row, col)) {
        return true;
      }
    }
  }

  return true;
}

void putMonsterRandLocation(GameObject monster) {
  var pos = getRandRowCol(Cell.floor | Cell.tunnel | Cell.isObject);
  int row = pos.item1;
  int col = pos.item2;

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

  GameObject? monster = levelMonsters.nextObject;
  while (monster != null) {
    wakeUp(monster);
    if (monster.ichar == 'X') {
      monster.identified = 0;
    }
    monster = monster.nextObject;
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
  GameObject? monster = levelMonsters.nextObject;
  while (monster != null) {
    if (monster.ichar == 'A') {
      await mvMonster(monster, rogue.row, rogue.col);
    }
    monster = monster.nextObject;
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
    var result = getOtherRoom(rn, row, col);
    bool b = result.item1;
    int rrow = result.item2;
    int ccol = result.item3;

    if (b) {
      monster.trow = rrow;
      monster.tcol = ccol;
    } else {
      monster.trow = -1;
    }
  }
}

Tuple3<bool, int, int> getOtherRoom(int rn, int row, int col) {
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
    return Tuple3(
      true,
      rooms[rn].doors[d].otherRow,
      rooms[rn].doors[d].otherCol,
    );
  }

  return Tuple3(false, 0, 0);
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}

class Tuple3<T1, T2, T3> {
  final T1 item1;
  final T2 item2;
  final T3 item3;

  Tuple3(this.item1, this.item2, this.item3);
}
