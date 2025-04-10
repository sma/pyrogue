import 'package:flrogue/rogue/message.dart';

import 'globals.dart';
import 'ui.dart';
import 'room.dart';
import 'object.dart';
import 'score.dart';

// List of experience points needed for each level
final List<int> levelPoints = [
  10,
  20,
  40,
  80,
  160,
  320,
  640,
  1300,
  2600,
  5200,
  10000,
  20000,
  40000,
  80000,
  160000,
  320000,
  1000000,
  10000000,
];

void makeLevel() {
  g.partyRoom = -1;

  if (g.currentLevel < 126) {
    g.currentLevel += 1;
  }

  if (g.currentLevel > g.maxLevel) {
    g.maxLevel = g.currentLevel;
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
    makeRoom(i, mustExists1, mustExists2, 4);
  }

  tryRooms(0, 1, 2);
  tryRooms(0, 3, 6);
  tryRooms(2, 5, 8);
  tryRooms(6, 7, 8);

  for (int i = 0; i < maxRooms - 1; i++) {
    connectRooms(i, i + 1, mustExists1, mustExists2, 4);
    if (i < maxRooms - 3) {
      connectRooms(i, i + 3, mustExists1, mustExists2, 4);
    }
  }

  addDeadEnds();

  if (g.hasAmulet == 0 && g.currentLevel >= amuletLevel) {
    putAmulet();
  }
}

void makeRoom(int n, int r1, int r2, int r3) {
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

void connectRooms(int room1, int room2, int m1, int m2, int m3) {
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

  if (adjascent(room1, room2)) {
    doConnect(room1, room2);
  }
}

void doConnect(int room1, int room2) {
  int dir1, dir2;

  if (rooms[room1].leftCol > rooms[room2].rightCol && onSameRow(room1, room2)) {
    dir1 = Direction.left.index;
    dir2 = Direction.right.index;
  } else if (rooms[room2].leftCol > rooms[room1].rightCol &&
      onSameRow(room1, room2)) {
    dir1 = Direction.right.index;
    dir2 = Direction.left.index;
  } else if (rooms[room1].topRow > rooms[room2].bottomRow &&
      onSameCol(room1, room2)) {
    dir1 = Direction.up.index;
    dir2 = Direction.down.index;
  } else if (rooms[room2].topRow > rooms[room1].bottomRow &&
      onSameCol(room1, room2)) {
    dir1 = Direction.down.index;
    dir2 = Direction.up.index;
  } else {
    return;
  }

  var door1 = putDoor(room1, dir1);
  int row1 = door1.item1;
  int col1 = door1.item2;

  var door2 = putDoor(room2, dir2);
  int row2 = door2.item1;
  int col2 = door2.item2;

  drawSimplePassage(row1, col1, row2, col2, dir1);

  if (randPercent(10)) {
    drawSimplePassage(row1, col1, row2, col2, dir1);
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

  g.detectMonster = 0;
  g.beingHeld = 0;
}

void printStats() {
  String m =
      "Level: ${g.currentLevel}  Gold: ${rogue.gold}  Hp: ${rogue.hpCurrent}(${rogue.hpMax})  Str: ${rogue.strengthCurrent}(${rogue.strengthMax})  Arm: ${getArmorClass(rogue.armor)}  Exp: ${rogue.exp}/${rogue.expPoints} ${g.hungerStr}";

  ui.move(ui.rows - 1, 0);
  ui.write(m);
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

bool adjascent(int room1, int room2) {
  if (!rooms[room1].isRoom || !rooms[room2].isRoom) {
    return false;
  }

  if (room1 > room2) {
    int temp = room1;
    room1 = room2;
    room2 = temp;
  }

  return (onSameCol(room1, room2) || onSameRow(room1, room2)) &&
      (room2 - room1 == 1 || room2 - room1 == 3);
}

Tuple2<int, int> putDoor(int rn, int dir) {
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
  return Tuple2(row, col);
}

void drawSimplePassage(int row1, int col1, int row2, int col2, int dir) {
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

bool onSameRow(int room1, int room2) {
  return room1 ~/ 3 == room2 ~/ 3;
}

bool onSameCol(int room1, int room2) {
  return room1 % 3 == room2 % 3;
}

void addDeadEnds() {
  if (g.currentLevel <= 2) return;

  int start = getRand(0, maxRooms - 1);
  int deadEndPercent = 12 + g.currentLevel * 2;

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
          breakIn(row, col, screen[row][col], dir);
          found = true;
        } else {
          addMask(row, col, Cell.tunnel);
        }

        k += 1;
      }
    }
  }
}

void breakIn(int row, int col, int ch, int dir) {
  if (ch & Cell.door != 0) {
    return;
  }

  int rn = getRoomNumber(row, col);

  if (ch & Cell.vertWall != 0) {
    if (col == rooms[rn].leftCol) {
      if (rooms[rn].doors[Direction.left.index ~/ 2].otherRoom != noRoom) {
        int drow = doorRow(rn, Direction.left.index);
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
        int drow = doorRow(rn, Direction.right.index);
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
        int dcol = doorCol(rn, Direction.up.index);
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
        int dcol = doorCol(rn, Direction.down.index);
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

int doorRow(int rn, int dir) {
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

int doorCol(int rn, int dir) {
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
    rogue.row = pos.item1;
    rogue.col = pos.item2;

    g.currentRoom = getRoomNumber(rogue.row, rogue.col);
    if (g.currentRoom != g.partyRoom) {
      break;
    }
  }
}

bool checkDown() {
  if (screen[rogue.row][rogue.col] & Cell.stairs != 0) {
    return true;
  }
  message("I see no way down", 0);
  return false;
}

bool checkUp() {
  if (!(screen[rogue.row][rogue.col] & Cell.stairs != 0)) {
    message("I see no way up", 0);
    return false;
  }

  if (g.hasAmulet == 0) {
    message("your way is magically blocked", 0);
    return false;
  }

  if (g.currentLevel == 1) {
    win();
    return true;
  } else {
    g.currentLevel -= 2;
    return true;
  }
}

void addExp(int e) {
  rogue.expPoints += e;

  if (rogue.expPoints >= levelPoints[rogue.exp - 1]) {
    int newExp = getExpLevel(rogue.expPoints);
    for (int i = rogue.exp + 1; i <= newExp; i++) {
      message("welcome to level $i", 0);
      int hp = getRand(3, 10);
      rogue.hpCurrent += hp;
      rogue.hpMax += hp;
      printStats();
    }
    rogue.exp = newExp;
  }

  printStats();
}

int getExpLevel(int e) {
  for (int i = 0; i < 50; i++) {
    if (levelPoints[i] > e) {
      return i + 1;
    }
  }
  return 50; // Max level
}

void tryRooms(int r1, int r2, int r3) {
  if (rooms[r1].isRoom && !rooms[r2].isRoom && rooms[r3].isRoom) {
    if (randPercent(75)) {
      doConnect(r1, r3);
    }
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple2(this.item1, this.item2);
}
