import sys, os
from ls_helpers import ls_word, ls_block, ls_list
from collections import deque
from colorama import Fore, Back, Style

#   from command_parser import parse_commands
#   Listack command parser.
#   {} = block/quotation/lambda function, stored as a list.  When applied, gets unpacked to the front of the future command queue.
#   [] = list, stored as a deque (double ended queue).  When applied, gets pushed onto the data stack.
#   () blocks are not checked.  You'll have to balance them yourself.
#   "N (" creates a new data stack and local variable scope, taking N items from the top of the previous stack, and also storing them in local variables A..N.
#   ")" pops the current data stack and local variable scope, moving the remaining items onto the stack below.
#   Local variables A..Z are automatically created and initialized to "" in the interpreter.
#   Global auxiliary stacks a..z are automatically created and initialized to [] in the interpreter.


delim = ",'`\"[]{}()\\-#%"      #   cannot use these characters (or whitespace) in variable names, except can begin with '.', end with ':'
digits = "0123456789"           #   the built in functions act weird with some unicode characters.
sugar = ["then", "else", "do"]

def parse_commands(line):
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
    in_comment = False
    minus = False
    line += "   "
    current = ""
    word = ""
    consumed = ""

    # print("Parsing:", line)

    try:
        while line:
            previous = current
            consumed = consumed + previous
            current = line[0]
            line = line[1:]

            if in_comment:
                if current in "\n\r":
                    in_comment = False
                continue

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

            if in_d_string:     # "string"
                if current == '"' and previous != "\\":
                    in_d_string = False
                    if not in_list and not in_block:
                        decoded_word = bytes(word, "utf-8").decode("unicode_escape") # python3 string decoder
                        parsed.append(decoded_word)
                        word = ""
                    else:
                        word += current
                else:
                    word += current
                continue

            if in_s_string:     # 'string'
                if current == "'" and previous != "\\":
                    in_s_string = False
                    if not in_list and not in_block:
                        decoded_word = bytes(word, "utf-8").decode("unicode_escape") # python3 string decoder
                        parsed.append(decoded_word)
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
                        returned = parse_commands(word)
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
                        returned = parse_commands(word)
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
                if current in delim or current.isspace() or current in [".", ":"]:  # '.' only at beginning, ":" only at end of varnames
                    in_word = False
                    if current == ":":
                        word += current
                    word = ls_word(word)
                    if in_b_string:
                        in_b_string = False     # save as block
                        returned = parse_commands(word)
                        word = ls_block(returned)
                    else:
                        word = ls_word(word)
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
            elif current == "`":
                b_solo = True
                word = ""
            elif current == "-":
                minus = True
            elif current == "#":
                in_comment = True
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
            print(f"in: {Fore.CYAN}{original}{Style.RESET_ALL}")
            print("Command parser terminated.")
            raise ValueError

        # print("finished parsing:", parsed)

        return(parsed)

    except(IndexError, ValueError):
        print("Something went wrong during parsing.")
        print(f">>>{Fore.GREEN}{consumed}{Fore.YELLOW}{word}{Fore.RED}{current}{Fore.CYAN}{line}{Style.RESET_ALL}<<<")
        print("Original:", original)
        print(*parsed)
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
