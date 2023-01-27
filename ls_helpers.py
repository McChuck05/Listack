#   Listack helper functions v2

import sys, os, copy
from collections import deque
from colorama import Fore, Back, Style

class ls_word(str):
    pass

class ls_block(deque):
    pass

class ls_list(deque):
    pass

def make_bool(item):
    if item in [None, False, 0.0, 0, "", "0", "0.0", "false", "False", "FALSE", (), {}, [], ls_word(""), ls_block([]), ls_list([])]:
        return False
    else:
        return True
def is_deq(seq):
    return True if type(seq) is deque else False

def is_list(seq):
    return True if type(seq) is ls_list else False

def is_block(seq):      # {}
    return True if type(seq) is ls_block else False

def is_seq(seq):
    return True if type(seq) in [ls_block, ls_list, deque, list] else False

def is_int(item):
    return True if type(item) is int else False

def is_float(item):
    return True if type(item) is float else False

def is_number(item):
    return True if type(item) in [int, float] else False

def is_word(item):
    return True if type(item) is ls_word else False

def is_string(item):
    return True if type(item) is str else False

def is_alpha(item):
    return True if type(itme) in [str, ls_word] else False

def is_bool(item):
    return True if item in [True, False] else False

def depth(seq):
    return len(seq) if is_seq(seq) else -1

def is_empty(seq):
    if not is_seq(seq):
        print(f"\n{Fore.RED}Warning: {Fore.YELLOW}is_empty({Fore.CYAN}{seq}{Fore.YELLOW}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    return True if depth(seq) == 0 else False

def copy_of(item):
    return copy.deepcopy(item) if is_seq(item) else copy.copy(item)

def reversed_copy(seq):
    if is_seq(seq):
        new = copy_of(seq)
        new.reverse()
        return new
    else:
        return seq

def push_right(seq, item):      # side effects
    if is_seq(seq):
        seq.append(copy_of(item))
    else:
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}push_right({Fore.CYAN}{seq}{Fore.YELLOW}, {item}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError

def push_left(seq, item):      # side effects
    if is_seq(seq):
        seq.appendleft(copy_of(item))
    else:
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}push_left({Fore.CYAN}{seq}{Fore.YELLOW}, {item}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError

def pop_right(seq):         # side effects
    if is_seq(seq):
        if not is_empty(seq):
            return seq.pop()
        else:
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}pop_right({Fore.CYAN}{seq}{Fore.YELLOW}): empty{Style.RESET_ALL}", flush = True)
            return False
    else:
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}pop_right({Fore.CYAN}{seq}{Fore.YELLOW}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError

def pop_left(seq):          # side effects
    if is_seq(seq):
        if not is_empty(seq):
            return seq.popleft()
        else:
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}pop_left({Fore.CYAN}{seq}{Fore.YELLOW}): empty{Style.RESET_ALL}", flush = True)
            return False
    else:
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}pop_left({Fore.CYAN}{seq}{Fore.YELLOW}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError

def extend_right(seq, item):    # side effects
    if is_seq(seq):
        new_item = copy_of(item)
        if is_seq(new_item):
            if is_empty(new_item):
                seq.append(new_item)
            else:
                seq.extend(new_item)
        else:
            seq.append(new_item)
    else:
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}extend_right({Fore.CYAN}{seq}{Fore.YELLOW}, {item}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError

def extend_left(seq, item):     # side effects
    if is_seq(seq):
        new_item = copy_of(item)
        if is_seq(new_item):
            if is_empty(new_item):
                seq.appendleft(new_item)
            else:
                new_item.reverse()
                seq.extendleft(new_item)
        else:
            seq.appendleft(new_item)
    else:
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}extend_left({Fore.CYAN}{seq}{Fore.YELLOW}, {item}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError

def push_stack(seq, item):
    push_right(seq, item)

def push_q(seq, item):
    push_left(seq, item)

def pop_stack(seq):
    return (pop_right(seq))

def pop_q(seq):
    return (pop_left(seq))

def ls_slice(seq, num):    # side effects      extracts num items from a sequence: negative from right, positive from left, maintaining order.
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}ls_slice({Fore.CYAN}{seq}{Fore.YELLOW}, {num}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif not is_int(num):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}ls_slice({seq}, {Fore.CYAN}{num}{Fore.YELLOW}): not an int{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif num == 0:        # do nothing
        return seq
    temp = []
    if num < 0:          # slice from right end
        for i in range(-num):
            temp.append(seq.pop())
        temp.reverse()
    else:               # slice from left end
        for i in range(num):
            temp.append(seq.popleft())
    if is_block(seq):
        return ls_block(temp)
    elif is_list(seq):
        return ls_list(temp)
    else:
        return deque(temp)

def peek_n(seq, place):
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}peek_n({Fore.CYAN}{seq}{Fore.YELLOW}, {place}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif not is_int(place):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}peek_n({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): not an int{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif place >= len(seq) or place < -len(seq) :
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}peek_n({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): out of bounds{Style.RESET_ALL}", flush = True)
        raise IndexError
    else:
        return (seq[place])

def poke_n(seq, place, item):       # side effects
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}poke_n({Fore.CYAN}{seq}{Fore.YELLOW}, {place}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif not is_int(place):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}poke_n({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): not an int{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif place >= len(seq) or place < -len(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}poke_n({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): out of bounds{Style.RESET_ALL}", flush = True)
        raise IndexError
    else:
        seq[place] = item

def push_n(seq, place, item):       # side effects
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}push_n({Fore.CYAN}{seq}{Fore.YELLOW}, {place}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif not is_int(place):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}push_n({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): not an int{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif place > len(seq) or place < -(len(seq)+1):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}push_n({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): out of bounds{Style.RESET_ALL}", flush = True)
        raise IndexError
    else:
        seq.insert(place, item)     # note: to insert after last item (extend to right), place = depth(seq)

def pop_n(seq, place):              # side effects
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}pop_n({Fore.CYAN}{seq}{Fore.YELLOW}, {place}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif not is_int(place):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}pop_n({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): not an int{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif place >= len(seq) or place < -len(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}peek_n({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): out of bounds{Style.RESET_ALL}", flush = True)
        raise IndexError
    item = copy_of(seq[place])
    del(seq[place])
    return item

def insert_left(seq, place, item):        # side effects
    if not is_int(place):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}insert_left({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): not an int{Style.RESET_ALL}", flush = True)
        raise ValueError
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}insert_left({Fore.CYAN}{seq}{Fore.YELLOW}, {place}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    push_n(seq, place, item)

def insert_right(seq, place, item):       # side effects
    if not is_int(place):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}insert_right({seq}, {Fore.CYAN}{place}{Fore.YELLOW}): not an int{Style.RESET_ALL}", flush = True)
        raise ValueError
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}insert_right({Fore.CYAN}{seq}{Fore.YELLOW}, {place}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    new_place = depth(seq) - place  # inserts after each element.  Could also reverse the seq twice.
    push_n(seq, new_place, item)

def unpack_right(seq):     # side effects      [a,b,[1,2,3]] --> [a,b,1,2,3]
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}unpack_right({Fore.CYAN}{seq}{Fore.YELLOW}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif is_empty(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}unpack_right({Fore.CYAN}{seq}{Fore.YELLOW}): empty{Style.RESET_ALL}", flush = True)
        raise ValueError
    item = pop_right(seq)
    extend_right(seq, item)

def unpack_left(seq):     # side effects      [[a,b,c],1,2,3] --> [a,b,c,1,2,3]
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}unpack_left({Fore.CYAN}{seq}{Fore.YELLOW}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    elif is_empty(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}unpack_left({Fore.CYAN}{seq}{Fore.YELLOW}): empty{Style.RESET_ALL}", flush = True)
        raise ValueError
    item = pop_left(seq)
    extend_left(seq, item)

def pack(seq):                   #   packs an entire sequence into a single item
    if not is_seq(seq):
        print(f"\n{Fore.RED}Error: {Fore.YELLOW}pack({Fore.CYAN}{seq}{Fore.YELLOW}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    new = [copy_of(seq)]
    if is_block(seq):
        return ls_block(new)
    elif is_list(seq):
        return ls_list(new)
    else:
        return deque(new)


def my_print(seq, print_quotes):
    if is_block(seq):
        open_symbol = "{ "
        close_symbol = "} "
        print(f"{Fore.CYAN}{open_symbol}{Style.RESET_ALL}", end="")
        for item in seq:
            my_print(item, print_quotes)
            print(end=" ")
        print(f"{Fore.CYAN}{close_symbol}{Style.RESET_ALL}", end="")
    elif is_list(seq):
        open_symbol = "[ "
        close_symbol = "] "
        print(f"{Fore.YELLOW}{open_symbol}{Style.RESET_ALL}", end="")
        for item in seq:
            my_print(item, print_quotes)
            print(end=" ")
        print(f"{Fore.YELLOW}{close_symbol}{Style.RESET_ALL}", end="")
    elif is_seq(seq):
        open_symbol = "( "
        close_symbol = ") "
        print(f"{Fore.RED}{open_symbol}{Style.RESET_ALL}", end="")
        for item in seq:
            my_print(item, print_quotes)
            print(end=" ")
        print(f"{Fore.RED}{close_symbol}{Style.RESET_ALL}", end="")
    elif is_string(seq) and print_quotes:
        print(f'"{seq}"', end="")
    else:
        print(seq, end="")

def my_println(seq, print_quotes):
    my_print(seq, print_quotes)
    print(flush=True)
