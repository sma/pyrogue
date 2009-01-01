from globals import *

__all__ = ['put_objects', 'put_object_at', 'object_at', 'get_letter_object',
           'name_of', 'get_rand_object', 'get_food', 'put_stairs',
           'get_armor_class', 'get_an_object', 'show_objects', 'put_amulet']

def put_objects():
    if g.current_level < g.max_level: return
    
    n = get_rand(2, 4)
    if rand_percent(35): n += 1
    
    if rand_percent(50):
        id_weapons[SHURIKEN].title = "daggers "
    if rand_percent(5):
        make_party()
    for i in range(n):
        obj = get_rand_object()
        put_object_rand_location(obj)
        add_to_pack(obj, g.level_objects, 0)
    put_gold()

def put_gold():
    for i in range(MAXROOMS):
        r = rooms[i]
        if r.is_room and rand_percent(GOLD_PERCENT):
            for j in range(25):
                row = get_rand(r.top_row + 1, r.bottom_row - 1)
                col = get_rand(r.left_col + 1, r.right_col - 1)
                if screen[row][col] == FLOOR or screen[row][col] == PASSAGE:
                    put_gold_at(row, col)
                    break

def put_gold_at(row, col):
    obj = get_an_object()
    obj.row = row
    obj.col = col
    obj.what_is = GOLD
    obj.quantity = get_rand(2 * g.current_level, 16 * g.current_level)
    add_mask(row, col, GOLD)
    add_to_pack(obj, g.level_objects, 0)

def put_object_at(obj, row, col):
    obj.row = row
    obj.col = col
    add_mask(row, col, obj.what_is)
    add_to_pack(obj, g.level_objects, 0)

def object_at(pack, row, col):
    obj = pack.next_object
    while obj and (obj.row != row or obj.col != col):
        obj = obj.next_object
    return obj

def get_letter_object(ch):
    obj = rogue.pack.next_object
    while obj and obj.ichar != ch:
        obj = obj.next_object
    return obj

def name_of(obj):
    w = obj.what_is
    if w == SCROLL:
        return "scrolls " if obj.quantity > 1 else "scroll "
    if w == POTION:
        return "potions " if obj.quantity > 1 else "potion "
    if w == FOOD:
        return "rations " if obj.quantity > 1 else "ration "
    if w == WAND:
        return "wand "
    if w == WEAPON:
        k = obj.which_kind
        if k == ARROW:
            return "arrows " if obj.quantity > 1 else "arrow "
        if k == SHURIKEN:
            if id_weapons[k].title[0] == 'd':
                return "daggers " if obj.quantity > 1 else "dagger "
            else:
                return "shurikens " if obj.quantity > 1 else "shuriken "
        return id_weapons[k].title
    if w == ARMOR:
        return id_armors[obj.which_kind].title
    return "unknown "

def get_rand_object():
    obj = get_an_object()
    if g.foods < g.current_level / 2:
        obj.what_is = FOOD
    else:
        obj.what_is = get_rand_what_is()
    obj.identified = 0
    
    w = obj.what_is
    if w == SCROLL:
        get_rand_scroll(obj)
    elif w == POTION:
        get_rand_potion(obj)
    elif w == WEAPON:
        get_rand_weapon(obj)
    elif w == ARMOR:
        get_rand_armor(obj)
    elif w == WAND:
        get_rand_wand(obj)
    elif w == FOOD:
        g.foods += 1
        get_food(obj)
    
    return obj

def get_rand_what_is():
    percent = get_rand(1, 92)
    
    if percent <= 30:
        return SCROLL
    if percent <= 60:
        return POTION
    if percent <= 65:
        return WAND
    if percent <= 75:
        return WEAPON
    if percent <= 85:
        return ARMOR
    return FOOD

def get_rand_scroll(obj):
    percent = get_rand(0, 82)
    
    if percent <= 5:
        obj.which_kind = PROTECT_ARMOR
    elif percent <= 11:
        obj.which_kind = HOLD_MONSTER
    elif percent <= 20:
        obj.which_kind = CREATE_MONSTER
    elif percent <= 35:
        obj.which_kind = IDENTIFY
    elif percent <= 43:
        obj.which_kind = TELEPORT
    elif percent <= 52:
        obj.which_kind = SLEEP
    elif percent <= 57:
        obj.which_kind = SCARE_MONSTER
    elif percent <= 66:
        obj.which_kind = REMOVE_CURSE
    elif percent <= 71:
        obj.which_kind = ENCHANT_ARMOR
    elif percent <= 76:
        obj.which_kind = ENCHANT_WEAPON
    else:
        obj.which_kind = AGGRAVATE_MONSTER

def get_rand_potion(obj):
    percent = get_rand(1, 105)
    
    if percent <= 5:
        obj.which_kind = RAISE_LEVEL
    elif percent <= 15:
        obj.which_kind = DETECT_OBJECTS
    elif percent <= 25:
        obj.which_kind = DETECT_MONSTER
    elif percent <= 35:
        obj.which_kind = INCREASE_STRENGTH
    elif percent <= 45:
        obj.which_kind = RESTORE_STRENGTH
    elif percent <= 55:
        obj.which_kind = HEALING
    elif percent <= 65:
        obj.which_kind = EXTRA_HEALING
    elif percent <= 75:
        obj.which_kind = BLINDNESS
    elif percent <= 85:
        obj.which_kind = HALLUCINATION
    elif percent <= 95:
        obj.which_kind = CONFUSION
    else:
        obj.which_kind = POISON

def get_rand_weapon(obj):
    obj.which_kind = get_rand(0, WEAPONS - 1)
    
    if obj.which_kind == ARROW or obj.which_kind == SHURIKEN:
        obj.quantity = get_rand(3, 15)
        obj.quiver = get_rand(0, 126)
    else:
        obj.quantity = 1
    obj.identified = 0
    obj.to_hit_enchantment = 0
    obj.damage_enchantment = 0
    
    # notice, long swords are ALWAYS cursed or blessed
    percent = get_rand(1, 32 if obj.which_kind == LONG_SWORD else 96)
    blessing = get_rand(1, 3)
    obj.is_cursed = 0
    
    if percent <= 16:
        increment = 1
    elif percent <= 32:
        increment = -1
        obj.is_cursed = 1
    if percent <= 32:
        for i in range(blessing):
            if rand_percent(50):
                obj.to_hit_enchantment += increment
            else:
                obj.damage_enchantment += increment
    k = obj.which_kind
    if k == BOW:
        obj.damage = "1d2"
    elif k == ARROW:
        obj.damage = "1d2"
    elif k == SHURIKEN:
        obj.damage = "1d4"
    elif k == MACE:
        obj.damage = "2d3"
    elif k == LONG_SWORD:
        obj.damage = "3d4"
    elif k == TWO_HANDED_SWORD:
        obj.damage = "4d5"

def get_rand_armor(obj):
    obj.which_kind = get_rand(0, ARMORS - 1)
    obj.clasz = obj.which_kind + 2
    if obj.which_kind == PLATE or obj.which_kind == SPLINT:
        obj.clasz -= 1
    obj.is_cursed = 0
    obj.is_protected = 0
    obj.damage_enchantment = 0
    
    percent = get_rand(1, 100)
    blessing = get_rand(1, 3)
    
    if percent <= 16:
        obj.is_cursed = 1
        obj.damage_enchantment -= blessing
    elif percent <= 33:
        obj.damage_enchantment += blessing

def get_rand_wand(obj):
    obj.which_kind = get_rand(0, WANDS - 1)
    obj.clasz = get_rand(3, 7)

def get_food(obj):
    obj.which_kind = FOOD
    obj.what_is = FOOD

def put_stairs():
    row, col = get_rand_row_col(FLOOR | TUNNEL)
    screen[row][col] = STAIRS

def get_armor_class(obj):
    if obj:
        return obj.clasz + obj.damage_enchantment
    return 0

def get_an_object():
    return object(0, "", 1, 'L', 0, 0, 0, 0, 0, 0)

def make_party():
    g.party_room = get_rand_room()
    fill_room_with_monsters(g.party_room, fill_room_with_objects(g.party_room))

def show_objects():
    obj = g.level_objects.next_object
    while obj:
        mvaddch(obj.row, obj.col, get_room_char(obj.what_is, obj.row, obj.col))
        obj = obj.next_object

def put_amulet():
    obj = get_an_object()
    obj.what_is = AMULET
    put_object_rand_location(obj)
    add_to_pack(obj, g.level_objects, 0)

def put_object_rand_location(obj):
    row, col = get_rand_row_col(FLOOR | TUNNEL)
    add_mask(row, col, obj.what_is)
    obj.row = row
    obj.col = col
