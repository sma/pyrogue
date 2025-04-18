import 'globals.dart';
import 'message.dart';
import 'object.dart';
import 'room.dart';
import 'score.dart';
import 'ui.dart';

void makeLevel() {
  partyRoom = -1;

  if (currentLevel < 126) {
    currentLevel += 1;
  }

  if (currentLevel > maxLevel) {
    maxLevel = currentLevel;
  }

  int mustExists1, mustExists2;
  if (randPercent(50)) {
    mustExists1 = 1;
    mustExists2 = 7;
  } else {
    mustExists1 = 3;
    mustExists2 = 5;
  }

  for (int i = 0; i < maxRooms; i++) {
    _makeRoom(i, mustExists1, mustExists2, 4);
  }

  _tryRooms(0, 1, 2);
  _tryRooms(0, 3, 6);
  _tryRooms(2, 5, 8);
  _tryRooms(6, 7, 8);

  for (int i = 0; i < maxRooms - 1; i++) {
    _connectRooms(i, i + 1, mustExists1, mustExists2, 4);
    if (i < maxRooms - 3) {
      _connectRooms(i, i + 3, mustExists1, mustExists2, 4);
    }
  }

  _addDeadEnds();

  if (!hasAmulet && currentLevel >= amuletLevel) {
    putAmulet();
  }
}

void _makeRoom(int n, int r1, int r2, int r3) {
  int leftCol, rightCol, topRow, bottomRow;

  if (n == 0) {
    leftCol = 0;
    rightCol = col1 - 1;
    topRow = minRow;
    bottomRow = row1 - 1;
  } else if (n == 1) {
    leftCol = col1 + 1;
    rightCol = col2 - 1;
    topRow = minRow;
    bottomRow = row1 - 1;
  } else if (n == 2) {
    leftCol = col2 + 1;
    rightCol = ui.cols - 1;
    topRow = minRow;
    bottomRow = row1 - 1;
  } else if (n == 3) {
    leftCol = 0;
    rightCol = col1 - 1;
    topRow = row1 + 1;
    bottomRow = row2 - 1;
  } else if (n == 4) {
    leftCol = col1 + 1;
    rightCol = col2 - 1;
    topRow = row1 + 1;
    bottomRow = row2 - 1;
  } else if (n == 5) {
    leftCol = col2 + 1;
    rightCol = ui.cols - 1;
    topRow = row1 + 1;
    bottomRow = row2 - 1;
  } else if (n == 6) {
    leftCol = 0;
    rightCol = col1 - 1;
    topRow = row2 + 1;
    bottomRow = ui.rows - 2;
  } else if (n == 7) {
    leftCol = col1 + 1;
    rightCol = col2 - 1;
    topRow = row2 + 1;
    bottomRow = ui.rows - 2;
  } else if (n == 8) {
    leftCol = col2 + 1;
    rightCol = ui.cols - 1;
    topRow = row2 + 1;
    bottomRow = ui.rows - 2;
  } else {
    // Should never happen
    return;
  }

  if (!(n != r1 && n != r2 && n != r3 && randPercent(45))) {
    int height = getRand(4, bottomRow - topRow + 1);
    int width = getRand(7, rightCol - leftCol - 2);
    int rowOffset = getRand(0, bottomRow - topRow - height + 1);
    int colOffset = getRand(0, rightCol - leftCol - width + 1);

    topRow += rowOffset;
    bottomRow = topRow + height - 1;
    leftCol += colOffset;
    rightCol = leftCol + width - 1;

    rooms[n].isRoom = true;

    for (int i = topRow; i <= bottomRow; i++) {
      for (int j = leftCol; j <= rightCol; j++) {
        int ch;
        if (i == topRow || i == bottomRow) {
          ch = Cell.horWall;
        } else if (j == leftCol || j == rightCol) {
          ch = Cell.vertWall;
        } else {
          ch = Cell.floor;
        }
        addMask(i, j, ch);
      }
    }

    rooms[n].topRow = topRow;
    rooms[n].bottomRow = bottomRow;
    rooms[n].leftCol = leftCol;
    rooms[n].rightCol = rightCol;
    rooms[n].height = height;
    rooms[n].width = width;
  }
}

void _connectRooms(int room1, int room2, int m1, int m2, int m3) {
  if (room1 != m1 &&
      room1 != m2 &&
      room1 != m3 &&
      room2 != m1 &&
      room2 != m2 &&
      room2 != m3) {
    if (randPercent(80)) {
      return;
    }
  }

  if (_adjascent(room1, room2)) {
    _doConnect(room1, room2);
  }
}

void _doConnect(int room1, int room2) {
  int dir1, dir2;

  if (rooms[room1].leftCol > rooms[room2].rightCol &&
      _onSameRow(room1, room2)) {
    dir1 = Direction.left.index;
    dir2 = Direction.right.index;
  } else if (rooms[room2].leftCol > rooms[room1].rightCol &&
      _onSameRow(room1, room2)) {
    dir1 = Direction.right.index;
    dir2 = Direction.left.index;
  } else if (rooms[room1].topRow > rooms[room2].bottomRow &&
      _onSameCol(room1, room2)) {
    dir1 = Direction.up.index;
    dir2 = Direction.down.index;
  } else if (rooms[room2].topRow > rooms[room1].bottomRow &&
      _onSameCol(room1, room2)) {
    dir1 = Direction.down.index;
    dir2 = Direction.up.index;
  } else {
    return;
  }

  final (row1, col1) = _putDoor(room1, dir1);

  final (row2, col2) = _putDoor(room2, dir2);

  _drawSimplePassage(row1, col1, row2, col2, dir1);

  if (randPercent(10)) {
    _drawSimplePassage(row1, col1, row2, col2, dir1);
  }

  rooms[room1].doors[dir1 ~/ 2].otherRoom = room2;
  rooms[room1].doors[dir1 ~/ 2].otherRow = row2;
  rooms[room1].doors[dir1 ~/ 2].otherCol = col2;

  rooms[room2].doors[dir2 ~/ 2].otherRoom = room1;
  rooms[room2].doors[dir2 ~/ 2].otherRow = row1;
  rooms[room2].doors[dir2 ~/ 2].otherCol = col1;
}

void clearLevel() {
  for (int i = 0; i < maxRooms; i++) {
    rooms[i].isRoom = false;
    for (int j = 0; j < 4; j++) {
      rooms[i].doors[j].otherRoom = noRoom;
    }
  }

  for (int i = 0; i < sRows; i++) {
    for (int j = 0; j < sCols; j++) {
      screen[i][j] = Cell.blank;
    }
  }

  detectMonster = false;
  beingHeld = false;
}

void printStats() {
  String m =
      "Level: $currentLevel  Gold: ${rogue.gold}  Hp: ${rogue.hpCurrent}(${rogue.hpMax})  Str: ${rogue.strengthCurrent}(${rogue.strengthMax})  Arm: ${getArmorClass(rogue.armor)}  Exp: ${rogue.exp}/${rogue.expPoints} $hungerStr";

  ui.move(ui.rows - 1, 0).write(m);
  ui.clearToEndOfLine();
  ui.refresh();
}

void addMask(int row, int col, int mask) {
  if (mask == Cell.door) {
    removeMask(row, col, Cell.horWall);
    removeMask(row, col, Cell.vertWall);
  }
  screen[row][col] |= mask;
}

void removeMask(int row, int col, int mask) {
  screen[row][col] &= ~mask;
}

bool _adjascent(int room1, int room2) {
  if (!rooms[room1].isRoom || !rooms[room2].isRoom) {
    return false;
  }

  if (room1 > room2) {
    int temp = room1;
    room1 = room2;
    room2 = temp;
  }

  return (_onSameCol(room1, room2) || _onSameRow(room1, room2)) &&
      (room2 - room1 == 1 || room2 - room1 == 3);
}

(int, int) _putDoor(int rn, int dir) {
  int row, col;

  if (dir == Direction.up.index || dir == Direction.down.index) {
    row = (dir == Direction.up.index) ? rooms[rn].topRow : rooms[rn].bottomRow;
    col = getRand(rooms[rn].leftCol + 1, rooms[rn].rightCol - 1);
  } else {
    // LEFT or RIGHT
    row = getRand(rooms[rn].topRow + 1, rooms[rn].bottomRow - 1);
    col =
        (dir == Direction.left.index) ? rooms[rn].leftCol : rooms[rn].rightCol;
  }

  addMask(row, col, Cell.door);
  return (row, col);
}

void _drawSimplePassage(int row1, int col1, int row2, int col2, int dir) {
  if (dir == Direction.left.index || dir == Direction.right.index) {
    if (col2 < col1) {
      // Swap points
      int tempRow = row1;
      row1 = row2;
      row2 = tempRow;

      int tempCol = col1;
      col1 = col2;
      col2 = tempCol;
    }

    int middle = getRand(col1 + 1, col2 - 1);

    for (int i = col1 + 1; i < middle; i++) {
      addMask(row1, i, Cell.tunnel);
    }

    for (int i = row1; i != row2; i += (row1 > row2) ? -1 : 1) {
      addMask(i, middle, Cell.tunnel);
    }

    for (int i = middle; i < col2; i++) {
      addMask(row2, i, Cell.tunnel);
    }
  } else {
    // UP or DOWN
    if (row2 < row1) {
      // Swap points
      int tempRow = row1;
      row1 = row2;
      row2 = tempRow;

      int tempCol = col1;
      col1 = col2;
      col2 = tempCol;
    }

    int middle = getRand(row1 + 1, row2 - 1);

    for (int i = row1 + 1; i < middle; i++) {
      addMask(i, col1, Cell.tunnel);
    }

    for (int i = col1; i != col2; i += (col1 > col2) ? -1 : 1) {
      addMask(middle, i, Cell.tunnel);
    }

    for (int i = middle; i < row2; i++) {
      addMask(i, col2, Cell.tunnel);
    }
  }
}

bool _onSameRow(int room1, int room2) {
  return room1 ~/ 3 == room2 ~/ 3;
}

bool _onSameCol(int room1, int room2) {
  return room1 % 3 == room2 % 3;
}

void _addDeadEnds() {
  if (currentLevel <= 2) return;

  int start = getRand(0, maxRooms - 1);
  int deadEndPercent = 12 + currentLevel * 2;

  for (int i = 0; i < maxRooms; i++) {
    int j = (start + i) % maxRooms;

    if (rooms[j].isRoom) continue;

    if (!randPercent(deadEndPercent)) continue;

    int row = rooms[j].topRow + getRand(0, 6);
    int col = rooms[j].leftCol + getRand(0, 19);

    bool found = false;
    while (!found) {
      int distance = getRand(8, 20);
      int dir = getRand(0, 3) * 2;
      int k = 0;

      while (k < distance && !found) {
        if (dir == Direction.up.index) {
          if (row - 1 >= minRow) row -= 1;
        } else if (dir == Direction.right.index) {
          if (col + 1 < ui.cols - 1) col += 1;
        } else if (dir == Direction.down.index) {
          if (row + 1 < ui.rows - 2) row += 1;
        } else if (dir == Direction.left.index) {
          if (col - 1 > 0) col -= 1;
        }

        if (screen[row][col] & (Cell.vertWall | Cell.horWall | Cell.door) !=
            0) {
          _breakIn(row, col, screen[row][col], dir);
          found = true;
        } else {
          addMask(row, col, Cell.tunnel);
        }

        k += 1;
      }
    }
  }
}

void _breakIn(int row, int col, int ch, int dir) {
  if (ch & Cell.door != 0) {
    return;
  }

  int rn = getRoomNumber(row, col);

  if (ch & Cell.vertWall != 0) {
    if (col == rooms[rn].leftCol) {
      if (rooms[rn].doors[Direction.left.index ~/ 2].otherRoom != noRoom) {
        int drow = _doorRow(rn, Direction.left.index);
        for (int i = row; i != drow; i += (drow > row) ? 1 : -1) {
          addMask(i, col - 1, Cell.tunnel);
        }
      } else {
        rooms[rn].doors[Direction.left.index ~/ 2].otherRoom = deadEnd;
        addMask(row, col, Cell.door);
      }
    } else {
      // rightCol
      if (rooms[rn].doors[Direction.right.index ~/ 2].otherRoom != noRoom) {
        int drow = _doorRow(rn, Direction.right.index);
        for (int i = row; i != drow; i += (drow > row) ? 1 : -1) {
          addMask(i, col + 1, Cell.tunnel);
        }
      } else {
        rooms[rn].doors[Direction.right.index ~/ 2].otherRoom = deadEnd;
        addMask(row, col, Cell.door);
      }
    }
  } else {
    // HORWALL
    if (row == rooms[rn].topRow) {
      if (rooms[rn].doors[Direction.up.index ~/ 2].otherRoom != noRoom) {
        int dcol = _doorCol(rn, Direction.up.index);
        for (int i = col; i != dcol; i += (dcol < col) ? -1 : 1) {
          addMask(row - 1, i, Cell.tunnel);
        }
      } else {
        rooms[rn].doors[Direction.up.index ~/ 2].otherRoom = deadEnd;
        addMask(row, col, Cell.door);
      }
    } else {
      // bottomRow
      if (rooms[rn].doors[Direction.down.index ~/ 2].otherRoom != noRoom) {
        int dcol = _doorCol(rn, Direction.down.index);
        for (int i = col; i != dcol; i += (dcol < col) ? -1 : 1) {
          addMask(row + 1, i, Cell.tunnel);
        }
      } else {
        rooms[rn].doors[Direction.down.index ~/ 2].otherRoom = deadEnd;
        addMask(row, col, Cell.door);
      }
    }
  }
}

int _doorRow(int rn, int dir) {
  if (rooms[rn].doors[dir ~/ 2].otherRoom == noRoom) {
    return -1;
  }

  int col;
  if (dir == Direction.left.index) {
    col = rooms[rn].leftCol;
  } else if (dir == Direction.right.index) {
    col = rooms[rn].rightCol;
  } else {
    return -1;
  }

  for (int row = rooms[rn].topRow; row < rooms[rn].bottomRow; row++) {
    if (screen[row][col] & Cell.door != 0) {
      return row;
    }
  }

  return -1;
}

int _doorCol(int rn, int dir) {
  if (rooms[rn].doors[dir ~/ 2].otherRoom == noRoom) {
    return -1;
  }

  int row;
  if (dir == Direction.up.index) {
    row = rooms[rn].topRow;
  } else if (dir == Direction.down.index) {
    row = rooms[rn].bottomRow;
  } else {
    return -1;
  }

  for (int col = rooms[rn].leftCol; col < rooms[rn].rightCol; col++) {
    if (screen[row][col] & Cell.door != 0) {
      return col;
    }
  }

  return -1;
}

void putPlayer() {
  while (true) {
    var pos = getRandRowCol(Cell.floor | Cell.isObject);
    rogue.row = pos.$1;
    rogue.col = pos.$2;

    currentRoom = getRoomNumber(rogue.row, rogue.col);
    if (currentRoom != partyRoom) {
      break;
    }
  }
}

Future<bool> checkDown() async {
  if (screen[rogue.row][rogue.col] & Cell.stairs != 0) {
    return true;
  }
  await message("I see no way down");
  return false;
}

Future<bool> checkUp() async {
  if (!(screen[rogue.row][rogue.col] & Cell.stairs != 0)) {
    await message("I see no way up");
    return false;
  }

  if (!hasAmulet) {
    await message("your way is magically blocked");
    return false;
  }

  if (currentLevel == 1) {
    await win();
    return true;
  } else {
    currentLevel -= 2;
    return true;
  }
}

Future<void> addExp(int e) async {
  rogue.expPoints += e;

  if (rogue.expPoints >= levelPoints[rogue.exp - 1]) {
    int newExp = _getExpLevel(rogue.expPoints);
    for (int i = rogue.exp + 1; i <= newExp; i++) {
      await message("welcome to level $i");
      int hp = getRand(3, 10);
      rogue.hpCurrent += hp;
      rogue.hpMax += hp;
      printStats();
    }
    rogue.exp = newExp;
  }

  printStats();
}

int _getExpLevel(int e) {
  for (int i = 0; i < 50; i++) {
    if (levelPoints[i] > e) {
      return i + 1;
    }
  }
  return 50; // Max level
}

void _tryRooms(int r1, int r2, int r3) {
  if (rooms[r1].isRoom && !rooms[r2].isRoom && rooms[r3].isRoom) {
    if (randPercent(75)) {
      _doConnect(r1, r3);
    }
  }
}
