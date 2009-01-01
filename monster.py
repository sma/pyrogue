from globals import *

__all__ = ['put_monsters', 'move_monsters', 'fill_room_with_monsters',
           'get_monster_char_row_col', 'get_monster_char', 'mv_monster',
           'move_monster_to', 'monster_can_go', 'wake_up', 'wake_room',
           'monster_name', 'rogue_is_around', 'start_wanderer', 'show_monsters',
           'create_monster', 'can_see', 'get_rand_obj_char', 'aggravate',
           'mv_aquatars']

def put_monsters():
    n = get_rand(3, 7)
    
    for i in range(n):
        monster = get_rand_monster()
        if monster.m_flags & WANDERS and rand_percent(50):
            wake_up(monster)
        put_monster_rand_location(monster)
        add_to_pack(monster, g.level_monsters, 0)

def get_rand_monster(): 
    monster = get_an_object()
    while True:
        mn = get_rand(0, MAXMONSTER - 1)
        if g.current_level >= monster_tab[mn].is_protected and g.current_level <= monster_tab[mn].is_cursed:
            break
    monster = monster_tab[mn].copy()
    monster.what_is = MONSTER
    if monster.ichar == 'X':
        monster.identified = get_rand_obj_char()
    if g.current_level > AMULET_LEVEL + 2:
        monster.m_flags |= HASTED
    monster.trow = -1
    return monster

def move_monsters():
    monster = g.level_monsters.next_object
    
    while monster:
        if monster.m_flags & HASTED:
            mv_monster(monster, rogue.row, rogue.col)
        elif monster.m_flags & SLOWED:
            monster.quiver = not monster.quiver
            if monster.quiver:
                #goto NM
                monster = monster.next_object
                continue
        flew = 0
        if monster.m_flags & FLIES and not monster_can_go(monster, rogue.row, rogue.col):
            flew = 1
            mv_monster(monster, rogue.row, rogue.col)
        if not flew or not monster_can_go(monster, rogue.row, rogue.col):
            mv_monster(monster, rogue.row, rogue.col)
        # NM:
        monster = monster.next_object

def fill_room_with_monsters(rn, n):
    r = rooms[rn]
    for i in range(n + n / 2):
        if no_room_for_monster(rn): break
        while True:
            row = get_rand(r.top_row + 1, r.bottom_row - 1)
            col = get_rand(r.left_col + 1, r.right_col - 1)
            if not screen[row][col] & MONSTER: break
        put_monster_at(row, col, get_rand_monster())

def get_monster_char_row_col(row, col):
    monster = object_at(g.level_monsters, row, col)
    if (not g.detect_monster and monster.m_flags & IS_INVIS) or g.blind:
        return get_room_char(screen[row][col] & ~MONSTER, row, col)
    if monster.ichar == 'X' and monster.identified:
        return monster.identified
    return monster.ichar

def get_monster_char(monster):
    if (not g.detect_monster and monster.m_flags & IS_INVIS) or g.blind:
        return get_room_char(screen[monster.row][monster.col] & ~MONSTER, monster.row, monster.col)
    if monster.ichar == 'X' and monster.identified:
        return monster.identified
    return monster.ichar

def mv_monster(monster, row, col):
    if monster.m_flags & IS_ASLEEP:
        if monster.m_flags & WAKENS and rogue_is_around(monster.row, monster.col) and rand_percent(WAKE_PERCENT):
            wake_up(monster)
        return

    if monster.m_flags & FLITS and flit(monster):
        return
    
    if monster.ichar == 'F' and not monster_can_go(monster, rogue.row, rogue.col):
        return
    
    if monster.ichar == 'I' and not monster.identified:
        return
    
    if monster.ichar == 'M' and not m_confuse(monster):
        return
    
    if monster_can_go(monster, rogue.row, rogue.col):
        monster_hit(monster, "")
        return
    
    if monster.ichar == 'D' and flame_broil(monster):
        return
    
    if monster.ichar == 'O' and orc_gold(monster):
        return

    if monster.trow == monster.row and monster.tcol == monster.col:
        monster.trow = -1
    elif monster.trow != -1:
        row = monster.trow
        col = monster.tcol
        
    if monster.row > row:
        row = monster.row - 1
    elif monster.row < row:
        row = monster.row + 1
    
    if screen[row][monster.col] & DOOR and mtry(monster, row, monster.col):
        return
    
    if monster.col > col:
        col = monster.col - 1
    elif monster.col < col:
        col = monster.col + 1
    
    if screen[monster.row][col] & DOOR and mtry(monster, monster.row, col):
        return
    
    if mtry(monster, row, col):
        return
    
    tried = [0] * 6
    for i in range(6):
        n = get_rand(0, 5)
        if n == 0:
            if not tried[n] and mtry(monster, row, monster.col - 1):
                return
        elif n == 1:
            if not tried[n] and mtry(monster, row, monster.col):
                return
        elif n == 2:
            if not tried[n] and mtry(monster, row, monster.col + 1):
                return
        elif n == 3:
            if not tried[n] and mtry(monster, monster.row - 1, col):
                return
        elif n == 4:
            if not tried[n] and mtry(monster, monster.row, col):
                return
        elif n == 5:
            if not tried[n] and mtry(monster, monster.row + 1, col):
                return
        tried[n] = 1
   
def mtry(monster, row, col):
    if monster_can_go(monster, row, col):
        move_monster_to(monster, row, col)
        return 1
    return 0

def move_monster_to(monster, row, col):
    add_mask(row, col, MONSTER)
    remove_mask(monster.row, monster.col, MONSTER)
    
    c = mvinch(monster.row, monster.col)
    
    if 'A' <= c <= 'Z':
        mvaddch(monster.row, monster.col,
            get_room_char(screen[monster.row][monster.col], monster.row, monster.col))
    if not g.blind and (g.detect_monster or can_see(row, col)):
        if not monster.m_flags & IS_INVIS or g.detect_monster:
            mvaddch(row, col, get_monster_char(monster))
    if screen[row][col] & DOOR and get_room_number(row, col) != g.current_room and screen[monster.row][monster.col] == FLOOR:
        if not g.blind:
            mvaddch(monster.row, monster.col, ' ')
    if screen[row][col] & DOOR:
        door_course(monster, screen[monster.row][monster.col] & TUNNEL, row, col)
    else:
        monster.row = row
        monster.col = col
    
def monster_can_go(monster, row, col):
    dr = monster.row - row
    if dr <= -2 or dr >= 2: return 0
    dc = monster.col - col
    if dc <= -2 or dc >= 2: return 0
    
    if not screen[monster.row][col] or not screen[row][monster.col]:
        return 0
    if not is_passable(row, col) or screen[row][col] & MONSTER:
        return 0
    if monster.row != row and monster.col != col and (screen[row][col] & DOOR or screen[monster.row][monster.col] & DOOR):
        return 0
    if not monster.m_flags & FLITS and not monster.m_flags & CAN_GO and monster.trow == -1:
        if monster.row < rogue.row and row < monster.row: return 0
        if monster.row > rogue.row and row > monster.row: return 0
        if monster.col < rogue.col and col < monster.col: return 0
        if monster.col > rogue.col and col > monster.col: return 0
    
    if screen[row][col] & SCROLL:
        obj = object_at(g.level_objects, row, col)
        if obj.which_kind == SCARE_MONSTER:
            return 0
        
    return 1

def wake_up(monster):
    monster.m_flags &= ~IS_ASLEEP

def wake_room(rn, entering, row, col):
    wake_percent = PARTY_WAKE_PERCENT if rn == g.party_room else WAKE_PERCENT
    
    monster = g.level_monsters.next_object
    while monster:
        if (monster.m_flags & WAKENS or rn == g.party_room) and rn == get_room_number(monster.row, monster.col):
            if monster.ichar == 'X' and rn == g.party_room:
                monster.m_flags |= WAKENS
            if entering:
                monster.trow = -1
            else:
                monster.trow = row
                monster.tcol = col
            if rand_percent(wake_percent) and monster.m_flags & WAKENS:
                if monster.ichar != 'X':
                    wake_up(monster)
        monster = monster.next_object

def monster_name(monster):
    if g.blind or (monster.m_flags & IS_INVIS and not g.detect_monster):
        return "something"
    if g.halluc:
        return monster_names[get_rand(0, 25)]
    return monster_names[ord(monster.ichar) - ord('A')]

def rogue_is_around(row, col):
    rdif = abs(row - rogue.row)
    cdif = abs(col - rogue.col)
    return rdif < 2 and cdif < 2
    
def start_wanderer():
    while True:
        monster = get_rand_monster()
        if monster.m_flags & WAKENS or monster.m_flags & WANDERS: break
    wake_up(monster)
    for i in range(12):
        row, col = get_rand_row_col(FLOOR | TUNNEL | IS_OBJECT)
        if not can_see(row, col):
            put_monster_at(row, col, monster)
            return

def show_monsters():
    if g.blind: return
    
    monster = g.level_monsters.next_object
    while monster:
        mvaddch(monster.row, monster.col, monster.ichar)
        if monster.ichar == 'X':
            monster.identified = 0
        monster = monster.next_object

def create_monster():
    inc1 = 1 if get_rand(0, 1) else -1
    inc2 = 1 if get_rand(0, 1) else -1
    
    found = 0
    for i in range(inc1, 2 * -inc1, -inc1):
        for j in range(inc2, 2 * -inc2, -inc2):
            if i == 0 and j == 0: continue
            row = rogue.row + i
            col = rogue.col + j
            if row < MIN_ROW or row > LINES - 2 or col < 0 or col > COLS - 1:
                continue
            if not screen[row][col] & MONSTER and screen[row][col] & (FLOOR | TUNNEL | STAIRS):
                found = 1
                break
        if found:
            break
    if found:
        monster = get_rand_monster()
        put_monster_at(row, col, monster)
        mvaddch(row, col, get_monster_char(monster))
        if monster.m_flags & WANDERS:
            wake_up(monster)
    else:
        message("you hear a faint cry of anguish in the distance", 0)

def put_monster_at(row, col, monster):
    monster.row = row
    monster.col = col
    add_mask(row, col, MONSTER)
    add_to_pack(monster, g.level_monsters, 0)

def can_see(row, col):
    return not g.blind and (get_room_number(row, col) == g.current_room or rogue_is_around(row, col))

def flit(monster):
    if not rand_percent(FLIT_PERCENT):
        return 0
    inc1 = 1 if get_rand(0, 1) else -1
    inc2 = 1 if get_rand(0, 1) else -1
    
    if rand_percent(10):
        return 1
    
    for i in range(inc1, 2 * -inc1, -inc1):
        for j in range(inc2, 2 * -inc2, -inc2):
            row = monster.row + i
            col = monster.col + j
            if row == rogue.row and col == rogue.col:
                continue
            if mtry(monster, row, col):
                return 1
    return 1

def put_monster_rand_location(monster): 
    row, col = get_rand_row_col(FLOOR | TUNNEL | IS_OBJECT)
    add_mask(row, col, MONSTER)
    monster.row = row
    monster.col = col

def get_rand_obj_char():
    return "%!?]/):*"[get_rand(0, 7)]

def no_room_for_monster(rn):
    r = rooms[rn]
    for i in range(r.left_col + 1, r.right_col):
        for j in range(r.top_row + 1, r.bottom_row):
            if not screen[j][i] & MONSTER:
                return 0
    return 1

def aggravate():
    message("you hear a high pitched humming noise")
    monster = g.level_monsters.next_object
    while monster:
        wake_up(monster)
        if monster.ichar == 'X':
            monster.identified = 0
        monster = monster.next_object

def monster_can_see(monster, row, col):
    rn = get_room_number(row, col)
    
    if rn != NO_ROOM and rn == get_room_number(monster.row, monster.col):
        return 1
    
    return abs(row - monster.row) < 2 and abs(col - monster.col) < 2

def mv_aquatars():
    monster = g.level_monsters.next_object
    while monster:
        if monster.ichar == 'A':
            mv_monster(monster, rogue.row, rogue.col)
        monster = monster.next_object

def door_course(monster, entering, row, col):
    monster.row = row
    monster.col = col
    
    if monster_can_see(monster, rogue.row, rogue.col):
        monster.trow = -1
        return
    
    rn = get_room_number(row, col)
    
    if entering:
        for i in range(MAXROOMS):
            if not rooms[i].is_room or i == rn: continue
            for j in range(4):
                d = rooms[i].doors[j]
                if d.other_room == rn:
                    monster.trow = d.other_row
                    monster.tcol = d.other_col
                    if monster.trow == row and monster.tcol == col:
                        continue
                    return
    else:
        b, rrow, ccol = get_other_room(rn, row, col)
        if b:
            monster.trow = rrow
            monster.tcol = ccol
        else:
            monster.trow = -1

def get_other_room(rn, row, col):
    d = -1
    if screen[row][col - 1] & HORWALL and screen[row][col + 1] & HORWALL:
        if screen[row + 1][col] & FLOOR:
            d = UP / 2
        else:
            d = DOWN / 2
    else:
        if screen[row][col + 1] & FLOOR:
            d = LEFT / 2
        else:
            d = RIGHT / 2
    if d != -1 and rooms[rn].doors[d].other_room > 0:
        return 1, rooms[rn].doors[d].other_row, rooms[rn].doors[d].other_col
    return 0, 0, 0
