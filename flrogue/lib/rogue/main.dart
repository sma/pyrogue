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
      } catch (e) {
        print("Level error: $e");
        exc = e as Exception;
        cleanUp("Level error occurred");
      }
    }
  } catch (e) {
    print("Game error: $e");
    exc = e as Exception;
    cleanUp("Game error occurred");
  }
}
