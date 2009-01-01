from globals import *

_all__ = ['message', 'remessage', 'check_message', 'get_input_line']

def message(msg, intrpt=0):
    if intrpt:
        g.interrupted = 1
    g.cant_int = 1
    slurp()
    
    if not g.message_cleared:
        mvaddstr(MIN_ROW - 1, g.message_col, MORE)
        refresh()
        wait_for_ack("")
        check_message()
        
    g.message_line = msg
    mvaddstr(MIN_ROW - 1, 0, msg)
    addch(' ')
    refresh()
    g.message_cleared = 0
    g.message_col = len(msg)
    
    if g.did_int:
        onintr()
    g.cant_int = 0

def remessage():
    if g.message_line:
        message(g.message_line, 0)

def check_message():
    if g.message_cleared:
        return
    move(MIN_ROW - 1, 0)
    clrtoeol()
    move(rogue.row, rogue.col)
    refresh()
    g.message_cleared = 1

def get_input_line(buf, if_cancelled):
    raise

def slurp():
    # todo doesn't work
    #while True:
    #    getchar()
    pass