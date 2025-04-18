import 'globals.dart';
import 'message.dart';
import 'object.dart';
import 'pack.dart';
import 'ui.dart';

List<String> _metals = [
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

List<String> _syllables = [
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
  _shuffleColors();
  _mixMetals();
  _makeScrollTitles();
}

Future<void> inventory(List<GameObject> pack, int mask) async {
  int i = 0;
  int maxlen = 27;
  List<String> descriptions = List.filled(maxPackCount + 1, "");

  for (GameObject obj in pack) {
    if (obj.whatIs & mask != 0) {
      descriptions[i] = " ${obj.ichar}) ${getDescription(obj)}";
      maxlen =
          maxlen > descriptions[i].length ? maxlen : descriptions[i].length;
      i++;
    }
  }

  descriptions[i] = " --press space to continue--";
  int col = ui.cols - maxlen - 2;

  int row = 0;
  while (row <= i && row < sRows) {
    if (row > 0) {
      String d = "";
      for (int j = col; j < ui.cols; j++) {
        d += ui.move(row, j).read();
      }
      descriptions[row - 1] = d;
    }

    ui.move(row, col).write(descriptions[row]);
    ui.clearToEndOfLine();
    row++;
  }

  ui.refresh();
  await waitForAck("");

  ui.move(0, 0).clearToEndOfLine();

  for (int j = 1; j <= i; j++) {
    ui.move(j, col).write(descriptions[j - 1]);
  }
}

void _shuffleColors() {
  for (int i = 0; i < PotionType.values.length; i++) {
    int j = getRand(0, PotionType.values.length - 1);
    int k = getRand(0, PotionType.values.length - 1);

    String temp = idPotions[j].title;
    idPotions[j].title = idPotions[k].title;
    idPotions[k].title = temp;
  }
}

void _makeScrollTitles() {
  for (int i = 0; i < ScrollType.values.length; i++) {
    int sylls = getRand(2, 5);
    String title = "'";

    for (int j = 0; j < sylls; j++) {
      title += _syllables[getRand(0, maxSyllables - 1)];
    }

    title = "${title.substring(0, title.length - 1)}' ";
    idScrolls[i].title = title;
  }
}

void _mixMetals() {
  for (int i = 0; i < maxMetals; i++) {
    int j = getRand(0, maxMetals - 1);
    int k = getRand(0, maxMetals - 1);

    String temp = _metals[j];
    _metals[j] = _metals[k];
    _metals[k] = temp;
  }

  for (int i = 0; i < WandType.values.length; i++) {
    idWands[i].title = _metals[i];
  }
}

Future<void> singleInventory() async {
  String ch = await getPackLetter("inventory what?", Cell.isObject);

  if (ch == cancel) {
    return;
  }

  GameObject? obj = getLetterObject(ch);
  if (obj == null) {
    await message("No such item.");
    return;
  }

  await message("$ch) ${getDescription(obj)}");
}
