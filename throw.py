from globals import *

__all__ = ['throw']

def throw():
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
    wch = get_pack_letter("throw what?", WEAPON)
    if wch == CANCEL:
        check_message()
        return
    
    check_message()
    
    weapon = get_letter_object(wch)
    if not weapon:
        message("no such item.", 0)
        return
    
    if weapon.what_is != WEAPON:
        k = get_rand(0, 2)
        if k == 0:
            message("if you don't want it, drop it!", 0)
        elif k == 1:
            message("throwing that would do noone any good", 0)
        else:
            message("why would you want to throw that?", 0)
        return
    
    if weapon == rogue.weapon and weapon.is_cursed:
        message("you can't, it appears to be cursed", 0)
        return
    
    monster, row, col = get_thrown_at_monster(dir, rogue.row, rogue.col)
    mvaddch(rogue.row, rogue.col, rogue.fchar)
    refresh()
    
    if can_see(row, col) and (row != rogue.row or col != rogue.col):
        mvaddch(row, col, get_room_char(screen[row][col], row, col))
    if monster:
        wake_up(monster)
        check_orc(monster)
        
        if not throw_at_monster(monster, weapon):
            flop_weapon(weapon, row, col)
    else:
        flop_weapon(weapon, row, col)
    vanish(weapon, 1)
    
def throw_at_monster(monster, weapon):
    hit_chance = get_hit_chance(weapon)
    t = weapon.quantity
    weapon.quantity = 1
    g.hit_message = "the %s" % name_of(weapon)
    weapon.quantity = t
    
    if not rand_percent(hit_chance):
        g.hit_message += "misses  "
        return 0
    
    g.hit_message += "hit  "
    damage = get_weapon_damage(weapon)
    if (weapon.which_kind == ARROW and rogue.weapon and rogue.weapon.which_kind == BOW) or (weapon.which_kind == SHURIKEN and rogue.weapon == weapon):
        damage += get_weapon_damage(rogue.weapon)
        damage = damage * 2 / 3
    monster_damage(monster, damage)
    return 1
    
def get_thrown_at_monster(dir, row, col):
    orow = row; ocol = col
    i = 0
    while i < 24:
        row, col = get_dir_rc(dir, row, col)
        if screen[row][col] == BLANK or screen[row][col] & (HORWALL | VERTWALL):
            return None, orow, ocol
        if i != 0 and can_see(orow, ocol):
            mvaddch(orow, ocol, get_room_char(screen[orow][ocol], orow, ocol))
        if can_see(row, col):
            if not screen[row][col] & MONSTER:
                mvaddch(row, col, ')')
            refresh()
        orow = row; ocol = col
        if screen[row][col] & MONSTER:
            if not hiding_xeroc(row, col):
                return object_at(g.level_monsters, row, col), row, col
        if screen[row][col] & TUNNEL:
            i += 2
        i += 1
    return None, row, col
    
def flop_weapon(weapon, row, col):
    inc1 = 1 if get_rand(0, 1) else -1
    inc2 = 1 if get_rand(0, 1) else -1
    
    r = row
    c = col
    
    found = 0
    if (screen[r][c] & ~(FLOOR | TUNNEL | DOOR)) or (row == rogue.row and col == rogue.col):
        for i in range(inc1, 2 * -inc1, -inc1):
            for j in range(inc2, 2 * -inc2, -inc2):
                r = row + i
                c = col + j
                
                if r > LINES - 2 or r < MIN_ROW or c > COLS - 1 or c < 0:
                    continue
                found = 1
                break
            if found: break
    else:
        found = 1
    
    if found:
        new_weapon = get_an_object()
        new_weapon = weapon.copy()
        new_weapon.quantity = 1
        new_weapon.row = r
        new_weapon.col = c
        add_mask(r, c, WEAPON)
        add_to_pack(new_weapon, g.level_objects, 0)
        if can_see(r, c):
            mvaddch(r, c, get_room_char(screen[r][c], r, c))
    else:
        t = weapon.quantity
        weapon.quantity = 1
        msg = "the %svanishes as it hits the ground" % name_of(weapon)
        weapon.quantity = t
        message(msg, 0)
    return found
