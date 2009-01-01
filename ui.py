import curses

from globals import *

COLS = 80
LINES = 24

def initscr(): g.curses = curses.initscr()
from curses import cbreak as crmode
from curses import noecho
from curses import nonl
from curses import endwin
from curses import beep
def clear(): g.curses.clear()
def clrtoeol(): g.curses.clrtoeol()
def getchar(): return g.curses.getkey()
def move(row, col): g.curses.move(row, col)
def mvaddch(row, col, ch): g.curses.addch(row, col, ch)
def mvaddstr(row, col, s): g.curses.addstr(row, col, s)
def mvinch(row, col): return chr(g.curses.inch(row, col))
def refresh(): g.curses.refresh()
def standout(): g.curses.standout()
def standend(): g.curses.standend()
def addch(ch): g.curses.addch(ch)
def addstr(s): g.curses.addstr(s)
