import 'globals.dart';
import 'hit.dart';
import 'level.dart';
import 'message.dart';
import 'monster.dart';
import 'object.dart';
import 'pack.dart';
import 'room.dart';
import 'score.dart';
import 'ui.dart';
import 'use.dart';

// Movement status constants
const int moved = 0;
const int moveFailed = -1;
const int stoppedOnSomething = -2;

// Global state for move logic
int _moves = 0;
int _hExp = -1;
int _hN = 0;
int _hC = 0;

Future<int> singleMoveRogue(String dirch, bool pickup) async {
  int row = rogue.row;
  int col = rogue.col;

  if (beingHeld) {
    (row, col) = getDirRc(dirch, row, col);

    if (!(screen[row][col] & Cell.monster != 0)) {
      await message("you are being held", true);
      return moveFailed;
    }
  }

  row = rogue.row;
  col = rogue.col;

  if (confused != 0) {
    dirch = _getRandDir();
  }

  (row, col) = getDirRc(dirch, row, col);

  if (screen[row][col] & Cell.monster != 0) {
    await rogueHit(objectAt(levelMonsters, row, col)!);
    await registerMove();
    return moveFailed;
  }

  if (!_canMove(rogue.row, rogue.col, row, col)) {
    return moveFailed;
  }

  if (screen[row][col] & Cell.door != 0) {
    if (currentRoom == passage) {
      currentRoom = getRoomNumber(row, col);
      lightUpRoom();
      wakeRoom(currentRoom, true, row, col);
    } else {
      lightPassage(row, col);
    }
  } else if (screen[rogue.row][rogue.col] & Cell.door != 0 &&
      screen[row][col] & Cell.tunnel != 0) {
    lightPassage(row, col);
    wakeRoom(currentRoom, false, row, col);
    darkenRoom(currentRoom);
    currentRoom = passage;
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
    if (pickup) {
      var (obj, status) = await pickUp(row, col);

      if (obj != null) {
        String description = getDescription(obj);
        if (obj.whatIs == Cell.gold) {
          await message(description, true);
          await registerMove();
          return stoppedOnSomething;
        }
      } else if (!status) {
        if (await registerMove()) {
          // fainted from hunger
          return stoppedOnSomething;
        }
        return confused != 0 ? stoppedOnSomething : moved;
      } else {
        GameObject obj = objectAt(levelObjects, row, col)!;
        String description = "moved onto ${getDescription(obj)}";
        await message(description, true);
        await registerMove();
        return stoppedOnSomething;
      }
    } else {
      GameObject obj = objectAt(levelObjects, row, col)!;
      String description = "moved onto ${getDescription(obj)}";
      await message(description, true);
      await registerMove();
      return stoppedOnSomething;
    }
  }

  if (screen[row][col] & Cell.door != 0 ||
      screen[row][col] & Cell.stairs != 0) {
    await registerMove();
    return stoppedOnSomething;
  }

  if (await registerMove()) {
    // fainted from hunger
    return stoppedOnSomething;
  }

  return confused != 0 ? stoppedOnSomething : moved;
}

Future<void> multipleMoveRogue(String dirch) async {
  if ("\u0008\u000A\u000B\u000C\u0019\u0015\u000E\u0002".contains(dirch)) {
    while (true) {
      int row = rogue.row;
      int col = rogue.col;

      int m = await singleMoveRogue(
        String.fromCharCode(dirch.ascii + 96),
        true,
      );

      if (m == moveFailed || m == stoppedOnSomething || interrupted) {
        break;
      }

      if (_nextToSomething(row, col)) {
        break;
      }
    }
  } else if ("HJKLBYUN".contains(dirch)) {
    while (!interrupted &&
        await singleMoveRogue(String.fromCharCode(dirch.ascii + 32), true) ==
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

bool _nextToSomething(int drow, int dcol) {
  if (confused != 0) {
    return true;
  }

  if (blind != 0) {
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

bool _canMove(int row1, int col1, int row2, int col2) {
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
  if (ch != cancel) {
    await singleMoveRogue(ch, false);
  }
}

bool isPackLetter(String c) {
  return c.between('a', 'z') || c == cancel || c == list;
}

Future<bool> _checkHunger() async {
  bool fainted = false;

  if (rogue.movesLeft == hungry) {
    hungerStr = "hungry";
    await message(hungerStr);
    printStats();
  }

  if (rogue.movesLeft == weak) {
    hungerStr = "weak";
    await message(hungerStr);
    printStats();
  }

  if (rogue.movesLeft <= faint) {
    if (rogue.movesLeft == faint) {
      hungerStr = "faint";
      await message(hungerStr, true);
      printStats();
    }

    int n = getRand(0, faint - rogue.movesLeft);
    if (n > 0) {
      fainted = true;
      if (randPercent(40)) rogue.movesLeft += 1;
      await message("you faint", true);

      for (int i = 0; i < n; i++) {
        if (randPercent(50)) {
          await moveMonsters();
        }
      }

      await message("you can move again", true);
    }
  }

  if (rogue.movesLeft <= starve) {
    await killedBy(null, DeathCause.starvation);
  }

  rogue.movesLeft -= 1;
  return fainted;
}

Future<bool> registerMove() async {
  bool fainted = false;

  if (rogue.movesLeft <= hungry && !hasAmulet) {
    fainted = _checkHunger() as bool;
  }

  await moveMonsters();

  _moves += 1;
  if (_moves >= 80) {
    _moves = 0;
    startWanderer();
  }

  if (halluc != 0) {
    halluc -= 1;
    if (halluc == 0) {
      await unhallucinate();
    } else {
      hallucinate();
    }
  }

  if (blind != 0) {
    blind -= 1;
    if (blind == 0) {
      await unblind();
    }
  }

  if (confused != 0) {
    confused -= 1;
    if (confused == 0) {
      await unconfuse();
    }
  }

  _heal();

  return fainted;
}

Future<void> rest(int count) async {
  for (int i = 0; i < count; i++) {
    if (interrupted) {
      break;
    }
    await registerMove();
  }
}

String _getRandDir() {
  return "hjklyubn"[getRand(0, 7)];
}

void _heal() {
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
