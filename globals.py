# global constants and variables, without `g` prefix for convenience

# monster.h
MONSTERS = 26

HASTED = 001
SLOWED = 002
IS_INVIS = 004
IS_ASLEEP = 010
WAKENS = 020
WANDERS = 040
FLIES = 0100
FLITS = 0200
CAN_GO = 0400

MAXMONSTER = 26

WAKE_PERCENT = 45
FLIT_PERCENT = 33
PARTY_WAKE_PERCENT = 75

XEROC1 = 16	# levels xeroc appears at
XEROC2 = 25

HYPOTHERMIA = 1
STARVATION = 2
QUIT = 3
WIN = 4

# move.h
UP = 0
UPRIGHT = 1
RIGHT = 2
RIGHTDOWN = 3
DOWN = 4
DOWNLEFT = 5
LEFT = 6
LEFTUP = 7

ROW1 = 7
ROW2 = 15

COL1 = 26
COL2 = 52

MOVED = 0
MOVE_FAILED = -1
STOPPED_ON_SOMETHING = -2
CANCEL = '\033'
LIST = '*'

HUNGRY = 300
WEAK = 120
FAINT = 20
STARVE = 0

MIN_ROW = 1

# object.h
BLANK    =      00
ARMOR    =      01
WEAPON   =      02
SCROLL   =      04
POTION   =     010
GOLD     =     020
FOOD     =     040
WAND     =    0100
STAIRS   =    0200
AMULET   =    0400
MONSTER  =   01000
HORWALL  =   02000
VERTWALL =   04000
DOOR     =  010000
FLOOR    =  020000
TUNNEL   =  040000
UNUSED   = 0100000

IS_OBJECT = 0777
CAN_PICK_UP = 0577

LEATHER = 0
RING = 1
SCALE = 2
CHAIN = 3
BANDED = 4
SPLINT = 5
PLATE = 6
ARMORS = 7

BOW = 0
ARROW = 1
SHURIKEN = 2
MACE = 3
LONG_SWORD = 4
TWO_HANDED_SWORD = 5
WEAPONS = 6

MAX_PACK_COUNT = 24

PROTECT_ARMOR = 0
HOLD_MONSTER = 1
ENCHANT_WEAPON = 2
ENCHANT_ARMOR = 3
IDENTIFY = 4
TELEPORT = 5
SLEEP = 6
SCARE_MONSTER = 7
REMOVE_CURSE = 8
CREATE_MONSTER = 9
AGGRAVATE_MONSTER = 10
SCROLLS = 11

INCREASE_STRENGTH = 0
RESTORE_STRENGTH = 1
HEALING = 2
EXTRA_HEALING = 3
POISON = 4
RAISE_LEVEL = 5
BLINDNESS = 6
HALLUCINATION = 7
DETECT_MONSTER = 8
DETECT_OBJECTS = 9
CONFUSION = 10
POTIONS = 11

TELEPORT_AWAY = 0
SLOW_MONSTER = 1
KILL_MONSTER = 2
INVISIBILITY = 3
POLYMORPH = 4
HASTE_MONSTER = 5
PUT_TO_SLEEP = 6
DO_NOTHING = 7
WANDS = 8

UNIDENTIFIED = 0
IDENTIFIED = 1
CALLED = 2

SROWS = 24
SCOLS = 80

MAX_TITLE_LENGTH = 30
MORE = "-more-"
MAXSYLLABLES = 40
MAXMETALS = 15

GOLD_PERCENT = 46

class identity:
    def __init__(self, value, title, real, id_status):
        self.value = value
        self.title = title
        self.real = real
        self.id_status = id_status
        
class object:
    def __init__(self, m_flags, damage, quantity, ichar, kill_exp, is_protected, is_cursed, clasz, identified, which_kind):
        self.m_flags = m_flags              # monster flags
        self.damage = damage                # damage it does
        self.quantity = quantity            # hit points to kill
        self.ichar = ichar                  # 'A' is for aquatar
        self.kill_exp = kill_exp            # exp for killing it
        self.is_protected = is_protected    # level starts
        self.is_cursed = is_cursed          # level ends
        self.clasz = clasz                  # chance of hitting you
        self.identified = identified        # F%d/Arwarn/Og/If/Mc/Xc
        self.which_kind = which_kind        # item carry/drop %
        self.row, self.col = 0, 0           # current row,col
        self.damage_enchantment = 0         # fly-trap,medusa,etc
        self.quiver = 0                     # monster slowed toggle
        self.trow, self.tcol = 0, 0         # target row, col
        self.to_hit_enchantment = 0
        self.what_is = 0
        self.picked_up = 0
        self.next_object = None             # next monster
        
    def copy(self):
        import copy
        return copy.copy(self)

class objholder:
    def __init__(self):
        self.next_object = None

class fighter:
    def __init__(self):
        self.armor = None           # object
        self.weapon = None          # object
        self.hp_current = 12        # short
        self.hp_max = 12            # short
        self.strength_current = 16  # char
        self.strength_max = 16      # char
        self.pack = objholder()     # object
        self.gold = 0               # int
        self.exp = 1                # char
        self.exp_points = 0         # int
        self.row = 0                # short
        self.col = 0                # short
        self.fchar = '@'            # char
        self.moves_left = 1200      # short

class door:
    def __init__(self):
        self.other_room = 0         # char
        self.other_row = 0          # char
        self.other_col = 0          # char

class room:
    def __init__(self):
        self.bottom_row = 0         # char
        self.right_col = 0          # char
        self.left_col = 0           # char
        self.top_row = 0            # char
        self.width = 0              # char
        self.height = 0             # char
        self.doors = [door() for i in range(4)]
        self.is_room = False        # char

# room.h
MAXROOMS = 9

NO_ROOM  = -1
DEAD_END = -2
PASSAGE  = -3

AMULET_LEVEL = 26

# monster.c
monster_names = [
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
    "zombie"
]

monster_tab = [
    object((IS_ASLEEP|WAKENS|WANDERS),"0d0",25,'A',20,9,18,100,0,0),
    object((IS_ASLEEP|WANDERS|FLITS),"1d3",10,'B',2,1,8,60,0,0),
    object((IS_ASLEEP|WANDERS),"3d3/2d5",30,'C',15,7,16,85,0,10),
    object((IS_ASLEEP|WAKENS),"4d5/3d9",128,'D',5000,21,126,100,0,90),
    object((IS_ASLEEP|WAKENS),"1d3",11,'E',2,1,7,65,0,0),
    object((0),"0d0",32,'F',91,12,126,80,0,0),
    object((IS_ASLEEP|WAKENS|WANDERS|FLIES),"5d4/4d5",92,'G',2000,20,126,85,0,10),
    object((IS_ASLEEP|WAKENS|WANDERS),"1d3/1d3",17,'H',3,1,10,67,0,0),
    object((IS_ASLEEP),"0d0",15,'I',5,2,11,68,0,0),
    object((IS_ASLEEP|WANDERS),"3d10/3d4",125,'J',3000,21,126,100,0,0),
    object((IS_ASLEEP|WAKENS|WANDERS|FLIES),"1d4",10,'K',2,1,6,60,0,0),
    object((IS_ASLEEP),"0d0",25,'L',18,6,16,75,0,0),
    object((IS_ASLEEP|WAKENS|WANDERS),"4d4/3d7",92,'M',250,18,126,85,0,25),
    object((IS_ASLEEP),"0d0",25,'N',37,10,19,75,0,100),
    object((IS_ASLEEP|WANDERS|WAKENS),"1d6",25,'O',5,4,13,70,0,10),
    object((IS_ASLEEP|IS_INVIS|WANDERS|FLITS),"5d4",76,'P',120,15,23,80,0,50),
    object((IS_ASLEEP|WAKENS|WANDERS),"3d5",30,'Q',20,8,17,78,0,20),
    object((IS_ASLEEP|WAKENS|WANDERS),"2d5",19,'R',10,3,12,70,0,0),
    object((IS_ASLEEP|WAKENS|WANDERS),"1d3",8,'S',2,1,9,50,0,0),
    object((IS_ASLEEP|WAKENS|WANDERS),"4d6",64,'T',125,13,22,75,0,33),
    object((IS_ASLEEP|WAKENS|WANDERS),"4d9",88,'U',200,17,26,85,0,33),
    object((IS_ASLEEP|WAKENS|WANDERS),"1d14",40,'V',350,19,126,85,0,18),
    object((IS_ASLEEP|WANDERS),"2d7",42,'W',55,14,23,75,0,0),
    object((IS_ASLEEP),"4d6",42,'X',110,XEROC1,XEROC2,75,0,0),
    object((IS_ASLEEP|WANDERS),"3d6",33,'Y',50,11,20,80,0,20),
    object((IS_ASLEEP|WAKENS|WANDERS),"1d7",20,'Z',8,5,14,69,0,0),
]

# object.c
id_potions = [
    identity(100, "blue ", "of increase strength ", 0),
    identity(250, "red ", "of restore strength ",0),
    identity(100, "green ", "of healing ",0),
    identity(200, "grey ", "of extra healing ",0),
    identity( 10, "brown ", "of poison ",0),
    identity(300, "clear ", "of raise level ",0),
    identity( 10, "pink ", "of blindness ",0),
    identity( 25, "white ", "of hallucination ",0),
    identity(100, "purple ", "of detect monster ",0),
    identity(100, "black ", "of detect things ",0),
    identity( 10, "yellow ", "of confusion ",0)
]

id_scrolls = [
    identity(505, "", "of protect armor ", 0),
    identity(200, "", "of hold monster ", 0),
    identity(235, "", "of enchant weapon ", 0),
    identity(235, "", "of enchant armor ", 0),
    identity(175, "", "of identify ", 0),
    identity(190, "", "of teleportation ", 0),
    identity( 25, "", "of sleep ", 0),
    identity(610, "", "of scare monster ", 0),
    identity(210, "", "of remove curse ", 0),
    identity(100, "", "of create monster ",0),
    identity( 25, "", "of aggravate monster ",0)
]

id_weapons = [
    identity(150, "short bow ", "", 0),
    identity( 15, "arrows ", "", 0),
    identity( 35, "shurikens ", "", 0),
    identity(370, "mace ", "", 0),
    identity(480, "long sword ", "", 0),
    identity(590, "two-handed sword ", "", 0)
]

id_armors = [
    identity(300, "leather armor ", "", (UNIDENTIFIED)),
    identity(300, "ring mail ", "", (UNIDENTIFIED)),
    identity(400, "scale mail ", "", (UNIDENTIFIED)),
    identity(500, "chain mail ", "", (UNIDENTIFIED)),
    identity(600, "banded mail ", "", (UNIDENTIFIED)),
    identity(600, "splint mail ", "", (UNIDENTIFIED)),
    identity(700, "plate mail ", "", (UNIDENTIFIED))
]

id_wands = [
    identity(25, "", "of teleport away ",0),
    identity(50, "", "of slow monster ", 0),
    identity(45, "", "of kill monster ",0),
    identity( 8, "", "of invisibility ",0),
    identity(55, "", "of polymorph ",0),
    identity( 2, "", "of haste monster ",0),
    identity(25, "", "of put to sleep ",0),
    identity( 0, "", "of do nothing ",0)
]

# object.c
screen = [[0] * SCOLS for i in range(SROWS)]

rogue = fighter()

# room.c
rooms = [room() for i in range(MAXROOMS)]


# all global variables are collected in `g` so that I don't have to use "global"
class G:
    pass

g = G()

del G

# hit.py
g.fight_monster = None # todo used only in hit.py
g.detect_monster = 0
g.hit_message = ""

# init.py
g.player_name = ""
g.cant_int = 0
g.did_int = 0

# level.py
g.current_level = 0
g.max_level = 1
g.hunger_str = ""
g.party_room = 0

# message.py
g.message_cleared = 1 # todo used only in message.py
g.message_line = ""   # todo used only in message.py
g.message_col = 0     # todo used only in message.py

# monster.py
g.level_monsters = objholder()

# object.py
g.level_objects = objholder()
g.has_amulet = 0
g.foods = 0 # todo used only in object.py

# pack.py
g.ichars = [0] * 26

# play.py
g.interrupted = 0

# room.py
g.current_room = 0

# special_hit.py
g.being_held = 0

# use.py
g.halluc = 0
g.blind = 0
g.confused = 0
g.detect_monster = 0

# random.c
import random

def srandom(x):
    random.seed(x)

def get_rand(x, y):
    return random.randint(x, y)

def rand_percent(percentage):
    return get_rand(1, 100) <= percentage

# all those imports
from hit import *
from init import *
from inventory import *
from level import *
from message import *
from monster import *
from move import *
from object import *
from pack import *
from play import *
from room import *
from score import *
from special_hit import *
from throw import *
from ui import *
from use import *
from zap import *
