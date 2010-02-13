from globals import *

__all__ = ['add_to_pack', 'remove_from_pack', 'pick_up', 'drop',
           'make_avail_ichar', 'wait_for_ack', 'get_pack_letter', 'take_off',
           'wear', 'wield', 'call_it']

CURSE_MESSAGE = "you can't, it appears to be cursed"

def add_to_pack(obj, pack, condense):
    if condense:
        op = check_duplicate(obj, pack)
        if op:
            return op
        else:
            obj.ichar = next_avail_ichar()
    if not pack.next_object:
        pack.next_object = obj
    else:
        op = pack.next_object
        while op.next_object:
            op = op.next_object
        op.next_object = obj
    obj.next_object = None
    return obj

def remove_from_pack(obj, pack):
    while pack.next_object != obj:
        pack = pack.next_object
    pack.next_object = pack.next_object.next_object

def pick_up(row, col):
    obj = object_at(g.level_objects, row, col)
    status = 1
    
    if obj.what_is == SCROLL and obj.which_kind == SCARE_MONSTER and obj.picked_up > 0:
        message("the scroll turns to dust as you pick it up", 1)
        remove_from_pack(obj, g.level_objects)
        remove_mask(row, col, SCROLL)
        status = 0
        id_scrolls[SCARE_MONSTER].id_status = IDENTIFIED
        return None, status
    
    if obj.what_is == GOLD:
        rogue.gold += obj.quantity
        remove_mask(row, col, GOLD)
        remove_from_pack(obj, g.level_objects)
        print_stats()
        return obj, status
    
    if get_pack_count(obj) >= MAX_PACK_COUNT:
        message("Pack too full", 1)
        return None, status
    
    if obj.what_is == AMULET:
        g.has_amulet = 1
        
    remove_mask(row, col, obj.what_is)
    remove_from_pack(obj, g.level_objects)
    obj = add_to_pack(obj, rogue.pack, 1)
    obj.picked_up += 1
    return obj, status
    
def drop():
    if screen[rogue.row][rogue.col] & IS_OBJECT:
        message("There's already something there", 0)
        return
    if not rogue.pack.next_object:
        message("You have nothing to drop", 0)
        return
    ch = get_pack_letter("drop what? ", IS_OBJECT)
    if ch == CANCEL:
        return
    obj = get_letter_object(ch)
    if not obj:
        message("No such item.", 0)
        return
    if obj == rogue.weapon:
        if obj.is_cursed:
            message(CURSE_MESSAGE, 0)
            return
        rogue.weapon = None
    elif obj == rogue.armor:
        if obj.is_cursed:
            message(CURSE_MESSAGE, 0)
            return
        rogue.armor = None
        print_stats()
    
    obj.row = rogue.row
    obj.col = rogue.col
    
    if obj.quantity > 1 and obj.what_is != WEAPON:
        obj.quantity -= 1
        new = get_an_object()
        new = obj.copy()
        new.quantity = 1
        obj = new
        #goto ADD
        add_to_pack(obj, g.level_objects, 0)
        add_mask(rogue.row, rogue.col, obj.what_is)
        message("dropped " + get_description(obj), 0)
        register_move()
        return
    
    if obj.what_is == AMULET:
        g.has_amulet = 0
        
    make_avail_ichar(obj.ichar)
    remove_from_pack(obj, rogue.pack)
    #ADD:
    add_to_pack(obj, g.level_objects, 0)
    add_mask(rogue.row, rogue.col, obj.what_is)
    message("dropped " + get_description(obj), 0)
    register_move()
    
def check_duplicate(obj, pack):
    if not (obj.what_is & (WEAPON | FOOD | SCROLL | POTION)):
        return None
    op = pack.next_object
    while op:
        if op.what_is == obj.what_is and op.which_kind == obj.which_kind:
            if obj.what_is != WEAPON or (obj.what_is == WEAPON and (obj.which_kind == ARROW or obj.which_kind == SHURIKEN) and obj.quiver == op.quiver):
                op.quantity += obj.quantity
                return op
        op = op.next_object
    return None

def next_avail_ichar():
    for i in range(26):
        if not g.ichars[i]:
            g.ichars[i] = 1
            return chr(i + ord('a'))
    return ''

def make_avail_ichar(ch):
    g.ichars[ord(ch) - ord('a')] = 0
    
def wait_for_ack(prompt):
    if prompt:
        addstr(MORE)
    while getchar() != ' ':
        pass

def get_pack_letter(prompt, mask):
    first_miss = 1
    message(prompt, 0)
    ch = getchar()
    while True:
        while not is_pack_letter(ch):
            if ch != '':
                beep()
            if first_miss:
                #WHICH:
                message(prompt, 0)
                first_miss = 0
            ch = getchar()
        if ch == LIST:
            check_message()
            inventory(rogue.pack, mask)
            #goto WHICH
            first_miss = 1
            ch = ''
            continue
        break
    check_message()
    return ch

def take_off():
    if rogue.armor:
        if rogue.armor.is_cursed:
            message(CURSE_MESSAGE, 0)
        else:
            mv_aquatars()
            obj = rogue.armor
            rogue.armor = None
            message("was wearing " + get_description(obj), 0)
            print_stats()
            register_move()
    else:
        message("not wearing any", 0)

def wear():
    if rogue.armor:
        message("your already wearing some", 0)
        return
    ch = get_pack_letter("wear what? ", ARMOR)
    if ch == CANCEL:
        return
    obj = get_letter_object(ch)
    if not obj:
        message("No such item.", 0)
        return
    if obj.what_is != ARMOR:
        message("You can't wear that", 0)
        return
    rogue.armor = obj
    obj.identified = 1
    message(get_description(obj), 0)
    print_stats()
    register_move()
    
def wield():
    if rogue.weapon and rogue.weapon.is_cursed:
        message(CURSE_MESSAGE, 0)
        return
    ch = get_pack_letter("wield what? ", WEAPON)
    if ch == CANCEL:
        return
    obj = get_letter_object(ch)
    if not obj:
        message("No such item.", 0)
        return
    if obj.what_is != WEAPON:
        message("You can't wield that", 0)
        return
    if obj == rogue.weapon:
        message("in use", 0)
    else:
        rogue.weapon = obj
        message(get_description(obj), 0)
        register_move()

def call_it():
    ch = get_pack_letter("call what? ", SCROLL | POTION | WAND)
    if ch == CANCEL:
        return
    obj = get_letter_object(ch)
    if not obj:
        message("No such item.", 0)
        return
    if not obj.what_is & (SCROLL | POTION | WAND):
        message("surely you already know what that's called", 0)
        return
    id_table = get_id_table(obj)
    
    buf = get_input_line(id_table[obj.which_kind].title, False)
    if buf:
        id_table[obj.which_kind].id_status = CALLED
        id_table[obj.which_kind].title = buf

def get_pack_count(new_obj):
    count = 0
    
    obj = rogue.pack.next_object
    while obj:
        if obj.what_is != WEAPON:
            count += obj.quantity
        else:
            if new_obj.what_is != WEAPON or\
                (new_obj.which_kind != ARROW and new_obj.which_kind != SHURIKEN) or\
                new_obj.which_kind != obj.which_kind or\
                new_obj.quiver != obj.quiver:
                count += 1
        obj = obj.next_object
    
    return count