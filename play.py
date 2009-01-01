from globals import *

__all__ = ['play_level']

def play_level():
    count = 0
    while True:
        g.interrupted = 0
        if g.hit_message:
            message(g.hit_message, 0)
            g.hit_message = ""
            
        move(rogue.row, rogue.col)
        refresh()
        
        ch = getchar()
        check_message()
        
        while True: # for "goto CH"
            if ch == '.':
                rest(count if count > 0 else 1)
            elif ch == 'i':
                inventory(rogue.pack, IS_OBJECT)
            #elif ch == 'p':
            #    inventory(g.level_objects, IS_OBJECT)
            elif ch == 'f':
                fight(0)
            elif ch == 'F':
                fight(1)
            elif ch in 'hjklyunb':
                single_move_rogue(ch, 1)
            elif ch in 'HJKLYUNB\010\012\013\014\031\025\016\002':
                multiple_move_rogue(ch)
            elif ch == 'e':
                eat()
            elif ch == 'q':
                quaff()
            elif ch == 'r':
                read_scroll()
            elif ch == 'm':
                move_onto()
            elif ch == 'd':
                drop()
            elif ch == '\020':
                remessage()
            elif ch == '>':
                if check_down():
                    return
            elif ch == '<':
                if check_up():
                    return
            elif ch == 'I':
                single_inventory()
            elif ch == '\022':
                wrefresh(curscr)
            elif ch == 'T':
                take_off()
            elif ch == 'W' or ch == 'P':
                wear()
            elif ch == 'w':
                wield()
            elif ch == 'c':
                call_it()
            elif ch == 'z':
                zapp()
            elif ch == 't':
                throw()
            elif ch == '\032':
                tstp()
            elif ch == '!':
                shell()
            elif ch == 'v':
                message("pyrogue: Version 1.0 (sma was here)", 0)
            elif ch == 'Q':
                quit()
            elif ch in "0123456789":
                count = 0
                while True:
                    count = 10 * count + ord(ch) - ord('0')
                    ch = getchar()
                    if ch < '0' or ch > '9': break
                continue # goto CH
            elif ch == ' ':
                pass
            else:
                message("unknown command")
            break
