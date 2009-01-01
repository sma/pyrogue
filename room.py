from globals import *

__all__ = ['light_up_room', 'light_passage', 'darken_room', 'get_room_char',
           'get_rand_row_col', 'get_rand_room', 'fill_room_with_objects',
           'get_room_number', 'shell']

def light_up_room():
    if g.blind: return
    r = rooms[g.current_room]
    for i in range(r.top_row, r.bottom_row + 1):
        for j in range(r.left_col, r.right_col + 1):
            mvaddch(i, j, get_room_char(screen[i][j], i, j))
    mvaddch(rogue.row, rogue.col, rogue.fchar)

def light_passage(row, col):
    if g.blind: return
    i_end = 1 if row < LINES - 2 else 0
    j_end = 1 if col < COLS - 1 else 0
    
    for i in range(-1 if row > MIN_ROW else 0, i_end + 1):
        for j in range(-1 if col > 0 else 0, j_end + 1):
            if is_passable(row + i, col + j):
                r = row + i
                c = col + j
                mvaddch(r, c, get_room_char(screen[r][c], r, c))

def darken_room(rn):
    if g.blind: return
    r = rooms[rn]
    for i in range(r.top_row + 1, r.bottom_row):
        for j in range(r.left_col + 1, r.right_col):
            if not is_object(i, j) and not (g.detect_monster and screen[i][j] & MONSTER):
                if not hiding_xeroc(i, j):
                    mvaddch(i, j, ' ')

def get_room_char(mask, row, col):
    if mask & MONSTER:
        return get_monster_char_row_col(row, col)
    if mask & SCROLL:
        return '?'
    if mask & POTION:
        return '!'
    if mask & FOOD:
        return ':'
    if mask & WAND:
        return '/'
    if mask & ARMOR:
        return ']'
    if mask & WEAPON:
        return ')'
    if mask & GOLD:
        return '*'
    if mask & TUNNEL:
        return '#'
    if mask & HORWALL:
        return '-'
    if mask & VERTWALL:
        return '|'
    if mask & AMULET:
        return ','
    if mask & FLOOR:
        return '.'
    if mask & DOOR:
        return '+'
    if mask & STAIRS:
        return '%'
    return ' '

def get_rand_row_col(mask):
    while True:
        row = get_rand(MIN_ROW, SROWS - 2)
        col = get_rand(0, SCOLS - 1)
        rn = get_room_number(row, col)
        if screen[row][col] & mask and not screen[row][col] & ~mask and rn != NO_ROOM: break
    return row, col

def get_rand_room():
    while True:
        i = get_rand(0, MAXROOMS - 1)
        if rooms[i].is_room: break
    return i

def fill_room_with_objects(rn):
    r = rooms[rn]
    N = (r.bottom_row - r.top_row - 1) * (r.right_col - r.left_col - 1)
    n = get_rand(5, 10)
    if n > N: n = N - 2
    
    for i in range(n):
        while True:
            row = get_rand(r.top_row + 1, r.bottom_row - 1)
            col = get_rand(r.left_col + 1, r.right_col - 1)
            if screen[row][col] == FLOOR: break
        obj = get_rand_object()
        put_object_at(obj, row, col)
        
    return n

def get_room_number(row, col):
    for i in range(MAXROOMS):
        r = rooms[i]
        if r.top_row <= row <= r.bottom_row and r.left_col <= col <= r.right_col:
            return i
    return NO_ROOM

def shell():
    raise
