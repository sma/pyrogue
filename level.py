from globals import *

__all__ = ['make_level', 'clear_level', 'print_stats', 'add_mask', 'remove_mask',
           'put_player', 'check_down', 'check_up', 'add_exp', 'level_points']

level_points = [
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
]

def make_level():
    g.party_room = -1
    if g.current_level < 126:
        g.current_level += 1
    if g.current_level > g.max_level:
        g.max_level = g.current_level
    
    if rand_percent(50):
        must_exists1 = 1
        must_exists2 = 7
    else:
        must_exists1 = 3
        must_exists2 = 5
        
    for i in range(MAXROOMS):
        make_room(i, must_exists1, must_exists2, 4)
        
    try_rooms(0, 1, 2)
    try_rooms(0, 3, 6)
    try_rooms(2, 5, 8)
    try_rooms(6, 7, 8)
    
    for i in range(MAXROOMS - 1):
        connect_rooms(i, i + 1, must_exists1, must_exists2, 4)
        if i < MAXROOMS - 3:
            connect_rooms(i, i + 3, must_exists1, must_exists2, 4)
    add_dead_ends()
    
    if not g.has_amulet and g.current_level >= AMULET_LEVEL:
        put_amulet()

def make_room(n, r1, r2, r3):
    if n == 0:
        left_col = 0
        right_col = COL1 - 1
        top_row = MIN_ROW
        bottom_row = ROW1 - 1
    elif n == 1:
        left_col = COL1 + 1
        right_col = COL2 - 1
        top_row = MIN_ROW
        bottom_row = ROW1 - 1
    elif n == 2:
        left_col = COL2 + 1
        right_col = COLS - 1
        top_row = MIN_ROW
        bottom_row = ROW1 - 1
    elif n == 3:
        left_col = 0
        right_col = COL1 - 1
        top_row = ROW1 + 1
        bottom_row = ROW2 - 1
    elif n == 4:
        left_col = COL1 + 1
        right_col = COL2 - 1
        top_row = ROW1 + 1
        bottom_row = ROW2 - 1
    elif n == 5:
        left_col = COL2 + 1
        right_col = COLS - 1
        top_row = ROW1 + 1
        bottom_row = ROW2 - 1
    elif n == 6:
        left_col = 0
        right_col = COL1 - 1
        top_row = ROW2 + 1
        bottom_row = LINES - 2
    elif n == 7:
        left_col = COL1 + 1
        right_col = COL2 - 1
        top_row = ROW2 + 1
        bottom_row = LINES - 2
    elif n == 8:
        left_col = COL2 + 1
        right_col = COLS - 1
        top_row = ROW2 + 1
        bottom_row = LINES - 2
    else:
        assert False
    
    if not (n != r1 and n != r2 and n != r3 and rand_percent(45)):
        height = get_rand(4, bottom_row - top_row + 1)
        width = get_rand(7, right_col - left_col - 2)
        row_offset = get_rand(0, bottom_row - top_row - height + 1)
        col_offset = get_rand(0, right_col - left_col - width + 1)
        
        top_row += row_offset
        bottom_row = top_row + height - 1
        left_col += col_offset
        right_col = left_col + width - 1
        
        rooms[n].is_room = 1
        for i in range(top_row, bottom_row + 1):
            for j in range(left_col, right_col + 1):
                if i == top_row or i == bottom_row:
                    ch = HORWALL
                elif j == left_col or j == right_col:
                    ch = VERTWALL
                else:
                    ch = FLOOR
                add_mask(i, j, ch)

        rooms[n].top_row = top_row
        rooms[n].bottom_row = bottom_row
        rooms[n].left_col = left_col
        rooms[n].right_col = right_col
        rooms[n].height = height
        rooms[n].width = width

def connect_rooms(room1, room2, m1, m2, m3):
    if room1 != m1 and room1 != m2 and room1 != m3 and room2 != m1 and room2 != m2 and room2 != m3:
        if rand_percent(80):
            return
    if adjascent(room1, room2):
        do_connect(room1, room2)

def do_connect(room1, room2):
    if rooms[room1].left_col > rooms[room2].right_col and on_same_row(room1, room2):
        dir1 = LEFT
        dir2 = RIGHT
    elif rooms[room2].left_col > rooms[room1].right_col and on_same_row(room1, room2):
        dir1 = RIGHT
        dir2 = LEFT
    elif rooms[room1].top_row > rooms[room2].bottom_row and on_same_col(room1, room2):
        dir1 = UP
        dir2 = DOWN
    elif rooms[room2].top_row > rooms[room1].bottom_row and on_same_col(room1, room2):
        dir1 = DOWN
        dir2 = UP
    else:
        return
    
    row1, col1 = put_door(room1, dir1)
    row2, col2 = put_door(room2, dir2)
    draw_simple_passage(row1, col1, row2, col2, dir1)
    if rand_percent(10):
        draw_simple_passage(row1, col1, row2, col2, dir1)
        
    rooms[room1].doors[dir1 / 2].other_room = room2
    rooms[room1].doors[dir1 / 2].other_row = row2
    rooms[room1].doors[dir1 / 2].other_col = col2
    
    rooms[room1].doors[dir2 / 2].other_room = room1
    rooms[room1].doors[dir2 / 2].other_row = row1
    rooms[room1].doors[dir2 / 2].other_col = col1

def clear_level():
    for i in range(MAXROOMS):
        rooms[i].is_room = 0
        for j in range(4):
            rooms[i].doors[j].other_room = NO_ROOM
    for i in range(SROWS):
        for j in range(SCOLS):
            screen[i][j] = BLANK
    g.detect_monster = 0
    g.being_held = 0

def print_stats():
    m = "Level: %d  Gold: %3d  Hp: %2d(%d)  Str: %2d(%d)  Arm: %2d  Exp: %d/%d %s" % (
        g.current_level,
        rogue.gold,
        rogue.hp_current,
        rogue.hp_max,
        rogue.strength_current,
        rogue.strength_max,
        get_armor_class(rogue.armor),
        rogue.exp,
        rogue.exp_points,
        g.hunger_str
    )
    mvaddstr(LINES - 1, 0, m)
    clrtoeol()
    refresh()

def add_mask(row, col, mask): 
    if mask == DOOR:
        remove_mask(row, col, HORWALL)
        remove_mask(row, col, VERTWALL)
    screen[row][col] |= mask

def remove_mask(row, col, mask):
    screen[row][col] &= ~mask

def adjascent(room1, room2):
    if not rooms[room1].is_room or not rooms[room2].is_room:
        return 0
    if room1 > room2: room1, room2 = room2, room1
    return (on_same_col(room1, room2) or on_same_row(room1, room2)) and (room2 - room1 == 1 or room2 - room1 == 3)

def put_door(rn, dir):
    if dir == UP or dir == DOWN:
        row = rooms[rn].top_row if dir == UP else rooms[rn].bottom_row
        col = get_rand(rooms[rn].left_col + 1, rooms[rn].right_col - 1)
    elif dir == LEFT or dir == RIGHT:
        row = get_rand(rooms[rn].top_row + 1, rooms[rn].bottom_row - 1)
        col = rooms[rn].left_col if dir == LEFT else rooms[rn].right_col
    else:
        assert False
    add_mask(row, col, DOOR)
    return row, col

def draw_simple_passage(row1, col1, row2, col2, dir):
    if dir == LEFT or dir == RIGHT:
        if col2 < col1:
            row1, row2 = row2, row1
            col1, col2 = col2, col1
        middle = get_rand(col1 + 1, col2 - 1)
        for i in range(col1 + 1, middle):
            add_mask(row1, i, TUNNEL)
        for i in range(row1, row2, -1 if row1 > row2 else 1):
            add_mask(i, middle, TUNNEL)
        for i in range(middle, col2):
            add_mask(row2, i, TUNNEL)
    else:
        if row2 < row1:
            row1, row2 = row2, row1
            col1, col2 = col2, col1
        middle = get_rand(row1 + 1, row2 - 1)
        for i in range(row1 + 1, middle):
            add_mask(i, col1, TUNNEL)
        for i in range(col1, col2, -1 if col1 > col2 else 1):
            add_mask(middle, i, TUNNEL)
        for i in range(middle, row2):
            add_mask(i, col2, TUNNEL)

def on_same_row(room1, room2):
    return room1 / 3 == room2 / 3

def on_same_col(room1, room2):
    return room1 % 3 == room2 % 3

def add_dead_ends():
    if g.current_level <= 2: return
    
    start = get_rand(0, MAXROOMS - 1)
    dead_end_percent = 12 + g.current_level * 2
    
    for i in range(MAXROOMS):
        j = (start + i) % MAXROOMS
        
        if rooms[j].is_room: continue
        
        if not rand_percent(dead_end_percent): continue
        
        row = rooms[j].top_row + get_rand(0, 6)
        col = rooms[j].left_col + get_rand(0, 19)
        
        found = 0
        while not found:
            distance = get_rand(8, 20)
            dir = get_rand(0, 3) * 2
            j = 0
            while j < distance and not found:
                if dir == UP:
                    if row - 1 >= MIN_ROW: row -= 1
                elif dir == RIGHT:
                    if col + 1 < COLS - 1: col += 1
                elif dir == DOWN:
                    if row + 1 < LINES - 2: row += 1
                elif dir == LEFT:
                    if col - 1 > 0: col -= 1
                if screen[row][col] & (VERTWALL | HORWALL | DOOR):
                    break_in(row, col, screen[row][col], dir)
                    found = 1
                else:
                    add_mask(row, col, TUNNEL)
                j += 1

def break_in(row, col, ch, dir):
    if ch == DOOR:
        return
    rn = get_room_number(row, col)
    
    if ch == VERTWALL:
        if col == rooms[rn].left_col:
            if rooms[rn].doors[LEFT / 2].other_room != NO_ROOM:
                drow = door_row(rn, LEFT)
                for i in range(row, drow, -1 if drow > row else 1):
                    add_mask(i, col - 1, TUNNEL)
            else:
                rooms[rn].doors[LEFT / 2].other_room = DEAD_END
                add_mask(row, col, DOOR)
        else:
            if rooms[rn].doors[RIGHT / 2].other_room != NO_ROOM:
                drow = door_row(rn, RIGHT)
                for i in range(row, drow, -1 if drow > row else 1):
                    add_mask(i, col + 1, TUNNEL)
            else:
                rooms[rn].doors[RIGHT / 2].other_room = DEAD_END
                add_mask(row, col, DOOR)
    else:
        if col == rooms[rn].left_col:
            if row == MIN_ROW:
                add_mask(row + 1, col - 1, TUNNEL)
                break_in(row + 1, col, VERTWALL, RIGHT)
            elif row == LINES - 2:
                add_mask(row - 1, col - 1, TUNNEL)
                break_in(row - 1, col, VERTWALL, RIGHT)
            else:
                if row == rooms[rn].top_row:
                    if dir == RIGHT:
                        add_mask(row - 1, col - 1, TUNNEL)
                        add_mask(row - 1, col, TUNNEL)
                    add_mask(row - 1, col + 1, TUNNEL)
                    break_in(row, col + 1, HORWALL, DOWN)
                else:
                    if dir == RIGHT:
                        add_mask(row + 1, col - 1, TUNNEL)
                        add_mask(row + 1, col, TUNNEL)
                    add_mask(row + 1, col + 1, TUNNEL)
                    break_in(row, col + 1, HORWALL, UP)
            return
        elif col == rooms[rn].right_col:
            if row == MIN_ROW:
                add_mask(row + 1, col + 1, TUNNEL)
                break_in(row + 1, col, VERTWALL, LEFT)
            elif row == LINES - 2:
                add_mask(row - 1, col + 1, TUNNEL)
                break_in(row - 1, col, VERTWALL, LEFT)
            else:
                if row == rooms[rn].top_row:
                    if dir == DOWN:
                        add_mask(row - 1, col + 1, TUNNEL)
                        add_mask(row, col + 1, TUNNEL)
                    add_mask(row + 1, col + 1, TUNNEL)
                    break_in(row + 1, col, VERTWALL, LEFT)
                else:
                    if dir == UP:
                        add_mask(row + 1, col + 1, TUNNEL)
                        add_mask(row, col + 1, TUNNEL)
                    add_mask(row - 1, col + 1, TUNNEL)
                    break_in(row - 1, col, VERTWALL, LEFT)
            return
        if row == rooms[rn].top_row:
            if rooms[rn].doors[UP / 2].other_room != NO_ROOM:
                dcol = door_col(rn, UP)
                for i in range(col, dcol, -1 if dcol < col else 1):
                    add_mask(row - 1, i, TUNNEL)
            else:
                rooms[rn].doors[UP / 2].other_room = DEAD_END
                add_mask(row, col, DOOR)
        else:
            if rooms[rn].doors[DOWN / 2].other_room != NO_ROOM:
                dcol = door_col(rn, DOWN)
                for i in range(col, dcol, -1 if dcol < col else 1):
                    add_mask(row + 1, i, TUNNEL)
            else:
                rooms[rn].doors[DOWN / 2].other_room = DEAD_END
                add_mask(row, col, DOOR)
    
def door_row(rn, dir):
    if rooms[rn].doors[dir / 2].other_room == NO_ROOM:
        return -1
    
    if dir == LEFT:
        col = rooms[rn].left_col
    if dir == RIGHT:
        col = rooms[rn].right_col
    # changed, because IndexErrors happens - no door is found
    for row in range(rooms[rn].top_row, rooms[rn].bottom_row):
        if screen[row][col] & DOOR:
            return row
    return -1

def door_col(rn, dir):
    if rooms[rn].doors[dir / 2].other_room == NO_ROOM:
        return -1
    if dir == UP:
        row = rooms[rn].top_row
    if dir == DOWN:
        row = rooms[rn].bottom_row
    # changed, because IndexErrors happens - no door is found
    for col in range(rooms[rn].left_col, rooms[rn].right_col):
        if screen[row][col] & DOOR:
            return col
    return -1

def put_player():
    while True:
        rogue.row, rogue.col = get_rand_row_col(FLOOR | IS_OBJECT)
        g.current_room = get_room_number(rogue.row, rogue.col)
        if g.current_room != g.party_room:
            break

def check_down():
    if screen[rogue.row][rogue.col] & STAIRS:
        return 1
    message("I see no way down", 0)
    return 0

def check_up():
    if not (screen[rogue.row][rogue.col] & STAIRS):
        message("I see no way up", 0)
        return 0
    if not g.has_amulet:
        message("your way is magically blocked", 0)
        return 0
    if g.current_level == 1:
        win()
    else:
        g.current_level -= 2
        return 1

def add_exp(e):
    rogue.exp_points += e
    
    if rogue.exp_points >= level_points[rogue.exp - 1]:
        new_exp = get_exp_level(rogue.exp_points)
        for i in range(rogue.exp + 1, new_exp + 1):
            message("welcome to level %d" % i, 0)
            hp = get_rand(3, 10)
            rogue.hp_current += hp
            rogue.hp_max += hp
            print_stats()
        rogue.exp = new_exp
    print_stats()

def get_exp_level(e):
    for i in range(50):
        if level_points[i] > e:
            break
    return i + 1

def try_rooms(r1, r2, r3):
    if rooms[r1].is_room and not rooms[r2].is_room and rooms[r3].is_room:
        if rand_percent(75):
            do_connect(r1, r3)
