// rogue/inventory.dart

import 'package:flrogue/rogue/pack.dart';

import 'globals.dart';
import 'object.dart';
import 'ui.dart';
import 'message.dart';

List<String> metals = [
  "steel ",
  "bronze ",
  "gold ",
  "silver ",
  "copper ",
  "nickel ",
  "cobalt ",
  "tin ",
  "iron ",
  "magnesium ",
  "chrome ",
  "carbon ",
  "platinum ",
  "silicon ",
  "titanium ",
];

List<String> syllables = [
  "blech ",
  "foo ",
  "barf ",
  "rech ",
  "bar ",
  "blech ",
  "quo ",
  "bloto ",
  "woh ",
  "caca ",
  "blorp ",
  "erp ",
  "festr ",
  "rot ",
  "slie ",
  "snorf ",
  "iky ",
  "yuky ",
  "ooze ",
  "ah ",
  "bahl ",
  "zep ",
  "druhl ",
  "flem ",
  "behil ",
  "arek ",
  "mep ",
  "zihr ",
  "grit ",
  "kona ",
  "kini ",
  "ichi ",
  "niah ",
  "ogr ",
  "ooh ",
  "ighr ",
  "coph ",
  "swerr ",
  "mihln ",
  "poxi ",
];

void initItems() {
  shuffleColors();
  mixMetals();
  makeScrollTitles();
}

void inventory(ObjectHolder pack, int mask) {
  int i = 0;
  int maxlen = 27;
  List<String> descriptions = List.filled(maxPackCount + 1, "");

  GameObject? obj = pack.nextObject;
  while (obj != null) {
    if (obj.whatIs & mask != 0) {
      descriptions[i] = " ${obj.ichar}) ${getDescription(obj)}";
      maxlen =
          maxlen > descriptions[i].length ? maxlen : descriptions[i].length;
      i++;
    }
    obj = obj.nextObject;
  }

  descriptions[i] = " --press space to continue--";
  int col = ui.cols - maxlen - 2;

  int row = 0;
  while (row <= i && row < sRows) {
    if (row > 0) {
      String d = "";
      for (int j = col; j < ui.cols; j++) {
        d += ui.read(row, j, 1);
      }
      descriptions[row - 1] = d;
    }

    ui.move(row, col);
    ui.write(descriptions[row]);
    ui.clearToEndOfLine();
    row++;
  }

  ui.refresh();
  waitForAck("");

  ui.move(0, 0);
  ui.clearToEndOfLine();

  for (int j = 1; j <= i; j++) {
    ui.move(j, col);
    ui.write(descriptions[j - 1]);
  }
}

void shuffleColors() {
  for (int i = 0; i < PotionType.values.length; i++) {
    int j = getRand(0, PotionType.values.length - 1);
    int k = getRand(0, PotionType.values.length - 1);

    String temp = idPotions[j].title;
    idPotions[j].title = idPotions[k].title;
    idPotions[k].title = temp;
  }
}

void makeScrollTitles() {
  for (int i = 0; i < ScrollType.values.length; i++) {
    int sylls = getRand(2, 5);
    String title = "'";

    for (int j = 0; j < sylls; j++) {
      title += syllables[getRand(0, maxSyllables - 1)];
    }

    title = "${title.substring(0, title.length - 1)}' ";
    idScrolls[i].title = title;
  }
}

void mixMetals() {
  for (int i = 0; i < maxMetals; i++) {
    int j = getRand(0, maxMetals - 1);
    int k = getRand(0, maxMetals - 1);

    String temp = metals[j];
    metals[j] = metals[k];
    metals[k] = temp;
  }

  for (int i = 0; i < WandType.values.length; i++) {
    idWands[i].title = metals[i];
  }
}

Future<void> singleInventory() async {
  String ch = await getPackLetter("inventory what? ", Cell.isObject);

  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    message("No such item.", 0);
    return;
  }

  message("$ch) ${getDescription(obj)}", 0);
}
