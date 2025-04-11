import 'dart:io' if (dart.library.js) 'web_io.dart';

import 'globals.dart';
import 'inventory.dart';
import 'message.dart';
import 'object.dart';
import 'pack.dart';
import 'ui.dart';

Future<void> init() async {
  playerName = Platform.environment['USER'] ?? 'Rogue';

  print("Hello $playerName, just a moment while I dig the dungeon...");

  for (int i = 0; i < 26; i++) {
    ichars[i] = false;
  }

  srandom(DateTime.now().millisecondsSinceEpoch);
  initItems();

  levelObjects.clear();
  levelMonsters.clear();
  playerInit();
}

void playerInit() {
  rogue.pack.clear();

  // Initial food
  GameObject obj = getAnObject();
  getFood(obj);
  addToPack(obj, rogue.pack, true);

  // Initial armor
  obj = getAnObject();
  obj.whatIs = Cell.armor;
  obj.whichKind = ArmorType.ring.index;
  obj.clasz = ArmorType.ring.index + 2;
  obj.isCursed = 0;
  obj.isProtected = 0;
  obj.damageEnchantment = 1;
  obj.identified = 1;
  addToPack(obj, rogue.pack, true);
  rogue.armor = obj;

  // Initial weapons
  obj = getAnObject();
  obj.whatIs = Cell.weapon;
  obj.whichKind = WeaponType.mace.index;
  obj.isCursed = 0;
  obj.damage = "2d3";
  obj.toHitEnchantment = 1;
  obj.damageEnchantment = 1;
  obj.identified = 1;
  addToPack(obj, rogue.pack, true);
  rogue.weapon = obj;

  obj = getAnObject();
  obj.whatIs = Cell.weapon;
  obj.whichKind = WeaponType.bow.index;
  obj.isCursed = 0;
  obj.damage = "1d2";
  obj.toHitEnchantment = 1;
  obj.damageEnchantment = 0;
  obj.identified = 1;
  addToPack(obj, rogue.pack, true);

  obj = getAnObject();
  obj.whatIs = Cell.weapon;
  obj.whichKind = WeaponType.arrow.index;
  obj.quantity = getRand(25, 35);
  obj.isCursed = 0;
  obj.damage = "1d2";
  obj.toHitEnchantment = 0;
  obj.damageEnchantment = 0;
  obj.identified = 1;
  addToPack(obj, rogue.pack, true);
}

Never cleanUp(String estr) {
  ui.move(ui.rows - 1, 0);
  ui.refresh();
  ui.clearScreen();
  print(estr);
  if (exc != null) {
    print("---------");
    print(exc.toString());
    print("---------");
  }
  exit(0);
}

void byebye() {
  cleanUp("Okay, bye bye!");
}

Future<void> onintr() async {
  if (cantInt) {
    didInt = true;
  } else {
    checkMessage();
    await message("interrupt", true);
  }
}
