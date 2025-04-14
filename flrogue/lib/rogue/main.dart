import 'globals.dart';
import 'init.dart';
import 'level.dart';
import 'monster.dart';
import 'object.dart';
import 'play.dart';
import 'room.dart';
import 'ui.dart';

Future<void> main() async {
  // Run game in separate isolate to prevent UI freezes
  try {
    await init();

    while (true) {
      try {
        clearLevel();
        makeLevel();
        putObjects();
        putStairs();
        putMonsters();
        putPlayer();
        lightUpRoom();
        printStats();
        await playLevel();
        levelObjects.clear();
        levelMonsters.clear();
        ui.clearScreen();
      } catch (ex, st) {
        exc = (ex, st);
        cleanUp("Level error occurred");
      }
    }
  } catch (ex, st) {
    exc = (ex, st);
    cleanUp("Game error occurred");
  }
}
