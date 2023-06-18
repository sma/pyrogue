from globals import *

__all__ = ['special_hit', 'cough_up', 'orc_gold', 'check_orc', 'check_xeroc',
           'hiding_xeroc', 'm_confuse', 'flame_broil']

def special_hit(monster):
    k = monster.ichar
    if k == 'A':
        rust(monster)
    elif k == 'F':
        g.being_held = 1
    elif k == 'I':
        freeze(monster)
    elif k == 'L':
        steal_gold(monster)
    elif k == 'N':
        steal_item(monster)
    elif k == 'R':
        sting(monster)
    elif k == 'V':
        drain_life()
    elif k == 'W':
        drain_level()

def rust(monster):
    if not rogue.armor or get_armor_class(rogue.armor) <= 1 or rogue.armor.which_kind == LEATHER:
        return
    if rogue.armor.is_protected:
        if not monster.identified:
            message("the rust vanishes instantly", 0)
            monster.identified = 1
    else:
        rogue.armor.damage_enchantment -= 1
        message("your armor weakens", 0)
        print_stats()

def freeze(monster):
    if rand_percent(12): return
    
    freeze_percent = 99
    freeze_percent -= rogue.strength_current + rogue.strength_current / 2
    freeze_percent -= rogue.exp * 4
    freeze_percent -= get_armor_class(rogue.armor) * 5
    freeze_percent -= rogue.hp_max / 3
    
    if freeze_percent > 10:
        monster.identified = 1
        message("you are frozen", 1)
        
        n = get_rand(5, 9)
        for i in range(n):
            move_monsters()
        if rand_percent(freeze_percent):
            for i in range(50):
                move_monsters()
            killed_by(None, HYPOTHERMIA)
        message("you can move again", 1)
        monster.identified = 0

def steal_gold(monster):
    if rand_percent(15): return
    
    if rogue.gold > 50:
        amount = get_rand(8, 15) if rogue.gold > 1000 else get_rand(2, 5)
        amount = rogue.gold / amount
    else:
        amount = rogue.gold / 2
    amount += (get_rand(0, 2) - 1) * (rogue.exp + g.current_level)
    
    if amount <= 0 and rogue.gold > 0:
        amount = rogue.gold
    
    if amount > 0:
        rogue.gold -= amount
        message("your purse feels lighter", 0)
        print_stats()
        
    disappear(monster)

def steal_item(monster):
    if rand_percent(15): return
    
    has_something = 0
    obj = rogue.pack.next_object
    while obj:
        if obj != rogue.armor and obj != rogue.weapon:
            has_something = 1
            break
        obj = obj.next_object
    if has_something:
        n = get_rand(0, MAX_PACK_COUNT)
        obj = rogue.pack.next_object
        
        for i in range(n + 1):
            obj = obj.next_object
            while not obj or obj == rogue.armor or obj == rogue.weapon:
                if not obj:
                    obj = rogue.pack.next_object
                else:
                    obj = obj.next_object
        message("she stole " + get_description(obj), 0)
        
        if obj.what_is == AMULET:
            g.has_amulet = 0
        vanish(obj, 0)
    disappear(monster)

def disappear(monster):
    row = monster.row
    col = monster.col
    
    remove_mask(row, col, MONSTER)
    if can_see(row, col):
        mvaddch(row, col, get_room_char(screen[row][col], row, col))
    remove_from_pack(monster, g.level_monsters)

def cough_up(monster):
    if g.current_level < g.max_level: return
    
    if monster.ichar == 'L':
        obj = get_an_object()
        obj.what_is = GOLD
        obj.quantity = get_rand(9, 599)
    else:
        if rand_percent(monster.which_kind):
            obj = get_rand_object()
        else:
            return
    
    row = monster.row
    col = monster.col
    
    for n in range(6):
        for i in range(-n, n + 1):
            if try_to_cough(row + n, col + i, obj):
                return
            if try_to_cough(row - n, col + i, obj):
                return
        for i in range(-n, n + 1):
            if try_to_cough(row + i, col - n, obj):
                return
            if try_to_cough(row + i, col + n, obj):
                return

def try_to_cough(row, col, obj):
    if row < MIN_ROW or row > LINES - 2 or col < 0 or col > COLS - 1:
        return 0
    if not screen[row][col] & IS_OBJECT and not screen[row][col] & MONSTER and screen[row][col] & (TUNNEL | FLOOR | DOOR):
        put_object_at(obj, row, col)
        mvaddch(row, col, get_room_char(screen[row][col], row, col))
        refresh()
        return 1
    return 0

def orc_gold(monster):
    if monster.identified:
        return 0
    rn = get_room_number(monster.row, monster.col)
    if rn < 0:
        return 0
    r = rooms[rn]
    for i in range(r.top_row + 1, r.bottom_row):
        for j in range(r.left_col + 1, r.right_col):
            if screen[i][j] & GOLD and not screen[i][j] & MONSTER:
                monster.m_flags |= CAN_GO
                s = monster_can_go(monster, i, j)
                monster.m_flags &= ~CAN_GO
                if s:
                    move_monster_to(monster, i, j)
                    monster.m_flags |= IS_ASLEEP
                    monster.m_flags &= ~WAKENS
                    monster.identified = 1
                    return 1
                monster.identified = 1
                monster.m_flags |= CAN_GO
                mv_monster(monster, i, j)
                monster.m_flags &= ~CAN_GO
                monster.identified = 0
                return 1
    return 0
    
def check_orc(monster):
    if monster.ichar == 'O':
        monster.identified = 1

def check_xeroc(monster):
    if monster.ichar == 'X' and monster.identified:
        wake_up(monster)
        monster.identified = 0
        mvaddch(monster.row, monster.col, get_room_char(screen[monster.row][monster.col], monster.row, monster.col))
        check_message()
        message("wait, that's a %s!" % monster_name(monster), 1)
        return 1
    return 0

def hiding_xeroc(row, col):
    if g.current_level < XEROC1 or g.current_level > XEROC2 or not screen[row][col] & MONSTER:
        return 0
    
    monster = object_at(g.level_monsters, row, col)
    return monster.ichar == 'X' and monster.identified
    
def sting(monster):
    if rogue.strength_current < 5: return
    
    sting_chance = 35
    ac = get_armor_class(rogue.armor)
    sting_chance += 6 * (6 - ac)
    
    if rogue.exp > 8:
        sting_chance -= 6 * (rogue.exp - 8)
    
    sting_chance = max(min(sting_chance, 100), 1)
    
    if rand_percent(sting_chance):
        message("the %s's bite has weakened you" % monster_name(monster), 0)
        rogue.strength_current -= 1
        print_stats()
    
def drain_level():
    if not rand_percent(20) or rogue.exp < 8:
        return
    
    rogue.exp_points = level_points[rogue.exp - 2] - get_rand(10, 50)
    rogue.exp -= 2
    add_exp(1)
    
def drain_life():
    if not rand_percent(25) or rogue.hp_max <= 30 or rogue.hp_current < 10:
        return
    message("you feel weaker", 0)
    rogue.hp_max -= 1
    rogue.hp_current -= 1
    if rand_percent(50):
        if rogue.strength_current >= 5:
            rogue.strength_current -= 1
            if rand_percent(50):
                rogue.strength_max -= 1
    print_stats()

def m_confuse(monster):
    if monster.identified:
        return 0
    if not can_see(monster.row, monster.col):
        return 0
    if rand_percent(45):
        monster.identified = 1
        return 0
    if rand_percent(55):
        monster.identified = 1
        message("the gaze of the %s has confused you" % monster_name(monster), 1)
        confuse()
        return 1
    return 0

def flame_broil(monster):
    if rand_percent(50):
        return 0
    row, col = monster.row, monster.col
    if not can_see(row, col):
        return 0
    if not rogue_is_around(row, col):
        row, col = get_closer(row, col, rogue.row, rogue.col)
        standout()
        while True:
            mvaddch(row, col, '*')
            refresh()
            row, col = get_closer(row, col, rogue.row, rogue.col)
            if row == rogue.row and col == rogue.col: break
        standend()
        
        row, col = get_closer(monster.row, monster.col, rogue.row, rogue.col)
        while True:
            mvaddch(row, col, get_room_char(screen[row][col], row, col))
            refresh()
            row, col = get_closer(row, col, rogue.row, rogue.col)
            if row == rogue.row and col == rogue.col: break
    monster_hit(monster, "flame")
    return 1
    
def get_closer(row, col, trow, tcol):
    if row < trow:
        row += 1
    elif row > trow:
        row -= 1
    if col < tcol:
        col += 1
    elif col > tcol:
        col -= 1
    return row, col
