from globals import *

__all__ = ['quaff', 'read_scroll', 'vanish', 'identify', 'eat', 'teleport',
           'hallucinate', 'unhallucinate', 'unblind', 'confuse', 'unconfuse']

def quaff():
    ch = get_pack_letter("quaff what? ", POTION)
    if ch == CANCEL:
        return
    obj = get_letter_object(ch)
    if not obj:
        message("no such item.", 0)
        return
    if obj.what_is != POTION:
        message("you can't drink that", 0)
        return
    k = obj.which_kind
    if k == INCREASE_STRENGTH:
        message("you feel stronger now, what bulging muscles!", 0)
        rogue.strength_current += 1
        if rogue.strength_current > rogue.strength_max:
            rogue.strength_max = rogue.strength_current
    elif k == RESTORE_STRENGTH:
        message("this tastes great, you feel warm all over", 0)
        rogue.strength_current = rogue.strength_max
    elif k == HEALING:
        message("you begin to feel better", 0)
        potion_heal(0)
    elif k == EXTRA_HEALING:
        message("you begin to feel much better", 0)
        potion_heal(1)
    elif k == POISON:
        rogue.strength_current -= get_rand(1, 3)
        if rogue.strength_current < 0:
            rogue.strength_current = 0
        message("you feel very sick now", 0)
        if g.halluc:
            unhallucinate()
    elif k == RAISE_LEVEL:
        message("you feel more experienced", 0)
        add_exp(level_points[rogue.exp - 1] - rogue.exp_points + 1)
    elif k == BLINDNESS:
        go_blind()
    elif k == HALLUCINATION:
        message("oh wow, everything seems so cosmic", 0)
        g.halluc += get_rand(500, 800)
    elif k == DETECT_MONSTER:
        if g.level_monsters.next_object:
            show_monsters()
        else:
            message("you have a strange feeling for a moment, then it passes", 0)
        g.detect_monster = 1
    elif k == DETECT_OBJECTS:
        if g.level_objects.next_object:
            if not g.blind:
                show_objects()
        else:
            message("you have a strange feeling for a moment, then it passes", 0)
    elif k == CONFUSION:
        message("what a trippy feeling" if g.halluc else "you feel confused", 0)
        confuse()
    print_stats()
    if id_potions[k].id_status != CALLED:
        id_potions[k].id_status = IDENTIFIED
    vanish(obj, 1)

def read_scroll():
    ch = get_pack_letter("read what? ", SCROLL)
    if ch == CANCEL:
        return
    obj = get_letter_object(ch)
    if not obj:
        message("no such item.", 0)
        return
    if obj.what_is != SCROLL:
        message("you can't read that", 0)
        return
    k = obj.which_kind
    if k == SCARE_MONSTER:
        message("you hear a maniacal laughter in the distance", 0)
    elif k == HOLD_MONSTER:
        hold_monster()
    elif k == ENCHANT_WEAPON:
        if rogue.weapon:
            message("your %sglows %sfor a moment" % (id_weapons[rogue.weapon.which_kind].title, get_ench_color()), 0)
            if get_rand(0, 1):
                rogue.weapon.to_hit_enchantment += 1
            else:
                rogue.weapon.damage_enchantment += 1
            rogue.weapon.is_cursed = 0
        else:
            message("your hands tingle", 0)
    elif k == ENCHANT_ARMOR:
        if rogue.armor:
            message("your armor glows %sfor a moment" % get_ench_color(), 0)
            rogue.armor.damage_enchantment += 1
            rogue.armor.is_cursed = 0
            print_stats()
        else:
            message("your skin crawls", 0)
    elif k == IDENTIFY:
        message("this is a scroll of identify", 0)
        message("what would you like to identify?", 0)
        obj.identified = 1
        id_scrolls[k].id_status = IDENTIFIED
        identify()
    elif k == TELEPORT:
        teleport()
    elif k == SLEEP:
        sleep_scroll()
    elif k == PROTECT_ARMOR:
        if rogue.armor:
            message( "your armor is covered by a shimmering gold shield", 0)
            rogue.armor.is_protected = 1
        else:
            message("your acne seems to have disappeared", 0)
    elif k == REMOVE_CURSE:
        message("you feel as though someone is watching over you", 0)
        if rogue.armor:
            rogue.armor.is_cursed = 0
        if rogue.weapon:
            rogue.weapon.is_cursed = 0
    elif k == CREATE_MONSTER:
        create_monster()
    elif k == AGGRAVATE_MONSTER:
        aggravate()
    if id_scrolls[k].id_status != CALLED:
        id_scrolls[k].id_status = IDENTIFIED
    vanish(obj, 1)
    
def vanish(obj, rm):
    if obj.quantity > 1:
        obj.quantity -= 1
    else:
        remove_from_pack(obj, rogue.pack)
        make_avail_ichar(obj.ichar)
    if rm:
        register_move()
    
def potion_heal(extra):
    ratio = float(rogue.hp_current) / rogue.hp_max
    if ratio >= 0.9:
        rogue.hp_max += extra + 1
        rogue.hp_current = rogue.hp_max
    else:
        if ratio < 30.0:
            ratio = 30.0
        if extra:
            ratio += ratio
        add = int(ratio * (rogue.hp_current - rogue.hp_max))
        rogue.hp_current = max(rogue.hp_current + add, rogue.hp_max)
    if g.blind:
        unblind()
    if g.confused and extra:
        unconfuse()
    elif g.confused:
        g.confused = (g.confused - 9)  / 2
        if g.confused <= 0:
            unconfuse()
    if g.halluc and extra:
        unhallucinate()
    elif g.halluc:
        g.halluc = g.halluc / 2 + 1
  
def identify():
    while True:
        ch = get_pack_letter("identify what? ", IS_OBJECT)
        if ch == CANCEL:
            return
        obj = get_letter_object(ch)
        if not obj:
            message("no such item, try again", 0)
            check_message()
            continue
        obj.identified = 1
        if obj.what_is & (SCROLL | POTION | WEAPON | ARMOR | WAND):
            id_table = get_id_table(obj)
            id_table[obj.which_kind].id_status = IDENTIFIED
        message(get_description(obj), 0)
        return

def eat():
    ch = get_pack_letter("eat what? ", FOOD)
    if ch == CANCEL:
        return
    obj = get_letter_object(ch)
    if not obj:
        message("no such item.", 0)
        return
    if obj.what_is != FOOD:
        message("you can't eat that", 0)
        return
    moves = get_rand(800, 1000)
    if moves >= 900:
        message("yum, that tasted good", 0)
    else:
        message("yuk, that food tasted awful", 0)
        add_exp(3)
    rogue.moves_left /= 2
    rogue.moves_left += moves
    g.hunger_str = ""
    print_stats()
    
    vanish(obj, 1)

def hold_monster():
    mcount = 0
    for i in range(-2, 3):
        for j in range(-2, 3):
            row = rogue.row + i
            col = rogue.col + j
            if row < MIN_ROW or row > LINES - 2 or col < 0 or col > COLS - 1:
                continue
            if screen[row][col] & MONSTER:
                monster = object_at(g.level_monsters, row, col)
                monster.m_flags |= IS_ASLEEP
                monster.m_flags &= ~WAKENS
                mcount += 1
    if mcount == 0:
        message("you feel a strange sense of loss", 0)
    elif mcount == 1:
        message("the monster freezes", 0)
    else:
        message("the monsters around you freeze", 0)

def teleport():
    if g.current_room >= 0:
        darken_room(g.current_room)
    else:
        mvaddch(rogue.row, rogue.col, get_room_char(screen[rogue.row][rogue.col], rogue.row, rogue.col))
    put_player()
    light_up_room()
    g.being_hold = 0
    
def hallucinate():
    if g.blind:
        return
    obj = g.level_objects.next_object
    while obj:
        ch = mvinch(obj.row, obj.col)
        if (ch < 'A' or ch > 'Z') and (obj.row != rogue.row or obj.col != rogue.col):
            if ch != ' ' and ch != '.' and ch != '#' and ch != '+':
                addch(get_rand_obj_char())
        obj = obj.next_object
    
    obj = g.level_monsters.next_object
    while obj:
        ch = mvinch(obj.row, obj.col)
        if ch >= 'A' and ch <= 'Z':
            addch(chr(get_rand(ord('A'), ord('Z'))))
        obj = obj.next_object

def unhallucinate():
    g.halluc = 0
    if g.current_room == PASSAGE:
        light_passage(rogue.row, rogue.col)
    else:
        light_up_room()
    message("everything looks SO boring now", 0)

def unblind():
    g.blind = 0
    message("the veil of darkness lifts", 0)
    if g.current_room == PASSAGE:
        light_passage(rogue.row, rogue.col)
    else:
        light_up_room()
    if g.detect_monster:
        show_monsters()
    if g.halluc:
        hallucinate()
    
def sleep_scroll():
    message("you fall asleep", 0)
    ##sleep(1)
    i = get_rand(4, 10)
    while i:
        move_monsters()
        i -= 1
    ##sleep(1)
    message("you can move again", 0)

def go_blind():
    if not g.blind:
        message("a cloak of darkness falls around you", 0)
    g.blind += get_rand(500, 800)
    
    if g.current_room >= 0:
        r = rooms[g.current_room]
        for i in range(r.top_row + 1, r.bottom_row):
            for j in range(r.left_col + 1, r.right_col):
                mvaddch(i, j, ' ')
    mvaddch(rogue.row, rogue.col, rogue.fchar)
    refresh()

def get_ench_color():
    if g.halluc:
        return id_potions[get_rand(0, POTIONS - 1)].title
    return "blue "

def confuse():
    g.confused = get_rand(12, 22)

def unconfuse():
    g.confused = 0
    message("you feel less %s now" % ("trippy" if g.halluc else "confused"), 0)
