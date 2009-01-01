import sys

from globals import *

def main():
    init()
    while True:
        clear_level()
        make_level()
        put_objects()
        put_stairs()
        put_monsters()
        put_player()
        light_up_room()
        print_stats()
        play_level()
        g.level_objects.next_object = None
        g.level_monsters.next_object = None
        clear()

# hackish attempt to fix up the imports
for m in sys.modules.values():
    if hasattr(m, 'MONSTERS'):
        m.__dict__.update(sys.modules['globals'].__dict__)

try:
    main()
except:
    # we have to delay the exception until init.clean_up to see it
    g.exc = sys.exc_info()