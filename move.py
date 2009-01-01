from globals import *

__all__ = ['single_move_rogue', 'multiple_move_rogue', 'is_passable',
           'is_object', 'move_onto', 'is_direction', 'is_pack_letter',
           'register_move', 'rest']

moves = 0
h_exp = -1
h_n = 0
h_c = 0

def single_move_rogue(dirch, pickup):
    row = rogue.row
    col = rogue.col
    
    if g.being_held:
        row, col = get_dir_rc(dirch, row, col)
        
        if not screen[row][col] & MONSTER:
            message("you are being held", 1)
            return MOVE_FAILED
        
    row = rogue.row
    col = rogue.col
    
    if g.confused:
        dirch = get_rand_dir()
    
    row, col = get_dir_rc(dirch, row, col)
    
    if screen[row][col] & MONSTER:
        rogue_hit(object_at(g.level_monsters, row, col))
        register_move()
        return MOVE_FAILED
    
    if not can_move(rogue.row, rogue.col, row, col):
        return MOVE_FAILED
    
    if screen[row][col] & DOOR:
        if g.current_room == PASSAGE:
            g.current_room = get_room_number(row, col)
            light_up_room()
            wake_room(g.current_room, 1, row, col)
        else:
            light_passage(row, col)
    elif screen[rogue.row][rogue.col] & DOOR and screen[row][col] & TUNNEL:
        light_passage(row, col)
        wake_room(g.current_room, 0, row, col)
        darken_room(g.current_room)
        g.current_room = PASSAGE
    elif screen[row][col] & TUNNEL:
        light_passage(row, col)
    
    mvaddch(rogue.row, rogue.col, get_room_char(screen[rogue.row][rogue.col], rogue.row, rogue.col))
    mvaddch(row, col, rogue.fchar)
    rogue.row = row
    rogue.col = col
    
    if screen[row][col] & CAN_PICK_UP:
        if pickup:
            obj, status = pick_up(row, col)
            if obj:
                description = get_description(obj)
                if obj.what_is == GOLD:
                    #goto NOT_IN_PACK
                    message(description, 1)
                    register_move()
                    return STOPPED_ON_SOMETHING
            elif not status:
                #goto MVED
                if register_move(): # fainted from hunger
                    return STOPPED_ON_SOMETHING
                return STOPPED_ON_SOMETHING if g.confused else MOVED
            else:
                #goto MOVE_ON
                obj = object_at(g.level_objects, row, col)
                description = "moved onto " + get_description(obj)
                #goto NOT_IN_PACK
                message(description, 1)
                register_move()
                return STOPPED_ON_SOMETHING
        else:
            # MOVE_ON
            obj = object_at(g.level_objects, row, col)
            description = "moved onto " + get_description(obj)
            #goto NOT_IN_PACK
            message(description, 1)
            register_move()
            return STOPPED_ON_SOMETHING
        
        description += "("
        description += obj.ichar
        description += ")"
        
        # NOT_IN_PACK
        message(description, 1)
        register_move()
        return STOPPED_ON_SOMETHING
    
    if screen[row][col] & DOOR or screen[row][col] & STAIRS:
        register_move()
        return STOPPED_ON_SOMETHING
    
    # MVED
    if register_move(): # fainted from hunger
        return STOPPED_ON_SOMETHING
    
    return STOPPED_ON_SOMETHING if g.confused else MOVED
    
def multiple_move_rogue(dirch):
    if dirch in "\010\012\013\014\031\025\016\002":
        while True:
            row = rogue.row
            col = rogue.col
            m = single_move_rogue(chr(ord(dirch) + 96), 1)
            if m == MOVE_FAILED or m == STOPPED_ON_SOMETHING or g.interrupted:
                break
            if next_to_something(row, col):
                break
    elif dirch in "HJKLBYUN":
        while not g.interrupted and single_move_rogue(chr(ord(dirch) + 32), 1) == MOVED:
            pass

def is_passable(row, col):
    if row < MIN_ROW or row > LINES - 2 or col < 0 or col > COLS - 1:
        return 0
    return screen[row][col] & (FLOOR | TUNNEL | DOOR | STAIRS)

def next_to_something(drow, dcol):
    pass_count = 0
    
    if g.confused:
        return 1
    if g.blind:
        return 0
    
    i_end = 1 if rogue.row < LINES - 2 else 0
    j_end = 1 if rogue.col < COLS - 1 else 0
    
    for i in range(-1 if rogue.row > MIN_ROW else 0, i_end + 1):
        for j in range(-1 if rogue.col > 0 else 0, j_end + 1):
            if i == 0 and j == 0: continue
            r = rogue.row + i
            c = rogue.col + j
            if r == drow and c == dcol: continue
            if screen[r][c] & (MONSTER | IS_OBJECT):
                return 1
            if (i - j == 1 or i - j == -1) and screen[r][c] & TUNNEL:
                pass_count += 1
                if pass_count > 1:
                    return 1
            if screen[r][c] & DOOR or is_object(r, c):
                if i == 0 or j == 0:
                    return 1
    return 0

def can_move(row1, col1, row2, col2):
    if not is_passable(row2, col2):
        return 0
    if row1 != row2 and col1 != col2:
        if screen[row1][col1] & DOOR or screen[row2][col2] & DOOR:
            return 0
        if not screen[row1][col2] or not screen[row2][col1]:
            return 0
    return 1

def is_object(row, col):
    return screen[row][col] & IS_OBJECT

def move_onto():
    first_miss = 1
    
    ch = getchar()
    while not is_direction(ch):
        beep()
        if first_miss:
            message("direction? ", 0)
            first_miss = 0
        ch = getchar()
    check_message()
    if ch != CANCEL:
        single_move_rogue(ch, 0)

def is_direction(c):
    return c in 'hjklbyun' or c == CANCEL

def is_pack_letter(c):
    return 'a' <= c <= 'z' or c == CANCEL or c == LIST

def check_hunger():
    fainted = 0
    if rogue.moves_left == HUNGRY:
        g.hunger_str = "hungry"
        message(g.hunger_str, 0)
        print_stats()
    if rogue.moves_left == WEAK:
        g.hunger_str = "weak"
        message(g.hunger_str, 0)
        print_stats()
    if rogue.moves_left <= FAINT:
        if rogue.moves_left == FAINT:
            g.hunger_str = "faint"
            message(g.hunger_str, 1)
            print_stats()
        n = get_rand(0, FAINT - rogue.moves_left)
        if n > 0:
            fainted = 1
            if rand_percent(40): rogue.moves_left += 1
            message("you faint", 1)
            for i in range(n):
                if rand_percent(50):
                    move_monsters()
            message("you can move again", 1)
    if rogue.moves_left <= STARVE:
        killed_by(0, STARVATION)
    rogue.moves_left -= 1
    return fainted

def register_move():
    global moves
    
    if rogue.moves_left <= HUNGRY and not g.has_amulet:
        fainted = check_hunger()
    else:
        fainted = 0
    
    move_monsters()
    
    moves += 1
    if moves >= 80:
        moves = 0
        start_wanderer()
    
    if g.halluc:
        g.halluc -= 1
        if not g.halluc:
            unhallucinate()
        else:
            hallucinate()
    
    if g.blind:
        g.blind -= 1
        if not g.blind:
            unblind()
            
    if g.confused:
        g.confused -= 1
        if not g.confused:
            unconfuse()
            
    heal()
    
    return fainted

def rest(count):
    for i in range(count):
        if g.interrupted:
            break
        register_move()

def get_rand_dir():
    return "hjklyubn"[get_rand(0, 7)]

def heal():
    global h_exp, h_n, h_c
    
    if rogue.exp != h_exp:
        h_exp = rogue.exp
        
        if h_exp == 1:
            h_n = 20
        elif h_exp == 2:
            h_n = 18
        elif h_exp == 3:
            h_n = 17
        elif h_exp == 4:
            h_n = 14
        elif h_exp == 5:
            h_n = 13
        elif h_exp == 6:
            h_n = 11
        elif h_exp == 7:
            h_n = 9
        elif h_exp == 8:
            h_n = 8
        elif h_exp == 9:
            h_n = 6
        elif h_exp == 10:
            h_n = 4
        elif h_exp == 11:
            h_n = 3
        else:
            h_n = 2
        
    if rogue.hp_current == rogue.hp_max:
        h_c = 0
        return
    h_c += 1
    if h_c >= h_n:
        h_c = 0
        rogue.hp_current += 1
        if rogue.hp_current < rogue.hp_max:
            if rand_percent(50):
                rogue.hp_current += 1
        print_stats()
