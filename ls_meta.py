# Listack v0.34
# ls_meta.py
# parser for meta programming
# Copyright McChuck, 2023
# May be freely redistributed and used with attribution under GPL3.


import sys, os
from collections import deque
from ls_helpers import *
from colorama import Fore, Back, Style

#   from meta import do_meta
#   do_meta(left/past, right/future, pattern), returns a list.
#   pattern:  [number of items from Left (stack), number of items from Right (queue), "pattern to implement"].
#   # = append  % = extend/unpack.
#   lowercase letters (a..z) are from Left/past stack, in order from deepest (a) to top (whatever it happens to be).
#   uppercase letters (A..Z) are from Right/future queue, in order from front (A) to rear (whatever it happens to be).
#   {} = block/quotation/lambda function, stored as a list.
#   [] = list, stored as a deque.
#   () Blocks are not checked.  You'll have to balance them yourself.
#
#   Example:  infix while using infix if
#   left/past = [whatever went before, [complex condition]]
#   right/future = [[complicated body], whatever comes after]
#   pattern = [1,1,"%a if [%A begin_while #a while #A] nop"]
#   produces: [complex condition if [complicated body begin_while [complex condition] while [complicated body]] nop]
#   You'll need to extend this onto the right/future.
#       new left/past: [whatever came before]
#       new right/future: [complex condition if [complicated body begin_while [complex condition] while [complicated body]] nop whatever comes after]
#   This can also be applied to the left/past to make fancy stack effects.  It's just a matter of where you store the result.

delim = ",'`\"[]{}()\\-#%"      #   cannot use these characters (or whitespace) in variable names.  Can use '.' at the beginning or ':' at the end.
digits = "0123456789"
sugar = ["then", "else", "do", "of"]

def parse_meta(line):
    original = line
    error = False
    parsed = deque([])
    list_depth = 0
    block_depth = 0
    in_s_string = False
    in_d_string = False
    in_b_string = False
    b_solo = False
    in_list = False
    in_block = False
    in_num = False
    in_float = False
    in_word = False
    in_var = False
    minus = False
    line += "   "
    current = ""
    word = ""
    consumed = ""
    try:
        while line:
            previous = current
            consumed = consumed + previous
            current = line[0]
            line = line[1:]

            if b_solo:      # is this a lone backquote?
                b_solo = False
                if current.isspace():
                    continue
                if current in delim:
                    print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} ` only applies to words, not: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                    raise ValueError
                else:
                    in_word = True
                    in_b_string = True
                    b_solo = False

            if in_d_string:     # ""
                if current == '"' and previous !="\\":
                    in_d_string = False
                    if not in_list and not in_block:
                        parsed.append(word)
                        word = ""
                    else:
                        word += current
                else:
                    word += current
                continue

            if in_s_string:     # ''
                if current == "'" and previous != "\\":
                    in_s_string = False
                    if not in_list and not in_block:
                        parsed.append(word)
                        word = ""
                    else:
                        word += current
                else:
                    word += current
                continue

            if in_block:        # {}
                if current == '"' and previous != "\\":
                    in_d_string = True
                elif current == "'" and previous != "\\":
                    in_s_string = True
                elif current == "{":
                    block_depth += 1
                    if block_depth > 10000:
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} block depth exceeded 10,000: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                elif current == "[":
                    list_depth += 1
                    if list_depth > 10000:
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} list depth exceeded 10,000: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                elif current == "]":
                    list_depth -= 1
                    if list_depth < 0:
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} attempt to close unopened list: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                elif current == "}":
                    block_depth -= 1
                    if block_depth < 0:      # not sure how you got here
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} attempt to close unopened block: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                    elif block_depth == 0:
                        in_block = False
                        returned = parse_meta(word)
                        returned = ls_block(returned)
                        parsed.append(returned)
                        word = ""
                        continue
                word += current
                continue

            if in_list:        # []
                if current == '"':
                    in_d_string = True
                elif current == "'":
                    in_s_string = True
                elif current == "{":
                    block_depth += 1
                    if block_depth > 10000:
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} block depth exceeded 10,000: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                elif current == "[":
                    list_depth += 1
                    if list_depth > 10000:
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} list depth exceeded 10,000: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                elif current == "]":
                    list_depth -= 1
                    if list_depth < 0:
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} attempt to close unopened list: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                    elif list_depth == 0:
                        in_list = False
                        returned = parse_meta(word)
                        returned = ls_list(returned)
                        parsed.append(returned)
                        word = ""
                        continue
                elif current == "}":
                    block_depth -= 1
                    if block_depth < 0:
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} attempt to close unopened block: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                word += current
                continue

            if in_var:
                if len(word) == 1:
                    if current.isalpha():
                        word += current
                    elif current == word:       #   ## or %%    --> # or %
                        word += current
                        in_var = False
                        parsed.append(word)
                        word = ""
                    else:
                        print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} variables must be a letter: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                        raise ValueError
                    continue
                elif len(word) == 2:
                    in_var = False
                    if current in digits:
                        word += current
                        parsed.append(word)
                        word = ""
                        continue
                    else:
                        parsed.append(word)
                        word = ""
                else:   # not sure how you got here
                    print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} variables must be a letter: {Fore.YELLOW}{word}{current}{Style.RESET_ALL}")
                    raise ValueError

            if in_num:
                if current == ".":
                    in_num = False
                    in_float = True
                    word += current
                    continue
                elif current in digits:
                    word += current
                    continue
                else:
                    in_num = False
                    parsed.append(int(word))
                    word = ""

            if in_float:
                if current in digits:
                    word += current
                    continue
                else:
                    in_float = False
                    if previous == ".":
                        word = word[:-1]
                        parsed.append(int(word))
                        word = "."
                        in_word = True
                    else:
                        parsed.append(float(word))
                        word = ""

            if in_word:
                if word == "." and current in ["-", "%"]:
                    in_word = False
                    word += current
                    parsed.append(ls_word(word))
                    word = ""
                    continue
                if in_b_string and current == "." and word == "":
                    word = current
                    continue
                if current in delim or current.isspace() or current in [".", ":"]:
                    in_word = False
                    if current == ":":
                        word += current
                    if in_b_string:
                        in_b_string = False     # save as block
                        returned = parse_commands(word)
                        word = ls_block(returned)
                    else:
                        word = ls_word(word)    # save as a command word so it is evaluated
                    if word in sugar:
                        pass
                    else:
                        parsed.append(word)
                    word = ""
                    if current == ":":          # ":" only allowed at end of words
                        continue
                    if current == ".":          # "." only allowed at beginning of words
                        word = current
                        in_word = True
                        continue
                else:
                    word += current
                    continue

            if current in digits:
                in_num = True
                in_float = False
                if minus:
                    word = "-"
                    minus = False
                word += current
                continue

            if minus:
                minus = False
                if current == ":":
                    parsed.append(ls_word("-:"))
                    word = ""
                    continue
                parsed.append(ls_word("-"))

            if current.isspace() or current == ",":
                if word != "":
                    parsed.append(word)
                    word = ""
                continue

            if current == "{":
                in_block = True
                block_depth += 1
            elif current == "[":
                in_list = True
                list_depth += 1
            elif current == "(":
                parsed.append(ls_word(current))
            elif current == ":":
                if previous == "(":
                    parsed[-1] = ls_word("(:")
            elif current == ")":
                parsed.append(ls_word(current))
            elif current == "'":
                in_s_string = True
                word = ""
            elif current == '"':
                in_d_string = True
                word = ""
            elif current == "`":        #  make a one word block
                b_solo = True
                word = ""
            elif current == "-":
                minus = True
            elif current in "#%":
                in_var = True
                word = current
            elif current == "\\":
                parsed.append(ls_word(current))
                word = ""
            else:
                in_word = True
                word = current

        if in_d_string or in_s_string:
            print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} unclosed string: {Fore.YELLOW}{word}{Style.RESET_ALL}")
            error = True
        if in_block:
            print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} unclosed block: {Fore.YELLOW}{word}{Style.RESET_ALL}")
            error = True
        if in_list:
            print(f"{Fore.RED}{Style.BRIGHT}Error:{Style.NORMAL} unclosed list: {Fore.YELLOW}{word}{Style.RESET_ALL}")
            error = True
        if in_num:
            parsed.append(int(word))
        if in_float:
            parsed.append(float(word))
        if in_word:
            parsed.append(word)
        if minus:
            parsed.append("-")
        if error:
            # print(f"in: {Fore.CYAN}{original}{Style.RESET_ALL}")
            print("Meta parser terminated.")
            raise ValueError
        return(parsed)

    except(IndexError, ValueError):
        print("Something went wrong during meta-parsing.")
        print(f"{Fore.GREEN}{consumed}{Fore.YELLOW}{word}{Fore.RED}{current}{Fore.CYAN}{line}{Style.RESET_ALL}\n")
        # print("Original:", original)
        print(*parsed)
        quit()


def scan_meta(left, right, pattern):
    no_copy = False
    output = deque([])
    # print("Scanning:", pattern)
    for index, instr in enumerate(pattern):
        unpack = False
        if type(instr) is ls_block:
            new_instr = ls_block(scan_meta(left, right, instr))
        elif type(instr) is ls_list:
            new_instr = ls_list(scan_meta(left, right, instr))
        else:
            if type(instr) is str and len(instr) > 0 and instr[0] == "%":   # unpack
                if instr[1] == "%":
                    instr="%"       # never mind, it's just %
                else:
                    unpack = True
                    instr = "#"+instr[1:]
            if type(instr) is str and len(instr) > 0 and instr[0] == '#':   # variable replacement
                if instr[1] == "#":
                    new_instr = "#"     # never mind, it's just #
                elif instr[1].islower():
                    where = ord(instr[1]) - ord('a')        # past/left
                    new_instr = left[where]
                elif instr[1].isupper():
                    where = ord(instr[1]) - ord('A')        # future/right
                    new_instr = right[where]
                else:
                    print("Warning: not a letter", instr)
                if len(instr) == 3 and instr[2] in digits:        # can only handle first 10 sub-elements
                    place = int(instr[2])                           # could use a second letter?  lower or upper?  Too confusing.
                    if place <= len(new_instr):
                        new_instr = new_instr[place]
                    else:
                        print("Warning: subscript", place, "out of range in", new_instr)
                elif len(instr) > 2:
                    print("Warning: improperly formatted variable", instr)

            else:
                new_instr = instr
        # print("New instruction:", new_instr)
        if unpack and is_seq(new_instr):
            extend_right(output, new_instr)
        else:
            push_right(output, new_instr)
    return(output)


def do_meta(raw_left, raw_right, raw_pattern):      # This is what you import
    num_l = raw_pattern[0]
    num_r = raw_pattern[1]
    pattern = raw_pattern[2]
    left = ls_slice(raw_left, -num_l)
    right = ls_slice(raw_right, num_r)
    pat = parse_meta(pattern)
    # print("Meta pattern", pat)
    # print("Left:", left)
    # print("Right:", right)
    new_pat = scan_meta(left, right, pat)
    new_pat=ls_block(new_pat)
    # print("Meta new pattern:", new_pat)
    return new_pat



def main(file_arg):
    output = deque([])
    raw = ""
    try:
        with open(file_arg, "r") as in_file:
            raw = in_file.read()
            in_file.close()
        output = parse_meta(raw)
        print("\n\nmeta-parsed output:", *output)
    except ValueError:
        print("Something went wrong while meta-parsing")


if __name__ == '__main__':
    main(sys.argv[1])
