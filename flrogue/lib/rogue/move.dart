import 'package:flrogue/rogue/score.dart';
import 'package:flrogue/rogue/use.dart';

import 'globals.dart';
import 'ui.dart';
import 'hit.dart';
import 'monster.dart';
import 'message.dart';
import 'level.dart';
import 'room.dart';
import 'object.dart';
import 'pack.dart';

// Movement status constants
const int moved = 0;
const int moveFailed = -1;
const int stoppedOnSomething = -2;

// Global state for move logic
int _moves = 0;
int _hExp = -1;
int _hN = 0;
int _hC = 0;

Future<int> singleMoveRogue(String dirch, int pickup) async {
  int row = rogue.row;
  int col = rogue.col;

  if (g.beingHeld != 0) {
    var pos = getDirRc(dirch, row, col);
    row = pos.item1;
    col = pos.item2;

    if (!(screen[row][col] & Cell.monster != 0)) {
      message("you are being held", 1);
      return moveFailed;
    }
  }

  row = rogue.row;
  col = rogue.col;

  if (g.confused != 0) {
    dirch = getRandDir();
  }

  var pos = getDirRc(dirch, row, col);
  row = pos.item1;
  col = pos.item2;

  if (screen[row][col] & Cell.monster != 0) {
    rogueHit(objectAt(g.levelMonsters, row, col)!);
    registerMove();
    return moveFailed;
  }

  if (!canMove(rogue.row, rogue.col, row, col)) {
    return moveFailed;
  }

  if (screen[row][col] & Cell.door != 0) {
    if (g.currentRoom == passage) {
      g.currentRoom = getRoomNumber(row, col);
      lightUpRoom();
      wakeRoom(g.currentRoom, true, row, col);
    } else {
      lightPassage(row, col);
    }
  } else if (screen[rogue.row][rogue.col] & Cell.door != 0 &&
      screen[row][col] & Cell.tunnel != 0) {
    lightPassage(row, col);
    wakeRoom(g.currentRoom, false, row, col);
    darkenRoom(g.currentRoom);
    g.currentRoom = passage;
  } else if (screen[row][col] & Cell.tunnel != 0) {
    lightPassage(row, col);
  }

  ui.move(rogue.row, rogue.col);
  ui.write(getRoomChar(screen[rogue.row][rogue.col], rogue.row, rogue.col));
  ui.move(row, col);
  ui.write(rogue.fchar);

  rogue.row = row;
  rogue.col = col;

  if (screen[row][col] & Cell.canPickUp != 0) {
    if (pickup != 0) {
      var result = await pickUp(row, col);
      GameObject? obj = result.item1;
      int status = result.item2;

      if (obj != null) {
        String description = getDescription(obj);
        if (obj.whatIs == Cell.gold) {
          message(description, 1);
          registerMove();
          return stoppedOnSomething;
        }
      } else if (status == 0) {
        if (registerMove()) {
          // fainted from hunger
          return stoppedOnSomething;
        }
        return g.confused != 0 ? stoppedOnSomething : moved;
      } else {
        GameObject obj = objectAt(g.levelObjects, row, col)!;
        String description = "moved onto ${getDescription(obj)}";
        message(description, 1);
        registerMove();
        return stoppedOnSomething;
      }
    } else {
      GameObject obj = objectAt(g.levelObjects, row, col)!;
      String description = "moved onto ${getDescription(obj)}";
      message(description, 1);
      registerMove();
      return stoppedOnSomething;
    }
  }

  if (screen[row][col] & Cell.door != 0 ||
      screen[row][col] & Cell.stairs != 0) {
    registerMove();
    return stoppedOnSomething;
  }

  if (registerMove()) {
    // fainted from hunger
    return stoppedOnSomething;
  }

  return g.confused != 0 ? stoppedOnSomething : moved;
}

Future<void> multipleMoveRogue(String dirch) async {
  if ("\u0008\u000A\u000B\u000C\u0019\u0015\u000E\u0002".contains(dirch)) {
    while (true) {
      int row = rogue.row;
      int col = rogue.col;

      int m = await singleMoveRogue(
        String.fromCharCode(dirch.codeUnitAt(0) + 96),
        1,
      );

      if (m == moveFailed || m == stoppedOnSomething || g.interrupted != 0) {
        break;
      }

      if (nextToSomething(row, col)) {
        break;
      }
    }
  } else if ("HJKLBYUN".contains(dirch)) {
    while (g.interrupted == 0 &&
        await singleMoveRogue(
              String.fromCharCode(dirch.codeUnitAt(0) + 32),
              1,
            ) ==
            moved) {
      // Continue until interrupted or move fails
    }
  }
}

bool isPassable(int row, int col) {
  if (row < minRow || row > ui.rows - 2 || col < 0 || col > ui.cols - 1) {
    return false;
  }
  return screen[row][col] &
          (Cell.floor | Cell.tunnel | Cell.door | Cell.stairs) !=
      0;
}

bool nextToSomething(int drow, int dcol) {
  if (g.confused != 0) {
    return true;
  }

  if (g.blind != 0) {
    return false;
  }

  int iEnd = rogue.row < ui.rows - 2 ? 1 : 0;
  int jEnd = rogue.col < ui.cols - 1 ? 1 : 0;

  for (int i = (rogue.row > minRow ? -1 : 0); i <= iEnd; i++) {
    for (int j = (rogue.col > 0 ? -1 : 0); j <= jEnd; j++) {
      if (i == 0 && j == 0) continue;

      int r = rogue.row + i;
      int c = rogue.col + j;

      if (r == drow && c == dcol) continue;

      if (screen[r][c] & (Cell.monster | Cell.isObject) != 0) {
        return true;
      }

      if ((i - j == 1 || i - j == -1) && screen[r][c] & Cell.tunnel != 0) {
        int passCount = 0;
        passCount += 1;
        if (passCount > 1) {
          return true;
        }
      }

      if (screen[r][c] & Cell.door != 0 || isObject(r, c)) {
        if (i == 0 || j == 0) {
          return true;
        }
      }
    }
  }
  return false;
}

bool canMove(int row1, int col1, int row2, int col2) {
  if (!isPassable(row2, col2)) {
    return false;
  }

  if (row1 != row2 && col1 != col2) {
    if (screen[row1][col1] & Cell.door != 0 ||
        screen[row2][col2] & Cell.door != 0) {
      return false;
    }

    if (!(screen[row1][col2] != 0) || !(screen[row2][col1] != 0)) {
      return false;
    }
  }

  return true;
}

bool isObject(int row, int col) {
  return screen[row][col] & Cell.isObject != 0;
}

Future<void> moveOnto() async {
  int firstMiss = 1;

  String ch = await ui.getchar();
  while (!isDirection(ch)) {
    ui.beep();
    if (firstMiss != 0) {
      message("direction? ", 0);
      firstMiss = 0;
    }
    ch = await ui.getchar();
  }

  checkMessage();
  if (ch != cancel) {
    await singleMoveRogue(ch, 0);
  }
}

bool isPackLetter(String c) {
  return (c.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
          c.codeUnitAt(0) <= 'z'.codeUnitAt(0)) ||
      c == cancel ||
      c == list;
}

bool checkHunger() {
  bool fainted = false;

  if (rogue.movesLeft == hungry) {
    g.hungerStr = "hungry";
    message(g.hungerStr, 0);
    printStats();
  }

  if (rogue.movesLeft == weak) {
    g.hungerStr = "weak";
    message(g.hungerStr, 0);
    printStats();
  }

  if (rogue.movesLeft <= faint) {
    if (rogue.movesLeft == faint) {
      g.hungerStr = "faint";
      message(g.hungerStr, 1);
      printStats();
    }

    int n = getRand(0, faint - rogue.movesLeft);
    if (n > 0) {
      fainted = true;
      if (randPercent(40)) rogue.movesLeft += 1;
      message("you faint", 1);

      for (int i = 0; i < n; i++) {
        if (randPercent(50)) {
          moveMonsters();
        }
      }

      message("you can move again", 1);
    }
  }

  if (rogue.movesLeft <= starve) {
    killedBy(null, DeathCause.starvation);
  }

  rogue.movesLeft -= 1;
  return fainted;
}

bool registerMove() {
  bool fainted = false;

  if (rogue.movesLeft <= hungry && g.hasAmulet == 0) {
    fainted = checkHunger();
  }

  moveMonsters();

  _moves += 1;
  if (_moves >= 80) {
    _moves = 0;
    startWanderer();
  }

  if (g.halluc != 0) {
    g.halluc -= 1;
    if (g.halluc == 0) {
      unhallucinate();
    } else {
      hallucinate();
    }
  }

  if (g.blind != 0) {
    g.blind -= 1;
    if (g.blind == 0) {
      unblind();
    }
  }

  if (g.confused != 0) {
    g.confused -= 1;
    if (g.confused == 0) {
      unconfuse();
    }
  }

  heal();

  return fainted;
}

void rest(int count) {
  for (int i = 0; i < count; i++) {
    if (g.interrupted != 0) {
      break;
    }
    registerMove();
  }
}

String getRandDir() {
  return "hjklyubn"[getRand(0, 7)];
}

void heal() {
  if (rogue.exp != _hExp) {
    _hExp = rogue.exp;

    if (_hExp == 1) {
      _hN = 20;
    } else if (_hExp == 2) {
      _hN = 18;
    } else if (_hExp == 3) {
      _hN = 17;
    } else if (_hExp == 4) {
      _hN = 14;
    } else if (_hExp == 5) {
      _hN = 13;
    } else if (_hExp == 6) {
      _hN = 11;
    } else if (_hExp == 7) {
      _hN = 9;
    } else if (_hExp == 8) {
      _hN = 8;
    } else if (_hExp == 9) {
      _hN = 6;
    } else if (_hExp == 10) {
      _hN = 4;
    } else if (_hExp == 11) {
      _hN = 3;
    } else {
      _hN = 2;
    }
  }

  if (rogue.hpCurrent == rogue.hpMax) {
    _hC = 0;
    return;
  }

  _hC += 1;
  if (_hC >= _hN) {
    _hC = 0;
    rogue.hpCurrent += 1;
    if (rogue.hpCurrent < rogue.hpMax) {
      if (randPercent(50)) {
        rogue.hpCurrent += 1;
      }
    }
    printStats();
  }
}
