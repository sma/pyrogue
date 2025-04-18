import 'globals.dart';
import 'monster.dart';
import 'move.dart';
import 'special_hit.dart';
import 'ui.dart';

void lightUpRoom() {
  if (blind != 0) return;

  Room r = rooms[currentRoom];

  for (int i = r.topRow; i <= r.bottomRow; i++) {
    for (int j = r.leftCol; j <= r.rightCol; j++) {
      ui.move(i, j).write(getRoomChar(screen[i][j], i, j));
    }
  }

  ui.move(rogue.row, rogue.col).write(rogue.fchar);
}

void lightPassage(int row, int col) {
  if (blind != 0) return;

  int iEnd = row < ui.rows - 2 ? 1 : 0;
  int jEnd = col < ui.cols - 1 ? 1 : 0;

  for (int i = (row > minRow ? -1 : 0); i <= iEnd; i++) {
    for (int j = (col > 0 ? -1 : 0); j <= jEnd; j++) {
      if (isPassable(row + i, col + j)) {
        int r = row + i;
        int c = col + j;
        ui.move(r, c).write(getRoomChar(screen[r][c], r, c));
      }
    }
  }
}

void darkenRoom(int rn) {
  if (blind != 0) return;

  Room r = rooms[rn];

  for (int i = r.topRow + 1; i < r.bottomRow; i++) {
    for (int j = r.leftCol + 1; j < r.rightCol; j++) {
      if (!isObject(i, j) &&
          !(detectMonster && screen[i][j] & Cell.monster != 0)) {
        if (!hidingXeroc(i, j)) {
          ui.move(i, j).write(' ');
        }
      }
    }
  }
}

String getRoomChar(int mask, int row, int col) {
  if (mask & Cell.monster != 0) {
    return getMonsterCharRowCol(row, col);
  }

  if (mask & Cell.scroll != 0) {
    return '?';
  }

  if (mask & Cell.potion != 0) {
    return '!';
  }

  if (mask & Cell.food != 0) {
    return ':';
  }

  if (mask & Cell.wand != 0) {
    return '/';
  }

  if (mask & Cell.armor != 0) {
    return ']';
  }

  if (mask & Cell.weapon != 0) {
    return ')';
  }

  if (mask & Cell.gold != 0) {
    return '*';
  }

  if (mask & Cell.tunnel != 0) {
    return '#';
  }

  if (mask & Cell.horWall != 0) {
    return '-';
  }

  if (mask & Cell.vertWall != 0) {
    return '|';
  }

  if (mask & Cell.amulet != 0) {
    return ',';
  }

  if (mask & Cell.stairs != 0) {
    return '%';
  }

  if (mask & Cell.floor != 0) {
    return '.';
  }

  if (mask & Cell.door != 0) {
    return '+';
  }

  return ' ';
}

(int, int) getRandRowCol(int mask) {
  int row, col;

  while (true) {
    row = getRand(minRow, sRows - 2);
    col = getRand(0, sCols - 1);
    int rn = getRoomNumber(row, col);
    if (screen[row][col] & mask != 0 &&
        screen[row][col] & ~mask == 0 &&
        rn != noRoom) {
      break;
    }
  }

  return (row, col);
}

int getRandRoom() {
  int i;

  while (true) {
    i = getRand(0, maxRooms - 1);
    if (rooms[i].isRoom) break;
  }

  return i;
}

int getRoomNumber(int row, int col) {
  for (int i = 0; i < maxRooms; i++) {
    Room r = rooms[i];
    if (r.topRow <= row &&
        row <= r.bottomRow &&
        r.leftCol <= col &&
        col <= r.rightCol) {
      return i;
    }
  }
  return noRoom;
}

void drawMagicMap() {
  const mask =
      Cell.horWall | Cell.vertWall | Cell.door | Cell.tunnel | Cell.stairs;

  for (var i = 0; i < sRows; i++) {
    for (var j = 0; j < sCols; j++) {
      var s = screen[i][j];
      if (s & mask != 0) {
        var ch = ui.move(i, j).read();
        if (ch == ' ') {
          if (s & Cell.horWall != 0) ch = '-';
          if (s & Cell.vertWall != 0) ch = '|';
          if (s & Cell.door != 0) ch = '+';
          if (s & Cell.tunnel != 0) ch = '#';
          if (s & Cell.stairs != 0) ch = '%';
          ui.move(i, j).write(ch);
        }
      }
    }
  }
}
