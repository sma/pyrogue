from globals import *

__all__ = ['killed_by', 'win', 'quit']

SCOREFILE = "scores"

def killed_by(monster, other):
    #signal(SIGINT, SIG_IGN)
    
    if other != QUIT:
        rogue.gold = rogue.gold * 9 / 10
    
    if other == HYPOTHERMIA:
        buf = "died of hypothermia"
    elif other == STARVATION:
        buf = "died of starvation"
    elif other == QUIT:
        buf = "quit"
    else:
        buf = "killed by "
        name = monster_names[ord(monster.ichar) - ord('A')]
        if  is_vowel(name):
            buf += "an "
        else:
            buf += "a "
        buf += name
    
    buf += " with %d gold" % rogue.gold
    message(buf, 0)
    message("", 0)
    score(monster, other)
    
def win():
    rogue.armor = None
    rogue.weapon = None
    
    clear()
    mvaddstr(10, 11, "@   @  @@@   @   @      @  @  @   @@@   @   @   @")
    mvaddstr(11, 11, " @ @  @   @  @   @      @  @  @  @   @  @@  @   @")
    mvaddstr(12, 11, "  @   @   @  @   @      @  @  @  @   @  @ @ @   @")
    mvaddstr(13, 11, "  @   @   @  @   @      @  @  @  @   @  @  @@")
    mvaddstr(14, 11, "  @    @@@    @@@        @@ @@    @@@   @   @   @")
    mvaddstr(17, 11, "Congratulations,  you have  been admitted  to  the")
    mvaddstr(18, 11, "Fighter's Guild.   You return home,  sell all your")
    mvaddstr(19, 11, "treasures at great profit and retire into comfort.")
    message("", 0);
    message("", 0);
    id_all()
    sell_pack()
    score(None, WIN)
    
def quit():
    message("really quit?", 1)
    if getchar() != 'y':
        check_message()
        return
    check_message()
    killed_by(None, QUIT)
    
def score(monster, other):
    # todo loop in case the scores file cannot be accessed/created
    put_scores(monster, other)
    
def put_scores(monster, other):
    scores = [""] * 10
    
    f = open(SCOREFILE, "a+") # read an existing file or create a new one
    f.seek(0)
    
    rank = 10
    dont_insert = 0
    i = 0
    while i < 10:
        #L:
        scores[i] = f.readline()
        if scores[i] == "":
            break
        if len(scores[i]) < 18:
            message("error in score file format", 1)
            cleanup("sorry, score file is out of order")
        if ncmp(scores[i][16:], g.player_name):
            s = int(scores[i][8:16])
            if s <= rogue.gold:
                #goto L
                continue
            dont_insert = 1
        i += 1
    
    #if dont_insert: goto DI
    if not dont_insert:
        for j in range(i):
            if rank > 9:
                s = int(scores[j][8:16])
                if s <= rogue.gold:
                    rank = j
        
        if i == 0:
            rank = 0
        elif i < 10 and rank > 9:
            rank = i
        if rank <= 9:
            insert_score(scores, rank, i, monster, other)
            if i < 10:
                i += 1
                
        f.truncate(0)

    #DI:
    clear()
    mvaddstr(3, 30, "Top  Ten  Rogueists")
    mvaddstr(8, 0, "Rank    Score   Name")
    
    #signal(SIGQUIT, SIG_IGN)
    #signal(SIGINT, SIG_IGN)
    #signal(SIGHUP, SIG_IGN)
    
    for j in range(i):
        if j == rank:
            standout()
        scores[j] = "%2d" % (j + 1) + scores[j][2:]
        mvaddstr(j + 10, 0, scores[j])
        if rank < 10:
            f.write(scores[j])
        if j == rank:
            standend()

    refresh()
    f.close()
    
    wait_for_ack("")
    
    clean_up("")

def insert_score(scores, rank, n, monster, other):
    for i in range(n - 1, rank - 1, -1):
        if i < 9:
            scores[i + 1] = scores[i]
    buf = "%2d      %5d   %s: " % (rank + 1, rogue.gold, g.player_name)
    
    if other == HYPOTHERMIA:
        buf += "died of hypothermia"
    elif other == STARVATION:
        buf += "died of starvation"
    elif other == QUIT:
        buf += "quit"
    elif other == WIN:
        buf += "a total winner"
    else:
        buf += "killed by "
        name = monster_names[ord(monster.ichar) - ord('A')]
        if is_vowel(name):
            buf += "an "
        else:
            buf += "a "
        buf += name
    buf += " on level %d " % g.max_level
    if other != WIN and g.has_amulet:
        buf += "with amulet"
    buf += "\n"
    scores[rank] = buf

def is_vowel(ch):
    return ch in "aeiou"

def sell_pack():
    rows = 2

    clear()
    
    obj = rogue.pack.next_object
    while obj:
        mvaddstr(1, 0, "Value      Item")
        if obj.what_is != FOOD:
            obj.identified = 1
            val = get_value(obj)
            rogue.gold += val
            
            if rows < SROWS:
                mvadstr(row, 0, "%5d      %s" % (val, get_description(obj)))
                row += 1
        obj = obj.next_object
    refresh()
    message("", 0)
    
def get_value(obj):
    k = obj.which_kind
    if k == WEAPON:
        val = id_weapons[k].value
        if k == ARROW or k == SHURIKEN:
            val *= obj.quantity
        val += obj.damage_enchantment * 85
        val += obj.to_hit_enchantment * 85
    elif k == ARMOR:
        val = id_armors[k].value
        val += obj.damage_enchantment * 75
        if obj.is_protected:
            val += 200
    elif k == WAND:
        val = id_wands[k].value * obj.clasz
    elif k == SCROLL:
        val = id_scrolls[k].value * obj.quantity
    elif k == POTION:
        val = id_potions[k].value * obj.quantity
    elif k == AMULET:
        val = 5000
    else:
        val = 0
    return max(val, 10)

def id_all():
    for i in range(SCROLLS):
        id_scrolls[i].id_status = IDENTIFIED
    for i in range(WEAPONS):
        id_weapons[i].id_status = IDENTIFIED
    for i in range(ARMORS):
        id_armors[i].id_status = IDENTIFIED
    for i in range(WANDS):
        id_wands[i].id_status = IDENTIFIED
    for i in range(POTIONS):
        id_potions[i].id_status = IDENTIFIED

def ncmp(s1, s2):
    return s1[:s1.index(":")] == s2
