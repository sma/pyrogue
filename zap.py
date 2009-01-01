from globals import *

__all__ = ['zapp']

def zapp():
    first_miss = 1
    dir = getchar()
    while not is_direction(dir):
        beep()
        if first_miss:
            message("direction? ", 0)
            first_miss = 0
        dir = getchar()
    if dir == CANCEL:
        check_message()
        return

    wch = get_pack_letter("zap with what? ", WAND)
    if wch == CANCEL:
        check_message()
        return
    wand = get_letter_object(wch)
    if not wand:
        message("no such item.", 0)
        return
    if wand.what_is != WAND:
        message("you can't zap with that", 0)
        return
    if wand.clasz <= 0:
        message("nothing happens", 0)
        #goto RM
    else:
        wand.clasz -= 1
    
        monster = get_zapped_monster(dir, rogue.row, rogue.col)
        if monster:
            wake_up(monster)
            zap_monster(monster, wand.which_kind)
    # RM:
    register_move()

def get_zapped_monster(dir, row, col):
    while True:
        r, c = get_dir_rc(dir, row, col)
        if (row == r and col == c) or screen[r][c] & (HORWALL | VERTWALL) or screen[r][c] == BLANK:
            return None
        if screen[r][c] & MONSTER:
            if not hiding_xeroc(r, c):
                return object_at(g.level_monsters, r, c)
        row = r
        col = c

def zap_monster(monster, kind):
    row = monster.row
    col = monster.col
    
    nm = monster.next_object
    
    if kind == SLOW_MONSTER:
        if monster.m_flags & HASTED:
            monster.m_flags &= ~HASTED
        else:
            monster.quiver = 0
            monster.m_flags |= SLOWED
    elif kind == HASTE_MONSTER:
        if monster.m_flags & SLOWED:
            monster.m_flags &= ~SLOWED
        else:
            monster.m_flags |= HASTED
    elif kind == TELEPORT_AWAY:
        teleport_away(monster)
    elif kind == KILL_MONSTER:
        rogue.exp_points -= monster.kill_exp
        monster_damage(monster, monster.quantity)
    elif kind == INVISIBILITY:
        monster.m_flags |= IS_INVIS
        mvaddch(row, col, get_monster_char(monster))
    elif kind == POLYMORPH:
        if monster.ichar == 'F':
            g.being_held = 0
        # need to find prev to link to new one
        pm = g.level_monsters
        while pm.next_object != monster:
            pm = pm.next_object
        while True:
            monster = monster_tab[get_rand(0, MONSTERS - 1)].copy()
            if not (monster.ichar == 'X' and (g.current_level < XEROC1 or g.current_level > XEROC2)): break
        monster.what_is = MONSTER
        monster.row = row
        monster.col = col
        monster.next_object = nm
        pm.next_object = monster
        wake_up(monster)
        if can_see(row, col):
            mvaddch(row, col, get_monster_char(monster))
    elif kind == PUT_TO_SLEEP:
        monster.m_flags |= IS_ASLEEP
        monster.m_flags &= ~WAKENS
    elif kind == DO_NOTHING:
        message("nothing happens", 0)
    # seems that original never identified wands
    if id_wands[kind].id_status != CALLED:
        id_wands[kind].id_status = IDENTIFIED

def teleport_away(monster):
    if monster.ichar == 'F':
        g.being_held = 0
    row, col = get_rand_row_col(FLOOR | TUNNEL | IS_OBJECT)
    remove_mask(monster.row, monster.col, MONSTER)
    mvaddch(monster.row, monster.col,
            get_room_char(screen[monster.row][monster.col], monster.row, monster.col))
    monster.row = row; monster.col = col
    add_mask(row, col, MONSTER)
    
    if can_see(row, col):
        mvaddch(row, col, get_monster_char(monster))
