from globals import *

__all__ = ['monster_hit', 'rogue_hit', 'monster_damage', 'fight', 'get_dir_rc', 'get_hit_chance', 'get_weapon_damage']

def monster_hit(monster, other):
    if g.fight_monster and monster != g.fight_monster:
        g.fight_monster = None
    monster.trow = -1
    hit_chance = monster.clasz
    hit_chance -= rogue.exp + rogue.exp
    if hit_chance < 0: hit_chance = 0
    
    if not g.fight_monster:
        g.interrupted = 1
    
    mn = monster_name(monster)
    
    if not rand_percent(hit_chance):
        if not g.fight_monster:
            g.hit_message += "the %s misses" % (other if other else mn)
            message(g.hit_message, 0)
            g.hit_message = ""
        return
    
    if not g.fight_monster:
        g.hit_message += "the %s hit" % (other if other else mn)
        message(g.hit_message, 0)
        g.hit_message = ""
    
    if monster.ichar != 'F':
        damage = get_damage(monster.damage, 1)
        minus = (get_armor_class(rogue.armor) * 3.0) / 100.0 * damage
        damage -= int(minus)
    else:
        damage = monster.identified
        monster.identified += 1
    
    if damage > 0:
        rogue_damage(damage, monster)
    
    special_hit(monster)

def rogue_hit(monster):
    if check_xeroc(monster):
        return
    hit_chance = get_hit_chance(rogue.weapon)
    if not rand_percent(hit_chance):
        if not g.fight_monster:
            g.hit_message = "you miss  "
        #goto RET
        check_orc(monster)
        wake_up(monster)
        return
    
    damage = get_weapon_damage(rogue.weapon)
    if monster_damage(monster, damage): # still alive?
        if not g.fight_monster:
            g.hit_message = "you hit  "
    #RET:
    check_orc(monster)
    wake_up(monster)

def rogue_damage(d, monster):
    if d >= rogue.hp_current:
        rogue.hp_current = 0
        print_stats()
        killed_by(monster, 0)
    rogue.hp_current -= d
    print_stats()

def get_damage(ds, r):
    total = 0
    i = 0
    while i < len(ds):
        n = get_number(ds[i:])
        while i < len(ds) and ds[i] != 'd':
            i += 1
        i += 1
        d = get_number(ds[i:])
        while i < len(ds) and ds[i] != '/':
            i += 1
        for j in range(n):
            if r:
                total += get_rand(1, d)
            else:
                total += d
        if i < len(ds) and ds[i] == '/':
            i += 1
    return total

def get_w_damage(obj):
    if not obj:
        return -1
    to_hit = get_number(obj.damage) + obj.to_hit_enchantment
    i = 0
    while i < len(obj.damage) and obj.damage[i] != 'd':
        i += 1
    i += 1
    damage = get_number(obj.damage[i:]) + obj.damage_enchantment
    
    return get_damage("%dd%d" % (to_hit, damage), 1)

def get_number(s):
    total = 0
    i = 0
    while i < len(s) and '0' <= s[i] <= '9':
        total = 10 * total + ord(s[i]) - ord('0')
        i += 1
    return total

def to_hit(obj):
    if not obj:
        return 1
    return get_number(obj.damage) + obj.to_hit_enchantment

def damage_for_strength(s):
    if s <= 6: return s - 5
    if s <= 14: return 1
    if s <= 17: return 3
    if s <= 18: return 4
    if s <= 20: return 5
    if s <= 21: return 6
    if s <= 30: return 7
    return 8

def monster_damage(monster, damage):
    monster.quantity -= damage
    if monster.quantity <= 0:
        row = monster.row
        col = monster.col
        remove_mask(row, col, MONSTER)
        mvaddch(row, col, get_room_char(screen[row][col], row, col))
        refresh()
        
        g.fight_monster = None
        cough_up(monster)
        g.hit_message += "defeated the %s" % monster_name(monster)
        message(g.hit_message, 1)
        g.hit_message = ""
        add_exp(monster.kill_exp)
        print_stats()
        remove_from_pack(monster, g.level_monsters)
        
        if monster.ichar == 'F':
            g.being_held = 0
        
        return 0
    return 1

def fight(to_the_death):
    first_miss = 1
    ch = getchar()
    while not is_direction(ch):
        beep()
        if first_miss:
            message("direction?", 0)
            first_miss = 0
        ch = getchar()
    check_message()
    if ch == CANCEL:
        return
    
    row, col = get_dir_rc(ch, rogue.row, rogue.col)
    
    if not screen[row][col] & MONSTER or g.blind or hiding_xeroc(row, col):
        #MN:
        message("I see no monster there", 0)
        return
    g.fight_monster = object_at(g.level_monsters, row, col)
    if g.fight_monster.m_flags & IS_INVIS and not g.detect_monster:
        #goto MN
        message("I see no monster there", 0)
        return
    possible_damage = get_damage(g.fight_monster.damage, 0) * 2 / 3
    
    while g.fight_monster:
        single_move_rogue(ch, 0)
        if not to_the_death and rogue.hp_current <= possible_damage:
            g.fight_monster = None
        if not screen[row][col] & MONSTER or g.interrupted:
            g.fight_monster = None

def get_dir_rc(dir, row, col):
    if dir in "hyb":
        if col > 0: col -= 1
    if dir in "jnb":
        if row < LINES - 2: row += 1
    if dir in 'kyu':
        if row > MIN_ROW: row -= 1
    if dir in "lun":
        if col < COLS - 1: col += 1
    return row, col

def get_hit_chance(weapon):
    hit_chance = 40
    hit_chance += 3 * to_hit(weapon)
    hit_chance += (rogue.exp + rogue.exp)
    if hit_chance > 100: hit_chance = 100
    return hit_chance

def get_weapon_damage(weapon):
    damage = get_w_damage(weapon)
    damage += damage_for_strength(rogue.strength_current)
    damage += (rogue.exp + 1) / 2
    return damage
