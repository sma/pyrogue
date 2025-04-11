import 'dart:io';
import 'globals.dart';
import 'init.dart';
import 'ui.dart';
import 'message.dart';
import 'object.dart';

const String scoreFile = "scores";

Future<void> killedBy(GameObject? monster, DeathCause other) async {
  if (other != DeathCause.quit) {
    rogue.gold = rogue.gold * 9 ~/ 10;
  }

  String buf;
  if (other == DeathCause.hypothermia) {
    buf = "died of hypothermia";
  } else if (other == DeathCause.starvation) {
    buf = "died of starvation";
  } else if (other == DeathCause.quit) {
    buf = "quit";
  } else {
    buf = "killed by ";
    String name =
        monsterNames[monster!.ichar.codeUnitAt(0) - 'A'.codeUnitAt(0)];
    if (isVowel(name[0])) {
      buf += "an ";
    } else {
      buf += "a ";
    }
    buf += name;
  }

  buf += " with ${rogue.gold} gold";
  await message(buf, 0);
  await message("", 0);
  await score(monster, other);

  exit(0);
}

Future<void> win() async {
  rogue.armor = null;
  rogue.weapon = null;

  ui.clearScreen();
  ui.move(10, 11);
  ui.write("@   @  @@@   @   @      @  @  @   @@@   @   @   @");
  ui.move(11, 11);
  ui.write(" @ @  @   @  @   @      @  @  @  @   @  @@  @   @");
  ui.move(12, 11);
  ui.write("  @   @   @  @   @      @  @  @  @   @  @ @ @   @");
  ui.move(13, 11);
  ui.write("  @   @   @  @   @      @  @  @  @   @  @  @@");
  ui.move(14, 11);
  ui.write("  @    @@@    @@@        @@ @@    @@@   @   @   @");
  ui.move(17, 11);
  ui.write("Congratulations,  you have  been admitted  to  the");
  ui.move(18, 11);
  ui.write("Fighter's Guild.   You return home,  sell all your");
  ui.move(19, 11);
  ui.write("treasures at great profit and retire into comfort.");

  await message("", 0);
  await message("", 0);
  idAll();
  await sellPack();
  await score(null, DeathCause.win);

  exit(0);
}

Future<void> quit() async {
  await message("really quit?", 1);
  String ch = await ui.getchar();
  if (ch != 'y') {
    checkMessage();
    return;
  }

  checkMessage();
  await killedBy(null, DeathCause.quit);
}

Future<void> score(GameObject? monster, DeathCause other) async {
  await putScores(monster, other);
}

Future<void> putScores(GameObject? monster, DeathCause other) async {
  List<String> scores = List.filled(10, "");

  File f;
  try {
    f = File(scoreFile);
    if (!f.existsSync()) {
      f.createSync();
    }
  } catch (e) {
    await message("Cannot access score file: $e", 1);
    return;
  }

  int rank = 10;
  bool dontInsert = false;
  int i = 0;

  try {
    List<String> lines = f.readAsLinesSync();
    while (i < 10 && i < lines.length) {
      scores[i] = lines[i];

      if (scores[i].length < 18) {
        await message("error in score file format", 1);
        cleanUp("sorry, score file is out of order");
      }

      if (ncmp(scores[i].substring(16), playerName)) {
        int s = int.parse(scores[i].substring(8, 16));
        if (s <= rogue.gold) {
          continue;
        }
        dontInsert = true;
      }

      i++;
    }

    if (!dontInsert) {
      for (int j = 0; j < i; j++) {
        if (rank > 9) {
          int s = int.tryParse(scores[j].substring(8, 16)) ?? 0;
          if (s <= rogue.gold) {
            rank = j;
          }
        }
      }

      if (i == 0) {
        rank = 0;
      } else if (i < 10 && rank > 9) {
        rank = i;
      }

      if (rank <= 9) {
        insertScore(scores, rank, i, monster, other);
        if (i < 10) {
          i += 1;
        }
      }

      // Clear file before writing new scores
      f.writeAsStringSync("");
    }

    ui.clearScreen();
    ui.move(3, 30);
    ui.write("Top  Ten  Rogueists");
    ui.move(8, 0);
    ui.write("Rank    Score   Name");

    for (int j = 0; j < i; j++) {
      bool isRankHighlighted = j == rank;

      scores[j] = "${j + 1}".padLeft(2) + scores[j].substring(2);
      ui.move(j + 10, 0);

      if (isRankHighlighted) {
        ui.write(scores[j], inverse: true);
      } else {
        ui.write(scores[j]);
      }

      if (rank < 10) {
        f.writeAsStringSync('${scores[j]}\n', mode: FileMode.append);
      }
    }

    ui.refresh();
  } catch (e) {
    await message("Error processing scores: $e", 1);
  }

  await waitForAck("");
  cleanUp("");
}

void insertScore(
  List<String> scores,
  int rank,
  int n,
  GameObject? monster,
  DeathCause other,
) {
  for (int i = n - 1; i >= rank; i--) {
    if (i < 9) {
      scores[i + 1] = scores[i];
    }
  }

  String buf =
      "${"${rank + 1}".padLeft(2)}${"      ${rogue.gold}".padLeft(7)}   $playerName: ";

  if (other == DeathCause.hypothermia) {
    buf += "died of hypothermia";
  } else if (other == DeathCause.starvation) {
    buf += "died of starvation";
  } else if (other == DeathCause.quit) {
    buf += "quit";
  } else if (other == DeathCause.win) {
    buf += "a total winner";
  } else {
    buf += "killed by ";
    String name =
        monsterNames[monster!.ichar.codeUnitAt(0) - 'A'.codeUnitAt(0)];
    if (isVowel(name[0])) {
      buf += "an ";
    } else {
      buf += "a ";
    }
    buf += name;
  }

  buf += " on level $maxLevel ";
  if (other != DeathCause.win && hasAmulet) {
    buf += "with amulet";
  }

  scores[rank] = buf;
}

bool isVowel(String ch) {
  return "aeiou".contains(ch.toLowerCase());
}

bool ncmp(String s1, String s2) {
  return s1.split(':')[0].trim() == s2;
}

void idAll() {
  for (int i = 0; i < ScrollType.values.length; i++) {
    idScrolls[i].idStatus = IdStatus.identified;
  }
  for (int i = 0; i < WeaponType.values.length; i++) {
    idWeapons[i].idStatus = IdStatus.identified;
  }
  for (int i = 0; i < ArmorType.values.length; i++) {
    idArmors[i].idStatus = IdStatus.identified;
  }
  for (int i = 0; i < WandType.values.length; i++) {
    idWands[i].idStatus = IdStatus.identified;
  }
  for (int i = 0; i < PotionType.values.length; i++) {
    idPotions[i].idStatus = IdStatus.identified;
  }
}

Future<void> sellPack() async {
  int rows = 2;

  ui.clearScreen();

  for (GameObject obj in rogue.pack) {
    ui.move(1, 0);
    ui.write("Value      Item");

    if (obj.whatIs != Cell.food) {
      obj.identified = 1;
      int val = getValue(obj);
      rogue.gold += val;

      if (rows < sRows) {
        ui.move(rows, 0);
        ui.write("${"$val".padLeft(5)}      ${getDescription(obj)}");
        rows += 1;
      }
    }
  }

  ui.refresh();
  await message("", 0);
}

int getValue(GameObject obj) {
  int k = obj.whichKind;
  int val = 0;

  if (k == Cell.weapon) {
    val = idWeapons[k].value;
    if (k == WeaponType.arrow.index || k == WeaponType.shuriken.index) {
      val *= obj.quantity;
    }
    val += obj.damageEnchantment * 85;
    val += obj.toHitEnchantment * 85;
  } else if (k == Cell.armor) {
    val = idArmors[k].value;
    val += obj.damageEnchantment * 75;
    if (obj.isProtected != 0) {
      val += 200;
    }
  } else if (k == Cell.wand) {
    val = idWands[k].value * obj.clasz;
  } else if (k == Cell.scroll) {
    val = idScrolls[k].value * obj.quantity;
  } else if (k == Cell.potion) {
    val = idPotions[k].value * obj.quantity;
  } else if (k == Cell.amulet) {
    val = 5000;
  }

  return val > 10 ? val : 10;
}
