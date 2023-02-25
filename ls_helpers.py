# Listack v0.38
# ls_helpers.py
# very basic helper functions
# Copyright McChuck, 2023
# May be freely redistributed and used with attribution under GPL3.


import sys, os, copy
from collections import deque
from colorama import Fore, Back, Style

class ls_word(str):
    pass

class ls_block(deque):
    pass

class ls_list(deque):
    pass

class ls_coll(deque):
    pass

def make_bool(item):
    if is_bool(item):
        answer = item
    elif item == 0:
        answer = True
    else:
        answer = item not in [None, "", (), {}, [], ls_word(""), ls_block([]), ls_list([]), ls_coll([]), ls_word("False"), ls_word("false"), ls_word("FALSE")]
    return answer

def is_deq(seq):
    return type(seq) is deque

def is_list(seq):
    return type(seq) is ls_list or type(seq) is ls_coll

def is_block(seq):      # {}
    return type(seq) is ls_block or type(seq) is ls_coll

def is_coll(item):
    return type(item) is ls_coll

def is_seq(seq):
    return type(seq) in [ls_block, ls_list, ls_coll, deque, list]

def is_int(item):
    return type(item) is int

def is_float(item):
    return type(item) is float

def is_number(item):
    return type(item) in [int, float]

def is_word(item):
    return type(item) is ls_word

def is_string(item):
    return type(item) is str

def is_alpha(item):
    return type(item) in [str, ls_word]

def is_bool(item):
    return type(item) is bool

def depth(seq):
    return len(seq) if is_seq(seq) else -1

def is_empty(seq):
    if not is_seq(seq):
        print(f"\n{Fore.RED}Warning: {Fore.YELLOW}is_empty({Fore.CYAN}{seq}{Fore.YELLOW}): not a sequence{Style.RESET_ALL}", flush = True)
        raise ValueError
    return True if depth(seq) == 0 else False

def is_single_word(item):
    if not is_alpha(item):
        return False
    for c in item:
        if c.isspace():
            return False
    return True

def is_valid_number(item):
    if is_number(item):
        return True
    test = copy_of(item)
    if test[0] == "-":
        test = test[1:]
    dots = 0
    for c in test:
        if c not in "1234567890.":
            return False
        if c == ".":
            dots += 1
    if dots > 1:
        return False
    return True

def convert_to_number(item):
    if is_number(item):
        return(item)
    item = item.strip()
    if is_valid_number(item):
        if "." in item:
            return float(item)
        else:
            return int(item)
    else:
        return False

def is_valid_word(item):
    if not is_single_word(item):
        return False
    if item in ["`", "\\", "%:", "%", ".%", "/%:", "/%", "./%", "..", "|>", "<|"]:
        return True
    if is_valid_number(item):
        return True
    for c in item:
        if c in "[]{}()|'\"\\,#%-":
            if item.count("\\") == 1 and item[0] == "\\":
                pass
            else:
                return False
    if item[0] in "1234567890-":
        return False
    dots = item.count(".")
    if (dots > 1) or (dots == 1 and item[0] != "."):
        if item[0] in "@$!" and item[1] == ".":
            pass
        else:
            return False
    colons = item.count(":")
    if (colons > 1) or (colons == 1 and item[-1] != ":"):
        return False
    if item[0] == "." and item[1] in "1234567890":
        return False
    if item[0] == "." and item[-1] == ":":
        return False
    return True

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
    max_number = len(seq)
    if abs(num) > max_number:
        if num > 0:
            num = max_number
        else:
            num = -max_number
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


def my_pretty_print(seq, print_quotes = False):
    if is_coll(seq):
        max_len = len(seq) - 1
        open_symbol = "("
        close_symbol = ")"
        print(f"{Fore.YELLOW}{open_symbol}{Style.RESET_ALL}", end="")
        for count, item in enumerate(seq):
            my_pretty_print(item, print_quotes)
            if count < max_len:
                print(end=" ")
        print(f"{Fore.YELLOW}{close_symbol}{Style.RESET_ALL}", end="")
    elif is_block(seq):
        max_len = len(seq) - 1
        open_symbol = "{"
        close_symbol = "}"
        print(f"{Fore.RED}{open_symbol}{Style.RESET_ALL}", end="")
        for count, item in enumerate(seq):
            my_pretty_print(item, print_quotes)
            if count < max_len:
                print(end=" ")
        print(f"{Fore.RED}{close_symbol}{Style.RESET_ALL}", end="")

    elif is_list(seq):
        max_len = len(seq) - 1
        open_symbol = "["
        close_symbol = "]"
        print(f"{Fore.GREEN}{open_symbol}{Style.RESET_ALL}", end="")
        for count, item in enumerate(seq):
            my_pretty_print(item, print_quotes)
            if count < max_len:
                print(end=", ")
        print(f"{Fore.GREEN}{close_symbol}{Style.RESET_ALL}", end="")

    elif type(seq) is deque:
        max_len = len(seq) - 1
        open_symbol = "["
        close_symbol = "]"
        print(f"{Fore.MAGENTA}{open_symbol}{Style.RESET_ALL}", end="")
        for count, item in enumerate(seq):
            my_pretty_print(item, print_quotes)
            if count < max_len:
                print(end=", ")
        print(f"{Fore.MAGENTA}{close_symbol}{Style.RESET_ALL}", end="")

    elif type(seq) is list:
        max_len = len(seq) - 1
        for count, item in enumerate(seq):
            my_pretty_print(item, print_quotes)
            if count < max_len:
                print(" ", end = "")
            else:
                print("  ", end = "")

    elif is_string(seq) and print_quotes:
        print(f'"{seq}"', end="")
    elif is_string(seq):
        print(f'{seq}', end="")
    elif is_int(seq):
        print(f'{Fore.BLUE}{seq}{Style.RESET_ALL}', end="")
    elif is_float(seq):
        print(f'{Fore.CYAN}{seq}{Style.RESET_ALL}', end="")
    elif is_bool(seq):
        print(f'{Fore.MAGENTA}{seq}{Style.RESET_ALL}', end="")
    else:
        print(f"{Fore.YELLOW}{seq}{Style.RESET_ALL}", end="")

def my_pretty_println(seq, print_quotes = False):
    my_pretty_print(seq, print_quotes)
    print(flush=True)

def my_print(seq, print_quotes = False):
    if is_coll(seq):
        max_len = len(seq) - 1
        open_symbol = "("
        close_symbol = ")"
        print(f"{open_symbol}", end="")
        for count, item in enumerate(seq):
            my_print(item, print_quotes)
            if count < max_len:
                print(end=" ")
        print(f"{close_symbol}", end="")

    elif is_block(seq):
        max_len = len(seq) - 1
        open_symbol = "{"
        close_symbol = "}"
        print(f"{open_symbol}", end="")
        for count, item in enumerate(seq):
            my_print(item, print_quotes)
            if count < max_len:
                print(end=" ")
        print(f"{close_symbol}", end="")

    elif is_list(seq):
        max_len = len(seq) - 1
        open_symbol = "["
        close_symbol = "]"
        print(f"{open_symbol}", end="")
        for count, item in enumerate(seq):
            my_print(item, print_quotes)
            if count < max_len:
                print(end=", ")
        print(f"{close_symbol}", end="")



    elif is_string(seq) and print_quotes:
        print(f'"{seq}"', end="")
    else:
        print(f"{seq}", end="")

def my_println(seq, print_quotes = False):
    my_print(seq, print_quotes)
    print("", flush=True)

def ls_type(item):  # returns type of item
    if is_coll(item):
        result = "COLL"
    elif is_list(item):
        result = "LIST"
    elif is_block(item):
        result = "BLOCK"
    elif is_int(item):
        result = "INT"
    elif is_float(item):
        result = "FLOAT"
    elif is_string(item):
        result = "STR"
    elif is_word(item):
        result = "WORD"
    elif is_bool(item):
        result = "BOOL"

    else:
        result = False  # how did you get here?
    return result

def all_str_or_num(seq):
    total = len(seq)
    alphas = 0
    numbers = 0
    for item in seq:
        if isinstance(item,(str, ls_word)):
            alphas += 1
        elif isinstance(item,(int, float)):
            numbers += 1
    return (alphas == total) or (numbers == total)
