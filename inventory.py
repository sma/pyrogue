from globals import *

__all__ = ['init_items', 'inventory', 'get_description', 'single_inventory', 'get_id_table']

metals = [
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
    "titanium "
]

syllables = [
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
    "poxi "
]

def init_items():
    shuffle_colors()
    mix_metals()
    make_scroll_titles()

def inventory(pack, mask):
    i = 0
    maxlen = 27
    descriptions = [""] * (MAX_PACK_COUNT + 1)
    
    obj = pack.next_object
    while obj:
        if obj.what_is & mask:
            descriptions[i] = " " + obj.ichar + ") " + get_description(obj)
            maxlen = max(maxlen, len(descriptions[i]))
            i += 1
        obj = obj.next_object
    descriptions[i] = " --press space to continue--"
    col = COLS - maxlen - 2
    
    row = 0
    while row <= i and row < SROWS:
        if row > 0:
            d = ""
            for j in range(col, COLS):
                d += mvinch(row, j)
            descriptions[row - 1] = d
        mvaddstr(row, col, descriptions[row])
        clrtoeol()
        row += 1
    refresh()
    wait_for_ack("")
    
    move(0, 0)
    clrtoeol()
    
    for j in range(1, i + 1):
        mvaddstr(j, col, descriptions[j - 1])

def shuffle_colors():
    for i in range(POTIONS):
        j = get_rand(0, POTIONS - 1)
        k = get_rand(0, POTIONS - 1)
        id_potions[j].title, id_potions[k].title = \
            id_potions[k].title, id_potions[j].title

def make_scroll_titles():
    for i in range(SCROLLS):
        sylls = get_rand(2, 5)
        title = "'"
        for j in range(sylls):
            title += syllables[get_rand(0, MAXSYLLABLES - 1)]
        title = title[:-1] + "' "
        id_scrolls[i].title = title
        

def get_description(obj):
    if obj.what_is == AMULET:
        return "the amulet of Yendor"

    if obj.what_is == GOLD:
        return "%d pieces of gold" % obj.quantity

    description = ""

    if obj.what_is != ARMOR:
        if obj.quantity == 1:
            description = "a "
        else:
            description = "%d " % obj.quantity
    
    item_name = name_of(obj)

    if obj.what_is == FOOD:
        description += item_name
        description += "of food "
        return description
    
    id_table = get_id_table(obj)
    title = id_table[obj.which_kind].title
    
    #if obj.what_is & (WEAPON | ARMOR | WAND):
    #    goto CHECK
    
    k = id_table[obj.which_kind].id_status
    if k == UNIDENTIFIED and not (obj.what_is & (WEAPON | ARMOR | WAND) and obj.identified):
        # CHECK:
        kk = obj.what_is
        if kk == SCROLL:
            description += item_name
            description += "entitled: "
            description += title
        elif kk == POTION:
            description += title
            description += item_name
        elif kk == WAND:
            #if obj.identified or k == IDENTIFIED:
            #    goto ID
            #if k == CALLED:
            #    goto CALL
            description += title
            description += item_name
        elif kk == ARMOR:
            #if obj.identified:
            #    goto ID
            description = title
            if obj == rogue.armor:
                description += "being worn"
        elif kk == WEAPON:
            #if obj.identified:
            #    goto ID
            description += item_name
            if obj == rogue.weapon:
                description += "in hand"
    elif k == CALLED:
        # CALL:
        kk = obj.what_is
        if kk == SCROLL or kk == POTION or kk == WAND:
            description += item_name
            description += "called "
            description += title
            #goto MI
            if obj.identified:
                description += "[%d]" % obj.clasz
    elif k == IDENTIFIED or (obj.what_is & (WEAPON | ARMOR | WAND) and obj.identified):
        # ID:
        kk = obj.what_is
        if kk == SCROLL or kk == POTION or kk == WAND:
            description += item_name
            description += id_table[obj.which_kind].real
            if k == WAND:
                # MI:
                if obj.identified:
                    description += "[%d]" % obj.clasz
        elif kk == ARMOR:
            description = "%s%d " % (
                "+" if obj.damage_enchantment >= 0 else "",
                obj.damage_enchantment
            )
            description += title
            description += "[%d] " % get_armor_class(obj)
            if obj == rogue.armor:
                description += "being worn"
        elif kk == WEAPON:
            description += "%s%d,%s%d " % (
                "+" if obj.to_hit_enchantment >= 0 else "",
                obj.to_hit_enchantment,
                "+" if obj.damage_enchantment >= 0 else "",
                obj.damage_enchantment
            )
            description += item_name
            if obj == rogue.weapon:
                description += "in hand"
    return description

def mix_metals():
    for i in range(MAXMETALS):
        j = get_rand(0, MAXMETALS - 1)
        k = get_rand(0, MAXMETALS - 1)
        metals[j], metals[k] = metals[k], metals[j]
    for i in range(WANDS):
        id_wands[i].title = metals[i]

def single_inventory():
    ch = get_pack_letter("inventory what? ", IS_OBJECT)
    
    if ch == CANCEL:
        return
    
    obj = get_letter_object(ch)
    if not obj:
        message("No such item.", 0)
        return
    
    message(ch + ") " + get_description(obj), 0)

def get_id_table(obj):
    k = obj.what_is
    if k == SCROLL:
        return id_scrolls
    if k == POTION:
        return id_potions
    if k == WAND:
        return id_wands
    if k == WEAPON:
        return id_weapons
    if k == ARMOR:
        return id_armors
    assert False
