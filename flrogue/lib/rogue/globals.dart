import 'dart:math';

// Direction constants converted to enum
enum Direction { up, upRight, right, rightDown, down, downLeft, left, leftUp }

// Monster flags - converted to extension methods for bitwise operations
extension MonsterFlags on int {
  static const int hasted = 0x001;
  static const int slowed = 0x002;
  static const int isInvis = 0x004;
  static const int isAsleep = 0x010;
  static const int wakens = 0x020;
  static const int wanders = 0x040;
  static const int flies = 0x0100;
  static const int flits = 0x0200;
  static const int canGo = 0x0400;

  // bool get isHasted => (this & hasted) != 0;
  // bool get isSlowed => (this & slowed) != 0;
  // bool get isInvisible => (this & isInvis) != 0;
  // bool get isAsleep => (this & asleep) != 0;
  // bool get isWakens => (this & wakens) != 0;
  // bool get isWanders => (this & wanders) != 0;
  // bool get isFlies => (this & flies) != 0;
  // bool get isFlits => (this & flits) != 0;
  // bool get isCanGo => (this & canGo) != 0;
}

// Death causes
enum DeathCause { hypothermia, starvation, quit, win }

// Cell types and objects
class Cell {
  static const int blank = 0x00;
  static const int armor = 0x01;
  static const int weapon = 0x02;
  static const int scroll = 0x04;
  static const int potion = 0x010;
  static const int gold = 0x020;
  static const int food = 0x040;
  static const int wand = 0x0100;
  static const int stairs = 0x0200;
  static const int amulet = 0x0400;
  static const int monster = 0x01000;
  static const int horWall = 0x02000;
  static const int vertWall = 0x04000;
  static const int door = 0x010000;
  static const int floor = 0x020000;
  static const int tunnel = 0x040000;
  static const int unused = 0x0100000;

  static const int isObject = 0x777;
  static const int canPickUp = 0x577;
}

// Constants for armor types
enum ArmorType { leather, ring, scale, chain, banded, splint, plate }

// Constants for weapon types
enum WeaponType { bow, arrow, shuriken, mace, longSword, twoHandedSword }

// Constants for scroll types
enum ScrollType {
  protectArmor,
  holdMonster,
  enchantWeapon,
  enchantArmor,
  identify,
  teleport,
  sleep,
  scareMonster,
  removeCurse,
  createMonster,
  aggravateMonster,
}

// Constants for potion types
enum PotionType {
  increaseStrength,
  restoreStrength,
  healing,
  extraHealing,
  poison,
  raiseLevel,
  blindness,
  hallucination,
  detectMonster,
  detectObjects,
  confusion,
}

// Constants for wand types
enum WandType {
  teleportAway,
  slowMonster,
  killMonster,
  invisibility,
  polymorph,
  hasteMonster,
  putToSleep,
  doNothing,
}

// Game constants
const int maxPackCount = 24;
const int maxRooms = 9;
const int noRoom = -1;
const int deadEnd = -2;
const int passage = -3;
const int amuletLevel = 26;
const int monsterCount = 26;
const int wakePercent = 45;
const int flitPercent = 33;
const int partyWakePercent = 75;
const int xeroc1 = 16;
const int xeroc2 = 25;

// Movement constants
const int hungry = 300;
const int weak = 120;
const int faint = 20;
const int starve = 0;
const int minRow = 1;
const int row1 = 7;
const int row2 = 15;
const int col1 = 26;
const int col2 = 52;

// Room constants
const int sRows = 24;
const int sCols = 80;
const int maxTitleLength = 30;
const String more = "-more-";
const int maxSyllables = 40;
const int maxMetals = 15;
const int goldPercent = 46;

// Movement status
const int moved = 0;
const int moveFailed = -1;
const int stoppedOnSomething = -2;
const String cancel = '\u001b'; // ESC character
const String list = '*';

// Identification status
enum IdStatus { unidentified, identified, called }

// Identity class for items
class Identity {
  int value;
  String title;
  String real;
  IdStatus idStatus;

  Identity(this.value, this.title, this.real, this.idStatus);
}

// Object class for game entities
class GameObject {
  int mFlags = 0;
  String damage = "";
  int quantity = 1;
  String ichar = 'L';
  int killExp = 0;
  int isProtected = 0;
  int isCursed = 0;
  int clasz = 0;
  int identified = 0;
  int whichKind = 0;
  int row = 0;
  int col = 0;
  int damageEnchantment = 0;
  int quiver = 0;
  int trow = 0;
  int tcol = 0;
  int toHitEnchantment = 0;
  int whatIs = 0;
  int pickedUp = 0;

  GameObject(
    this.mFlags,
    this.damage,
    this.quantity,
    this.ichar,
    this.killExp,
    this.isProtected,
    this.isCursed,
    this.clasz,
    this.identified,
    this.whichKind,
  );

  GameObject copy() {
    GameObject obj = GameObject(
      mFlags,
      damage,
      quantity,
      ichar,
      killExp,
      isProtected,
      isCursed,
      clasz,
      identified,
      whichKind,
    );
    obj.row = row;
    obj.col = col;
    obj.damageEnchantment = damageEnchantment;
    obj.quiver = quiver;
    obj.trow = trow;
    obj.tcol = tcol;
    obj.toHitEnchantment = toHitEnchantment;
    obj.whatIs = whatIs;
    obj.pickedUp = pickedUp;
    return obj;
  }
}

// Fighter class for the player
class Fighter {
  GameObject? armor;
  GameObject? weapon;
  int hpCurrent = 12;
  int hpMax = 12;
  int strengthCurrent = 16;
  int strengthMax = 16;
  List<GameObject> pack = [];
  int gold = 0;
  int exp = 1;
  int expPoints = 0;
  int row = 0;
  int col = 0;
  String fchar = '@';
  int movesLeft = 1200;

  Fighter();
}

// Door class
class Door {
  int otherRoom = 0;
  int otherRow = 0;
  int otherCol = 0;

  Door();
}

// Room class
class Room {
  int bottomRow = 0;
  int rightCol = 0;
  int leftCol = 0;
  int topRow = 0;
  int width = 0;
  int height = 0;
  List<Door> doors = List.generate(4, (_) => Door());
  bool isRoom = false;

  Room();
}

// Monster names
const monsterNames = [
  "aquatar",
  "bat",
  "centaur",
  "dragon",
  "emu",
  "venus fly-trap",
  "griffin",
  "hobgoblin",
  "ice monster",
  "jabberwock",
  "kestrel",
  "leprechaun",
  "medusa",
  "nymph",
  "orc",
  "phantom",
  "quasit",
  "rattlesnake",
  "snake",
  "troll",
  "black unicorn",
  "vampire",
  "wraith",
  "xeroc",
  "yeti",
  "zombie",
];

// Monster definitions
final List<GameObject> monsterTab = [
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "0d0",
    25,
    'A',
    20,
    9,
    18,
    100,
    0,
    0,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wanders | MonsterFlags.flits),
    "1d3",
    10,
    'B',
    2,
    1,
    8,
    60,
    0,
    0,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wanders),
    "3d3/2d5",
    30,
    'C',
    15,
    7,
    16,
    85,
    0,
    10,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens),
    "4d5/3d9",
    128,
    'D',
    5000,
    21,
    126,
    100,
    0,
    90,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens),
    "1d3",
    11,
    'E',
    2,
    1,
    7,
    65,
    0,
    0,
  ),
  GameObject(0, "0d0", 32, 'F', 91, 12, 126, 80, 0, 0),
  GameObject(
    (MonsterFlags.isAsleep |
        MonsterFlags.wakens |
        MonsterFlags.wanders |
        MonsterFlags.flies),
    "5d4/4d5",
    92,
    'G',
    2000,
    20,
    126,
    85,
    0,
    10,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "1d3/1d3",
    17,
    'H',
    3,
    1,
    10,
    67,
    0,
    0,
  ),
  GameObject((MonsterFlags.isAsleep), "0d0", 15, 'I', 5, 2, 11, 68, 0, 0),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wanders),
    "3d10/3d4",
    125,
    'J',
    3000,
    21,
    126,
    100,
    0,
    0,
  ),
  GameObject(
    (MonsterFlags.isAsleep |
        MonsterFlags.wakens |
        MonsterFlags.wanders |
        MonsterFlags.flies),
    "1d4",
    10,
    'K',
    2,
    1,
    6,
    60,
    0,
    0,
  ),
  GameObject((MonsterFlags.isAsleep), "0d0", 25, 'L', 18, 6, 16, 75, 0, 0),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "4d4/3d7",
    92,
    'M',
    250,
    18,
    126,
    85,
    0,
    25,
  ),
  GameObject((MonsterFlags.isAsleep), "0d0", 25, 'N', 37, 10, 19, 75, 0, 100),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wanders | MonsterFlags.wakens),
    "1d6",
    25,
    'O',
    5,
    4,
    13,
    70,
    0,
    10,
  ),
  GameObject(
    (MonsterFlags.isAsleep |
        MonsterFlags.isInvis |
        MonsterFlags.wanders |
        MonsterFlags.flits),
    "5d4",
    76,
    'P',
    120,
    15,
    23,
    80,
    0,
    50,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "3d5",
    30,
    'Q',
    20,
    8,
    17,
    78,
    0,
    20,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "2d5",
    19,
    'R',
    10,
    3,
    12,
    70,
    0,
    0,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "1d3",
    8,
    'S',
    2,
    1,
    9,
    50,
    0,
    0,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "4d6",
    64,
    'T',
    125,
    13,
    22,
    75,
    0,
    33,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "4d9",
    88,
    'U',
    200,
    17,
    26,
    85,
    0,
    33,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "1d14",
    40,
    'V',
    350,
    19,
    126,
    85,
    0,
    18,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wanders),
    "2d7",
    42,
    'W',
    55,
    14,
    23,
    75,
    0,
    0,
  ),
  GameObject(
    (MonsterFlags.isAsleep),
    "4d6",
    42,
    'X',
    110,
    xeroc1,
    xeroc2,
    75,
    0,
    0,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wanders),
    "3d6",
    33,
    'Y',
    50,
    11,
    20,
    80,
    0,
    20,
  ),
  GameObject(
    (MonsterFlags.isAsleep | MonsterFlags.wakens | MonsterFlags.wanders),
    "1d7",
    20,
    'Z',
    8,
    5,
    14,
    69,
    0,
    0,
  ),
];

// Item identification tables
final List<Identity> idPotions = [
  Identity(100, "blue ", "of increase strength ", IdStatus.unidentified),
  Identity(250, "red ", "of restore strength ", IdStatus.unidentified),
  Identity(100, "green ", "of healing ", IdStatus.unidentified),
  Identity(200, "grey ", "of extra healing ", IdStatus.unidentified),
  Identity(10, "brown ", "of poison ", IdStatus.unidentified),
  Identity(300, "clear ", "of raise level ", IdStatus.unidentified),
  Identity(10, "pink ", "of blindness ", IdStatus.unidentified),
  Identity(25, "white ", "of hallucination ", IdStatus.unidentified),
  Identity(100, "purple ", "of detect monster ", IdStatus.unidentified),
  Identity(100, "black ", "of detect things ", IdStatus.unidentified),
  Identity(10, "yellow ", "of confusion ", IdStatus.unidentified),
];

final List<Identity> idScrolls = [
  Identity(505, "", "of protect armor ", IdStatus.unidentified),
  Identity(200, "", "of hold monster ", IdStatus.unidentified),
  Identity(235, "", "of enchant weapon ", IdStatus.unidentified),
  Identity(235, "", "of enchant armor ", IdStatus.unidentified),
  Identity(175, "", "of identify ", IdStatus.unidentified),
  Identity(190, "", "of teleportation ", IdStatus.unidentified),
  Identity(25, "", "of sleep ", IdStatus.unidentified),
  Identity(610, "", "of scare monster ", IdStatus.unidentified),
  Identity(210, "", "of remove curse ", IdStatus.unidentified),
  Identity(100, "", "of create monster ", IdStatus.unidentified),
  Identity(25, "", "of aggravate monster ", IdStatus.unidentified),
];

final List<Identity> idWeapons = [
  Identity(150, "short bow ", "", IdStatus.unidentified),
  Identity(15, "arrows ", "", IdStatus.unidentified),
  Identity(35, "shurikens ", "", IdStatus.unidentified),
  Identity(370, "mace ", "", IdStatus.unidentified),
  Identity(480, "long sword ", "", IdStatus.unidentified),
  Identity(590, "two-handed sword ", "", IdStatus.unidentified),
];

final List<Identity> idArmors = [
  Identity(300, "leather armor ", "", IdStatus.unidentified),
  Identity(300, "ring mail ", "", IdStatus.unidentified),
  Identity(400, "scale mail ", "", IdStatus.unidentified),
  Identity(500, "chain mail ", "", IdStatus.unidentified),
  Identity(600, "banded mail ", "", IdStatus.unidentified),
  Identity(600, "splint mail ", "", IdStatus.unidentified),
  Identity(700, "plate mail ", "", IdStatus.unidentified),
];

final List<Identity> idWands = [
  Identity(25, "", "of teleport away ", IdStatus.unidentified),
  Identity(50, "", "of slow monster ", IdStatus.unidentified),
  Identity(45, "", "of kill monster ", IdStatus.unidentified),
  Identity(8, "", "of invisibility ", IdStatus.unidentified),
  Identity(55, "", "of polymorph ", IdStatus.unidentified),
  Identity(2, "", "of haste monster ", IdStatus.unidentified),
  Identity(25, "", "of put to sleep ", IdStatus.unidentified),
  Identity(0, "", "of do nothing ", IdStatus.unidentified),
];

// Screen cells
List<List<int>> screen = List.generate(sRows, (_) => List.filled(sCols, 0));

// Fighter instance for the player
Fighter rogue = Fighter();

// Room instances
List<Room> rooms = List.generate(maxRooms, (_) => Room());

// Random functions
Random _random = Random();

void srandom(int seed) {
  _random = Random(seed);
}

int getRand(int min, int max) {
  return min + _random.nextInt(max - min + 1);
}

bool randPercent(int percentage) {
  return getRand(1, 100) <= percentage;
}

// Global game state
GameObject? fightMonster;
bool detectMonster = false;
String hitMessage = "";

String playerName = "";
bool cantInt = false;
bool didInt = false;
Exception? exc;

int currentLevel = 0;
int maxLevel = 1;
String hungerStr = "";
int partyRoom = 0;

bool messageCleared = true;
String messageLine = "";
int messageCol = 0;

List<GameObject> levelMonsters = [];

List<GameObject> levelObjects = [];
bool hasAmulet = false;
int foods = 0;

List<bool> ichars = List.filled(26, false);

bool interrupted = false;

int currentRoom = 0;

bool beingHeld = false;

int halluc = 0;
int blind = 0;
int confused = 0;

// Level points for experience progression
const levelPoints = [
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
