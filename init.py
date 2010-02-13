import os, sys

from globals import *

__all__ = ['init', 'clean_up', 'onintr']

def init():
    g.player_name = os.getlogin()
    if not g.player_name:
        print >>sys.stderr, "Hey! Who are you?"
        sys.exit(1)
    print "Hello %s, just a moment while I dig the dungeon..." % g.player_name
    
    import atexit
    atexit.register(byebye)
    
    initscr()
    for i in range(26):
        g.ichars[i] = 0
    start_window()
    ##signal(SIGTSTP, tstp)
    ##signal(SIGINT, onintr)
    ##signal(SIGQUIT, byebye)
    ##if LINES < 24 or COLS < 80:
    ##    clean_up("must be played on 24 x 80 screen")
    ##LINES = SROWS
    
    srandom(os.getpid())
    init_items()
    
    g.level_objects.next_object = None
    g.level_monsters.next_object = None
    player_init()
    
def player_init():
    rogue.pack.next_object = None
    obj = get_an_object()
    get_food(obj)
    add_to_pack(obj, rogue.pack, 1)
    
    # initial armor
    obj = get_an_object()
    obj.what_is = ARMOR
    obj.which_kind = RING
    obj.clasz = RING + 2
    obj.is_cursed = 0
    obj.is_protected = 0
    obj.damage_enchantment = 1
    obj.identified = 1
    add_to_pack(obj, rogue.pack, 1)
    rogue.armor = obj
    
    # initial weapons
    obj = get_an_object()
    obj.what_is = WEAPON
    obj.which_kind = MACE
    obj.is_cursed = 0
    obj.damage = "2d3"
    obj.to_hit_enchantment = 1
    obj.damage_enchantment = 1
    obj.identified = 1
    add_to_pack(obj, rogue.pack, 1)
    rogue.weapon = obj
    
    obj = get_an_object()
    obj.what_is = WEAPON
    obj.which_kind = BOW
    obj.is_cursed = 0
    obj.damage = "1d2"
    obj.to_hit_enchantment = 1
    obj.damage_enchantment = 0
    obj.identified = 1
    add_to_pack(obj, rogue.pack, 1)
    
    obj = get_an_object()
    obj.what_is = WEAPON
    obj.which_kind = ARROW
    obj.quantity = get_rand(25, 35)
    obj.is_cursed = 0
    obj.damage = "1d2"
    obj.to_hit_enchantment = 0
    obj.damage_enchantment = 0
    obj.identified = 1
    add_to_pack(obj, rogue.pack, 1)

def clean_up(estr):
    move(LINES - 1, 0)
    refresh()
    stop_window()
    print estr
    if g.exc and g.exc[0] != SystemExit:
        import traceback
        print >>sys.stderr, "---------"
        traceback.print_exception(*g.exc)
        print >>sys.stderr, "---------"
    sys.exit(0)

def start_window():
    crmode()
    noecho()
    nonl()
    edchars(0)

def stop_window():
    endwin()
    edchars(1)

def byebye():
    clean_up("Okay, bye bye!")

def onintr():
    if g.cant_int:
        g.did_int = 1
    else:
        ##signal(SIGINT, SIG_IGN)
        check_message()
        message("interrupt", 1)
        ##signal(SIGINT, onintr)
    
def edchars(mode):
    pass

