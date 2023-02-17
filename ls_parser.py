# Listack v0.38
# ls_parser.py
# main parser for target files
# Copyright McChuck, 2023
# May be freely redistributed and used with attribution under GPL3.


import sys, os
from ls_helpers import *
from collections import deque
from colorama import Fore, Back, Style

#   from command_parser import parse_commands
#   Listack command parser.
#   {} = block/quotation/lambda function, stored as a deque.  When applied, gets unpacked to the front of the future command queue.
#   [] = list, stored as a deque (double ended queue).  When applied, gets pushed onto the data stack.
#   () blocks are not checked.  You'll have to balance them yourself.
#   "N (" creates a new data stack and local variable scope, taking N items from the top of the previous stack, and also storing them in local variables A..N.
#   ")" pops the current data stack and local variable scope, moving the remaining items onto the stack below.
#   Local variables A..Z are automatically created and initialized to "" in the interpreter.
#   Global auxiliary stacks a..z are automatically created and initialized to [] in the interpreter.


delim = ",'`\"[]{}()|\\-#%"      #   cannot use these characters (or whitespace) in variable names, except can begin with '.', end with ':'
digits = "0123456789"           #   the built in functions act weird with some unicode characters.
sugar = ["then", "else", "do", "of"]

def parse_commands(text, total_depth, is_meta = False, debug = False, verbose = False):
    original = text
    text = text.strip()
    parsed = deque([])
    list_depth = 0
    block_depth = 0
    coll_depth = 0
    scope_depth = 0
    in_s_string = False
    in_d_string = False
    in_b_string = False
    b_solo = False
    in_list = False
    in_block = False
    in_coll = False
    in_num = False
    in_float = False
    in_word = False
    in_comment = False
    minus = False
    text += "   "
    current = ""
    word = ""
    consumed = ""
    in_var = False
    err = ""


    if total_depth > 1000:
        err = "total depth exceeded 1,000"
        raise ValueError

    if debug and verbose:
        print(f"{Fore.GREEN}Parsing:\n{Fore.BLUE}{text}{Style.RESET_ALL}")

    try:
        while text:
            previous = current
            consumed = consumed + previous
            current = text[0]
            text = text[1:]

            # if debug and verbose:
            #     print(f"{Fore.GREEN}{word[:40]} {Fore.YELLOW}{current}{Style.RESET_ALL} ")

            if in_comment:
                if current in "\n\r":
                    in_comment = False
                continue

            if b_solo:      # is this a lone backquote?
                b_solo = False
                if current.isspace():
                    continue
                if current in delim:
                    err = "` only applies to words, not:"
                    raise ValueError
                else:
                    in_word = True
                    in_b_string = True
                    b_solo = False

            if in_d_string:     # "string"
                if current == '"' and previous != "\\":
                    in_d_string = False
                    if not in_list and not in_block and not in_coll:
                        decoded_word = bytes(word, "utf-8").decode("unicode_escape") # python3 string decoder
                        parsed.append(decoded_word)
                        word = ""
                    else:
                        word += current
                elif current in "\n\r":
                    err = "strings should be closed before the end of line:"
                    raise ValueError
                else:
                    word += current
                continue

            if in_s_string:     # 'string'
                if current == "'" and previous != "\\":
                    in_s_string = False
                    if not in_list and not in_block and not in_coll:
                        decoded_word = bytes(word, "utf-8").decode("unicode_escape") # python3 string decoder
                        parsed.append(decoded_word)
                        word = ""
                    else:
                        word += current
                elif current in "\n\r":
                    err = "strings should be closed before the end of line:"
                    raise ValueError
                else:
                    word += current
                continue

            if in_block and current == "}":
                block_depth -= 1
                if block_depth < 0:
                    err = "attempt to close unopened block: }"
                    raise ValueError
                if block_depth == 0:
                    in_block = False
                    total_depth += 1
                    returned = parse_commands(word, total_depth, is_meta, debug, verbose)
                    total_depth -= 1
                    returned = ls_block(returned)
                    parsed.append(returned)
                    word = ""
                    if debug and verbose:
                        print(f"{Fore.YELLOW}Returning:{Style.RESET_ALL}", end=" ")
                        my_pretty_println(returned, True)
                    continue
                word += current
                continue
            elif in_list and current == ']':
                list_depth -= 1
                if list_depth < 0:
                    err = "attempt to close unopened list: ]"
                    raise ValueError
                if list_depth == 0:
                    in_list = False
                    total_depth += 1
                    returned = parse_commands(word, total_depth, is_meta, debug, verbose)
                    total_depth -= 1
                    returned = ls_list(returned)
                    parsed.append(returned)
                    word = ""
                    if debug and verbose:
                        print(f"{Fore.YELLOW}Returning:{Style.RESET_ALL}", end = " ")
                        my_pretty_println(returned, True)
                    continue
                word += current
                continue
            elif in_coll and current == ')':
                coll_depth -= 1
                if coll_depth < 0:
                    err = "attempt to close unopened collection: )"
                    raise ValueError
                if coll_depth == 0:
                    in_coll = False
                    total_depth += 1
                    returned = parse_commands(word, total_depth, is_meta, debug, verbose)
                    total_depth -= 1
                    returned = ls_coll(returned)
                    parsed.append(returned)
                    word = ""
                    if debug and verbose:
                        print(f"{Fore.YELLOW}Returning:{Style.RESET_ALL}", end = " ")
                        my_pretty_println(returned, True)
                    continue
                word += current
                continue

            if in_list or in_block or in_coll:
                if current == '"' and previous != "\\":
                    in_d_string = True
                elif current == "'" and previous != "\\":
                    in_s_string = True
                elif current == "{":
                    block_depth += 1
                elif current == "[":
                    list_depth += 1
                elif current == "(":
                    coll_depth += 1
                elif current == "}":
                    block_depth -= 1
                    if block_depth < 0:
                        err = "attempt to close unopened block: }"
                        raise ValueError
                elif current == "]":
                    list_depth -= 1
                    if list_depth < 0:
                        err = "attempt to close unopened list: ]"
                        raise ValueError
                elif current == ")":
                    coll_depth -= 1
                    if coll_depth < 0:
                        err = "attempt to close unopened collection: )"
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
                        err = "meta variables must be a letter:"
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
                    err = "meta variables must be a letter:"
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
                        if current.isspace():   # Convert "123. " to 123.0
                            word += "0"
                            parsed.append(float(word))
                            word = ""
                        else:
                            word = word[:-1]
                            parsed.append(int(word))
                            word = "."
                            in_word = True
                    else:
                        parsed.append(float(word))
                        word = ""

            if in_word:
                if word == "\\" and current.isspace():
                    continue
                if word == "@" and current == ".":
                    word += current
                    continue
                if word == "." and current in ["-", "%", "."]:
                    in_word = False
                    word += current
                    parsed.append(ls_word(word))
                    word = ""
                    continue
                if (word == "." or word == "-.") and current in digits:
                    in_word = False
                    in_float = True
                    word += current
                    continue
                if word == "-.":
                    parsed.append(ls_word("-"))
                    word = "."
                if in_b_string and current == "." and word == "":
                    word = current
                    continue
                if current == "%" and previous == "/":
                    word += current
                    continue
                if word == "|" and current == ">":
                    word += current
                    scope_depth += 1
                    parsed.append(ls_word(word))
                    word = ""
                    in_word = False
                    continue
                if previous == "<" and current == "|":
                    if word != "<":
                        word = word[:-1]
                        parsed.append(ls_word(word))
                    word = "<|"
                    parsed.append(ls_word(word))
                    word = ""
                    in_word = False
                    scope_depth -= 1
                    if scope_depth < 0:
                        err = "attempt to close unopened scope: <|"
                        raise ValueError
                    continue

                if current in delim or current.isspace() or current in [".", ":"]:  # '.' only at beginning, ":" only at end of varnames
                    in_word = False
                    if current == ":":
                        word += current
                    if in_b_string:
                        in_b_string = False     # save as block
                        word = ls_word(word)
                        returned = parse_commands(word, is_meta, debug, verbose)
                        word = ls_block(returned)
                        parsed.append(word)
                        word = ""
                        continue
                    if word in sugar:
                        pass
                    elif word in ["True", "true", "TRUE"]:
                        parsed.append(True)
                    elif word in ["False", "false", "FALSE"]:
                        parsed.append(False)
                    elif is_valid_word(word):
                        word = ls_word(word)
                        parsed.append(word)

                    else:
                        err = "not a valid word:"
                        raise ValueError

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
                    word = "-:"
                    parsed.append(ls_word(word))
                    word = ""
                    continue
                if current == ".":
                    word = "-."
                    in_word = True
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
                in_coll = True
                coll_depth += 1
            elif current == "}" and block_depth <= 0:
                err = "attempt to close unopened block: }"
                raise ValueError
            elif current == "]" and list_depth <= 0:
                err = "attempt to close unopened list: ]"
                raise ValueError
            elif current == ")" and coll_depth <= 0:
                err = "attempt to close unopened collection: )"
                raise ValueError
            elif current == "'":
                in_s_string = True
                word = ""
            elif current == '"':
                in_d_string = True
                word = ""
            elif current == "`":
                b_solo = True
                word = ""
            elif current == "-":
                minus = True
            elif current in "#%" and is_meta:
                in_var = True
                word = current
            elif current == "#" and not is_meta:
                in_comment = True
            elif current == "\\":
                word = "\\"
                in_word = True
            else:
                in_word = True
                word = current

        if in_d_string or in_s_string:
            err = "unclosed string: \"/'"
        if in_block:
            err = "unclosed block: {"
        if in_list:
            err = "unclosed list: ["
        if in_coll:
            err = "unclosed collection: ("
        if scope_depth != 0:
            err = "unclosed scope: |>"
        if in_num:
            parsed.append(int(word))
        if in_float:
            parsed.append(float(word))
        if in_word:
            parsed.append(word)
        if minus:
            parsed.append("-")
        if err != "":
            raise ValueError

        return(parsed)

    except(IndexError, ValueError):
        print(f"{Back.RED}Something went wrong during parsing!{Style.RESET_ALL}")
        print(f"{Fore.RED}Command parser terminated.{Style.RESET_ALL}")
        print(f"{Fore.RED}>>> {Fore.MAGENTA}{err}{Style.RESET_ALL}")
        consumed += " "
        prev_list = consumed.splitlines()
        count = len(prev_list)
        if current.isspace():
            current = ""
        prev = prev_list[-12:-1]
        fut_list = text.splitlines()
        fut = fut_list[:12]
        print(f"{Fore.GREEN}{Style.DIM}", end="")
        for item in prev:
            print(item)
        print(f"{Style.NORMAL}{Fore.MAGENTA}{prev_list[-1]}", end="")
        print(f"{Fore.WHITE}\n{Back.RED}Line {Style.BRIGHT}{count}{Style.RESET_ALL} {Fore.YELLOW}>>> {Style.RESET_ALL}{Fore.RED}{word}{Style.BRIGHT}{current}{Style.RESET_ALL}{Fore.YELLOW} <<<  ", end="")
        if err == "":
            err = "unknown:"
        print(f"{Fore.RED}Error: {Fore.YELLOW}{err}  {Fore.RED}{word}{Style.BRIGHT}{current}{Style.RESET_ALL}\n{Fore.CYAN}{Style.DIM}", end="")
        for item in fut:
            print(item)
        print(f"{Style.RESET_ALL}\n")
        partial = ls_slice(parsed, -12)
        print(f"{Fore.YELLOW}Last parsed elements: {Style.RESET_ALL}", end="")
        my_pretty_println(ls_block(partial), True)
        err = err.capitalize()
        err = err.rstrip(":")
        print(f"\n\n{Back.RED}{err}{Style.RESET_ALL}")
        quit()


def main(file_arg):
    output = deque([])
    raw = ""
    try:
        with open(file_arg, "r") as in_file:
            raw = in_file.read()
            in_file.close()
        output = parse_commands(raw)
        print("\n\nparsed output:", *output, "\n")
        print("parsed output:", output, "\n")
    except ValueError:
        print("Something went wrong during parsing")


if __name__ == '__main__':
    main(sys.argv[1])
