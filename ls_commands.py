# Listack v0.38.2
# ls_commands.py
# executes most of the languages functions
# Copyright McChuck, 2023
# May be freely redistributed and used with attribution under GPL3.


import sys, os, copy
import math
from ls_parser import parse_commands
from ls_helpers import *
from collections import deque
from colorama import Fore, Back, Style
import pickle

try:
    from getch import getch, getche         # Linux
except ImportError:
    from msvcrt import getch, getche        # Windows

class ls_commands:
    global lowers, uppers, digits
    lowers = "abcdefghijklmnopqrstuvwxyz"   #   global stacks
    uppers = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"   #   local variables
    digits = "0123456789"

    def __init__(self, commands_in):
        self.past = deque([])
        self.future = ls_block(commands_in)
        self.side = {}              # auxiliary stacks A..Z initialized to deque([])
        self.past_data = []         # place to store old versions of past
        self.global_funcs = {}       # functions stored as table: name, value
        self.local_vars = [{}]      # stack of tables, a..z initialized to ""
        self.current = ""
        self.breaking = False
        self.continuing = False
        self.exiting = False
        self.past_begin = False
        for char in uppers:
            self.local_vars[0][char] = ""
        for char in lowers:
            self.side[char] = deque([])

#####################   Basic functions

    def push_past(self, item):
        push_right(self.past, item)

    def push_fut(self, item):
        push_left(self.future, item)

    def pop_past(self):
        return(pop_right(self.past))

    def pop_fut(self):
        return(pop_left(self.future))

    def ext_past(self, item):
        extend_right(self.past, item)

    def ext_fut(self, item):
        extend_left(self.future, item)

    def ins_fut_1(self, item):
        push_n(self.future, 1, item)

    def ins_fut_2(self, item):
        push_n(self.future, 2, item)

    def ins_fut_3(self, item):
        push_n(self.future, 3, item)

    def ins_fut_4(self, item):
        push_n(self.future, 4, item)

    def swap_fut(self):
        self.future[0], self.future[1] = self.future[1], self.future[0]

    def swap_fut_past(self):
        a = pop_fut()
        b = pop_past()
        push_fut(b)
        push_past(a)

######################  Meta processing

    def scan_meta(self, left, right, pattern):
        no_copy = False
        output = deque([])
        for index, instr in enumerate(pattern):
            unpack = False
            if type(instr) is ls_block:
                new_instr = ls_block(self.scan_meta(left, right, instr))
            elif type(instr) is ls_list:
                new_instr = ls_list(self.scan_meta(left, right, instr))
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
            if unpack and is_seq(new_instr):
                extend_right(output, new_instr)
            else:
                push_right(output, new_instr)
        return(output)


    def do_meta(self, raw_left, raw_right, raw_pattern):      # This is what you import
        num_l = raw_pattern[0]
        num_r = raw_pattern[1]
        pattern = raw_pattern[2]
        left = ls_slice(raw_left, -num_l)
        right = ls_slice(raw_right, num_r)
        pat = parse_commands(pattern, 0, True)
        new_pat = self.scan_meta(left, right, pat)
        new_pat=ls_block(new_pat)
        return new_pat


    def meta_fut(self, pattern):
        new = self.do_meta(self.past, self.future, pattern)
        self.ext_fut(new)

    def meta_past(self, pattern):
        new = self.do_meta(self.past, self.future, pattern)
        self.ext_past(new)

    def do_load(self, verbose=False):
        self.check_stack("load", 1)
        self.check_types("load", "str")
        filename = self.pop_past()
        breakout = filename.rsplit(".")
        ext = breakout[-1]
        if ext not in ["ls", "lsp"]:
            ext = "ls"
            filename += ".ls"
        if os.path.isfile(filename):
            if ext == "ls":
                if verbose:
                    print("Loading", filename)
                with open(filename, "r") as in_file:
                    rawin = in_file.read()
                    in_file.close()
                if verbose:
                    print("Parsing", filename)
                parsedin = parse_commands(rawin, 0, False)
                parsedin.append(ls_word("end"))
                altname = filename + "p"
                if not os.path.isfile(altname):
                    if verbose:
                        print("Creating", altname)
                    with open(altname, "wb") as out_file:
                        pickle.dump(parsedin, out_file)
                        out_file.close()
            elif ext == "lsp":
                if verbose:
                    print("Loading", filename)
                with open(filename, "rb") as in_file:
                    parsedin = pickle.load(in_file)
                    in_file.close()
            if verbose:
                print("Running", filename)
            self.ext_fut(parsedin)
        else:
            print(f"\n{Fore.RED}Error: {Fore.MAGENTA}LOAD {Fore.RED}{filename} {Fore.YELLOW} file not found{Style.RESET_ALL}", flush = True)
            raise ValueError
    def do_load_pre(self):
        self.ins_fut_1(ls_word(".load"))


####################### Error handling

    def check_stack(self, word, depth):
        command = word.upper()
        if len(self.past) < depth:
            print(f"\n{Fore.RED}Error: {Fore.MAGENTA}{command}{Fore.YELLOW}: insufficient arguments (stack is too low){Style.RESET_ALL}", flush = True)
            print(f"Expected: {Fore.YELLOW}{depth}{Style.RESET_ALL}, found: {Fore.RED}{len(self.past)}{Style.RESET_ALL}", flush=True)
            raise ValueError

    def check_types(self, word, type_list):
        command = word.upper()
        if type(type_list) is not list:
            type_list = [type_list]
        how_many = len(type_list)
        where = -how_many
        for i, what in enumerate(type_list):
            if type(what) is list:
                try:
                    for index, item in enumerate(what):
                        what[index] = item.upper()
                except:
                    print("Failed list of types checking: ", what, flush=True)
                    raise
                correct_list = what
            else:
                correct = what.upper()
                if correct == "ANY":
                    where += 1
                    continue
                if correct == "SEQ":
                    correct_list = ["BLOCK", "LIST", "COLL"]
                elif correct == "BLOCK":
                    correct_list = ["BLOCK", "COLL"]
                elif correct == "LIST":
                    correct_list = ["LIST", "COLL"]
                elif correct == "ALPHA":
                    correct_list = ["WORD", "STR"]
                elif correct == "ITEM":
                    correct_list = ["WORD", "STR", "INT", "FLOAT", "BOOL"]
                elif correct == "NUM":
                    correct_list = ["INT", "FLOAT"]
                elif correct == "ALPHANUM":
                    correct_list = ["WORD", "STR", "INT", "FLOAT"]
                elif correct == "ALPHAINT":
                    correct_list = ["WORD", "STR", "INT"]
                elif correct == "SAME":
                    if i == 0:
                        print(f"\n{Fore.RED}Error:  {Fore.MAGENTA}{command}{Fore.YELLOW}  incorrect type argument: {Fore.RED}SAME {Fore.YELLOW} cannot be the first type!{Style.RESET_ALL}", flush = True)
                        raise ValueError
                    prev_type = ls_type(self.past[where-1])
                    correct = prev_type
                    if correct == "BLOCK":
                        correct_list = ["BLOCK", "COLL"]
                    elif correct == "LIST":
                        correct_list = ["LIST", "COLL"]
                    elif correct == "COLL":
                        correct_list = ["COLL", "BLOCK", "LIST"]
                    else:
                        correct_list = [prev_type]
                elif correct == "SIMILAR":
                    if i == 0:
                        print(f"\n{Fore.RED}Error:  {Fore.MAGENTA}{command}{Fore.YELLOW}  incorrect type argument: {Fore.RED}SAME {Fore.YELLOW} cannot be the first type!{Style.RESET_ALL}", flush = True)
                        raise ValueError
                    prev_type = ls_type(self.past[where-1])
                    if prev_type in ["INT", "FLOAT"]:
                        correct_list = ["INT", "FLOAT"]
                        correct = "NUM"
                    elif prev_type in ["LIST", "BLOCK", "COLL"]:
                        correct_list = ["LIST", "BLOCK", "COLL"]
                        correct = "SEQ"
                    elif prev_type in ["STR", "WORD"]:
                        correct_list = ["STR", "WORD"]
                        correct = "ALPHA"
                    else:
                        correct = prev_type
                        correct_list = [prev_type]
                elif type(correct) is not list:
                    correct_list = [correct]
            target = self.past[where]
            target_type = ls_type(target)
            if target_type not in correct_list:
                print(f"\n{Fore.RED}Error: {Fore.MAGENTA}{command}{Fore.YELLOW}  incorrect argument.  Expected {Fore.GREEN}{correct}{Fore.YELLOW}, found {Fore.RED}{target_type}{Style.RESET_ALL}: ", end="", flush=True)
                my_println(target, True)
                raise ValueError
            where += 1


####################### Listack commands

    def do_move_to_stack(self):   #  \ item --> pushes item to past without execution or evaluation
        item = self.pop_fut()
        self.push_past(item)

    def do_make_block(self):    # ` word --> converts word into a block and pushes it onto the stack
        item = self.pop_fut()   # this word should normally never be executed, as it is handled by the parser
        if is_seq(item):
            item = ls_block(item)
        else:
            item = ls_block([item])
        ls.push_past(item)

    def do_exec(self):     # {item}.exec // [item].exec // item.exec   -> item placed at front of command queue
        self.check_stack("exec", 1)
        item = self.pop_past()
        if is_string(item) and not (" " in item or "\t" in item or "\n" in item or "\r" in item):     # coerce string to command word, making sure it is a single word.
            new = ls_word(item)
            if item.count(".") == 1:
                try:
                    new = float(item)
                except ValueError:
                    pass
            elif item.count(".") == 0:
                try:
                    new = int(item)
                except ValueError:
                    pass
            elif len(item) == 0:    # empty string does nothing
                new = ls_block([])
            item = new
        if is_seq(item):
            if is_empty(item):      # empty sequence does nothing
                pass
            else:
                self.ext_fut(item)  # list, block, execute it either way
        else:
            self.push_fut(item)

    def do_exec_pre(self):    # prefix      exec: [item] -> item
        self.ins_fut_1(ls_word(".exec"))

    def do_choose(self):   #   postfix      condition true false .choose
        self.check_stack("choose", 3)
        bad = self.pop_past()
        good = self.pop_past()
        cond = self.pop_past()
        if not is_block(cond):
            if make_bool(cond):
                self.push_past(good)
            else:
                self.push_past(bad)
        else:
            if is_empty(cond):
                self.push_past(bad)
            else:
                self.push_fut(ls_word(".choose"))
                self.push_fut(bad)
                self.push_fut(good)
                self.ext_fut(cond)

    def do_choose_pre(self):    # prefix     choose: cond true false -> true/false
        self.ins_fut_3(ls_word(".choose"))

    def do_choose_in(self):    # infix      cond choose true false -> true/false
        self.ins_fut_2(ls_word(".choose"))

    def do_if(self):   #   postfix        a {condition} {true} {false} .if --> {a true} // {false}
        self.check_stack(".if", 3)
        bad = self.pop_past()
        good = self.pop_past()
        cond = self.pop_past()
        if is_block(cond):
            if is_empty(cond):
                self.ext_fut(bad)
            else:
                self.push_fut(ls_word(".if"))
                if not is_seq(bad):
                    bad = ls_block([bad])
                self.push_fut(bad)
                if not is_seq(good):
                    good = ls_block([good])
                self.push_fut(good)
                self.ext_fut(cond)
        else:
            if make_bool(cond):
                self.ext_fut(good)
            else:
                self.ext_fut(bad)


    def do_if_pre(self):    # prefix      a if: {condition} {true} {false} --> {a true} // {false}
        self.ins_fut_1(ls_word("if"))
        if is_block(self.future[0]):
            cond = self.pop_fut()
            self.ext_fut(cond)

    def do_if_in(self):     #   infix     a {condition} if {true} {false} --> {a true} // {false}
        self.check_stack("if", 1)
        cond = self.pop_past()
        if is_block(cond):
            self.push_fut(ls_word("if"))
            self.ext_fut(cond)
        else:
            if make_bool(cond):
                del self.future[1]
            else:
                del self.future[0]
            body = self.pop_fut()
            self.ext_fut(body)

    def do_if_star(self):   #   postfix        a {condition} {true} {false} .if* --> {a true} // {false}
        self.check_stack(".if*", 4)
        self.meta_past([4, 0, "#a #b {#a %c} #d"])  # 'cont' and 'break' require '_begin_loop_' and '_end_loop_'
        self.do_if()

    def do_if_star_pre(self):    # prefix      a if*: {condition} {true} {false} --> {a true} // {false}
        self.check_stack("if*:", 1)
        a = self.past[-1]
        self.meta_fut([1, 2, "%A if {#a %B}"])
        self.push_past(a)

    def do_if_star_in(self):     #   infix     a {condition} if* {true} {false} --> {a true} // {false}
        self.check_stack("if*", 2)
        a = self.past[-2]
        cond = self.past[-1]
        if is_block(cond) or is_coll(cond):
            self.meta_fut([2, 1, "%b if {#a %A}"])
            self.push_past(a)
        else:
            self.meta_fut([2, 1, "if {#a %A}"])
            self.push_past(a)
            self.push_past(cond)

    def do_iff(self):   # cond {true} .iff      if and only if, no else clause
        self.check_stack(".iff", 2)
        good = self.pop_past()
        cond = self.pop_past()
        if is_block(cond) or is_coll(cond):
            if is_empty(cond):
                pass
            else:
                self.push_fut(ls_word(".iff"))
                if not is_seq(good):
                    good = ls_block([good])
                self.push_fut(good)
                self.ext_fut(cond)
        else:
            if make_bool(cond):
                self.ext_fut(good)
            else:
                pass    # there is no else

    def do_iff_pre(self):   # a iff: cond {true}
        self.ins_fut_1(ls_word("iff"))
        if is_block(self.future[0]) or is_coll(self.future[0]):
            cond = self.pop_fut()
            self.ext_fut(cond)

    def do_iff_in(self):    # a cond iff {true}
        self.check_stack("iff", 1)
        cond = self.pop_past()
        if is_block(cond) or is_coll(cond):
            self.push_fut(ls_word("iff"))
            self.ext_fut(cond)
        else:
            body = self.pop_fut()
            if make_bool(cond):
                self.ext_fut(body)
            else:
                pass    # there is no else

    def do_iff_star(self):   # a cond {true} .iff*   --> {a true} // nop   if and only if, no else clause
        self.check_stack(".iff*", 3)
        self.meta_past([3, 0, "#a #b {#a %c}"])
        self.do_iff()

    def do_iff_star_pre(self):   # a iff*: cond {true}  --> {a true} // nop
        self.check_stack("iff*:", 1)
        a = self.past[-1]
        self.meta_fut([1, 2, "%A iff {#a %B}"])
        self.push_past(a)

    def do_iff_star_in(self):    # a cond iff* {true}  --> {a true} // nop
        self.check_stack("iff*", 2)
        a = self.past[-2]
        cond = self.past[-1]
        if is_block(cond):
            self.meta_fut([2, 1, "%b iff {#a %A}"])
            self.push_past(a)
        else:
            self.meta_fut([2, 1, "iff {#a %A}"])
            self.push_past(a)
            self.push_past(cond)

    def do_starship(self):      # number {do if negative} {do if zero} {do if positive} .<=>
        self.check_stack("<=>", 4)
        self.check_types("<=>", ["num", "seq", "seq", "seq"])
        do_pos = self.pop_past()
        do_zero = self.pop_past()
        do_neg = self.pop_past()
        num = self.pop_past()
        if num < 0:
            self.ext_fut(do_neg)
        elif num == 0:
            self.ext_fut(do_zero)
        else:
            self.ext_fut(do_pos)

    def do_starship_pre(self):  # <=>: number {do if negative} {do if zero} {do if positive}
        self.ins_fut_1(ls_word("<=>"))

    def do_starship_in(self):   # number <=> {do if negative} {do if zero} {do if positive}
        self.check_stack("<=>", 1)
        self.check_types("<=>", "num")
        num = self.pop_past()
        neg = self.pop_fut()
        zero = self.pop_fut()
        pos = self.pop_fut()
        if num < 0:
            self.ext_fut(neg)
        elif num == 0:
            self.ext_fut(zero)
        else:
            self.ext_fut(pos)

# then
# else

    def do_while(self):    # postfix WHILE      condition body .while
        self.check_stack("while", 2)
        self.check_types("while", [["block", "coll"], "block"])
        if self.future[0] == "_end_loop_":
            self.pop_fut()
        self.meta_fut([2, 0, "%a iff {%b _begin_loop_ #a #b .while _end_loop_}"])
        # 'cont' and 'break' require '_begin_loop_' and '_end_loop_'

    def do_while_pre(self):  # prefix WHILE:       while: condition body
        self.meta_fut([0, 2, "%A iff {%B _begin_loop_ #A #B .while _end_loop_}"])

    def do_while_in(self):  # infix WHILE         condition while body
        self.check_stack("while", 1)
        self.check_types("while", [["block", "coll"]])
        self.meta_fut([1, 1, "%a iff {%A _begin_loop_ #a #A .while _end_loop_}"])

    def do_until(self):     # {body} {condition} .do_until
		self.check_stack("until", 2)
        self.check_types("until", ["block", "block"])
        self.meta_fut([2, 0, "%a _begin_loop_ #b \.not .append #a .while _end_loop_"])

    def do_until_pre(self):     # until: {body} {condition}
        self.ins_fut_2(ls_word(".until"))

    def do_until_in(self):      # {body} until {condition}
        self.ins_fut_1(ls_word(".until"))

# break
# cont
# exit
# halt
# _begin_loop_
# _end_loop_
# end
# nop

    def do_def(self, verbose):  #   {words} "name" .def     creates global function "name" with instruction set {words}.
        self.check_stack("def", 2)
        self.check_types("def", ["str"])
        func_name = self.pop_past()
        if func_name in self.local_vars[-1].keys():
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}DEF: local variable {Fore.CYAN}{func_name}{Fore.YELLOW} already exists{Style.RESET_ALL}", flush = True)
            raise ValueError
        func_body = self.pop_past()
        if verbose and func_name in self.global_funcs.keys():
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}DEF: global function {Fore.CYAN}{func_name}{Fore.YELLOW} already exists as: {Fore.CYAN}", end="")
            my_print(global_funcs[func_name])
            print(f"{Fore.YELLOW}Overwriting with {Fore.CYAN}", end="")
            my_print(func_body)
            print(f"{Style.RESET_ALL}", flush=True)
        new_func = {func_name: func_body}
        self.global_funcs.update(new_func)

    def do_def_pre(self): # def: "name" {words}         NOTE reversed order
        self.swap_fut()
        self.ins_fut_2(ls_word(".def"))

    def do_def_in(self): # {words} def "name"
        self.ins_fut_1(ls_word(".def"))

    def do_init(self, verbose):  # value "name" .init     creates a local variable "name" with an initial value from the stack
        self.check_stack("init", 2)
        self.check_types("init", ["str"])
        var_name = self.pop_past()
        value = self.pop_past()
        if var_name in self.global_funcs.keys():
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}INIT global function {Fore.CYAN}{var_name}{Fore.YELLOW} already exists{Style.RESET_ALL}", flush = True)
            raise ValueError
        if verbose and var_name in self.local_vars[-1].keys():
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}INIT local variable {Fore.CYAN}{var_name}{Fore.YELLOW} already exists, overwriting with {Fore.CYAN}{value}{Style.RESET_ALL}", flush = True)
        new_var = {var_name: value}
        self.local_vars[-1].update(new_var)

    def do_init_pre(self): # init: "name" value             NOTE reversed order.
        self.swap_fut()
        self.ins_fut_2(ls_word(".init"))

    def do_init_in(self): # value init "name"
        self.ins_fut_1(ls_word(".init"))

    def do_call(self):  # "name" .call       Put reference at front of command queue.  If a block or function, it will be expanded.
        self.check_stack("call", 2)
        self.check_types("call", ["alpha"])
        var_name = self.pop_past()
        item = ""
        glob_func = False
        if var_name in self.local_vars[-1].keys():  # works on local variables
            item = self.local_vars[-1][var_name]
        elif var_name in self.global_funcs.keys():  # and also on global functions
            item = self.global_funcs[var_name]
            glob_func = True
        else:
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}CALLed variable {Fore.CYAN}{var_name}{Fore.YELLOW} does not exist{Style.RESET_ALL}", flush = True)
            raise ValueError
        if is_block(item):
            self.ext_fut(item)
        else:
            self.push_fut(item)

    def do_call_pre(self):  #   call: "name"
        self.ins_fut_1(ls_word(".call"))

    def do_set(self):   # value "name" .set     assigns value to existing variable      SYNONYM: also $varname
        self.check_stack("set", 2)
        self.check_types("set", ["alpha"])
        var_name = self.pop_past()
        value = self.pop_past()
        if var_name in self.local_vars[-1].keys():
            self.local_vars[-1][var_name] = value
        elif var_name in self.global_funcs.keys():
            self.global_funcs[var_name] = value
        else:
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}SET {Fore.CYAN}{var_name}{Fore.YELLOW} not found{Style.RESET_ALL}", flush = True)
            raise ValueError

    def do_set_pre(self):  # set: "name" value                              NOTE reversed order
        self.swap_fut()
        self.ins_fut_2(ls_word(".set"))

    def do_set_in(self):    # value set "name"
        self.ins_fut_1(ls_word(".set"))

    def do_get(self):   # "name" .get -> value          SYNONYM: @varname
        self.check_stack("get", 1)
        self.check_types("get", ["alpha"])
        var_name = self.pop_past()
        if var_name in self.local_vars[-1].keys():
            value = self.local_vars[-1][var_name]
        elif var_name in self.global_funcs.keys():
            value = self.global_funcs[var_name]
        else:
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}GET {Fore.CYAN}{var_name}{Fore.YELLOW} not found{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(value)

    def do_get_pre(self):   # get: "name"
        self.ins_fut_1(ls_word(".get"))

    def do_free(self):  # "varname" .free    delete a variable
        self.check_stack("free", 1)
        self.check_types("free", ["alpha"])
        if var_name in self.local_vars[-1].keys():
            self.local_vars[-1].pop(var_name)
        elif var_name in self.global_funcs.keys():
            self.global_funcs.pop(var_name)
        else:
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}FREE: {Fore.CYAN}{var_name}{Fore.YELLOW} not found{Style.RESET_ALL}", flush = True)
            raise ValueError

    def do_free_pre(self):  # free: "varname"
        self.ins_fut_1(ls_word(".free"))

    def do_each(self):   # seq block .each        applies block to each item in seq     uses side stack e
        self.check_stack("each", 2)
        if not is_seq(self.past[-1]):
            self.past[-1] = ls_block([self.past[-1]])
        if not is_seq(self.past[-2]):
            self.past[-2] = ls_list([self.past[-2]])
        self.meta_fut([1, 0, "push_e {pop_e .len 0 .> dup .not iff {swap drop}} {.first* swap push_e %a} .while _end_loop_"])

    def do_each_pre(self):   # each: block seq
        # self.swap_fut()
        self.ins_fut_2(ls_word(".each"))

    def do_each_in(self):   # seq each block
        self.ins_fut_1(ls_word(".each"))

    def do_apply_each(self):   # [seq] [list of blocks] .apply_each        applies each block to each item in seq     uses side stacks d, e
        self.check_stack("each", 2)
        if not is_seq(self.past[-1]):
            self.past[-1] = ls_list([self.past[-1]])
        if not is_seq(self.past[-2]):
            self.past[-2] = ls_list([self.past[-2]])
        self.meta_fut([0, 0, "push_d dup push_e push_e {pop_d .len 0 .> dup .not iff {swap drop}}{.first* swap push_d pop_e swap .each} .while _end_loop_"])

    def do_apply_each_pre(self):   # apply_each: block seq
        # self.swap_fut()
        self.ins_fut_2(ls_word(".apply_each"))

    def do_apply_each_in(self):   # seq apply_each block
        self.ins_fut_1(ls_word(".apply_each"))

    def do_map(self):   # seq block .map         like each, but collects values into a list   uses EACH
        self.check_stack("map", 2)
        self.check_types("map", ["seq", "block"])
        self.meta_fut([0, 0, "2 |> .each enlist_all <|"])

    def do_map_pre(self):   # map: block list
        self.ins_fut_2(ls_word(".map"))

    def do_map_in(self):    # list map block
        self.ins_fut_1(ls_word(".map"))

    def do_times(self):     # num {block} .times        uses side stack n
        self.check_stack("times", 2)
        self.check_types("times", ["int", "block"])
        self.meta_fut([1, 0, "+ 1 push_n {pop_n - 1 dup push_n 0 .>} #a .while _end_loop_ pop_n drop"])

    def do_times_in(self):
        self.ins_fut_1(ls_word(".times"))

    def do_times_pre(self):
        self.ins_fut_2(ls_word(".times"))

    def do_times_n(self):     # num {block} .times*        uses side stack n    makes counter available
        self.check_stack("times*", 2)
        self.check_types("times*", ["int", "block"])
        self.meta_fut([1, 0, "+ 1 push_n {pop_n - 1 dup push_n 0 .>} \ copy_n #a .concat .while _end_loop_ pop_n drop"])

    def do_times_n_in(self):
        self.ins_fut_1(ls_word(".times*"))

    def do_times_n_pre(self):
        self.ins_fut_2(ls_word(".times*"))

    def do_for(self):   # [{initial state}{incremental change}{exit condition}] {body} .for     uses side stack f
        self.check_stack("for", 2)
        self.check_types("for", ["seq", "block"])
        if len(self.past[-2]) != 3:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FOR{Fore.YELLOW}: argument list error {Fore.MAGENTA}", end="")
            my_print(a)
            print(f" incorrect length, expected 3{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.meta_fut([2, 0, "%a0 push_f {copy_f %a2 .not} {%b pop_f %a1 push_f} .while _end_loop_ pop_f drop"])  # [init inc cond] body --> init {cond} while {body inc}

    def do_for_pre(self):   # for: [{initial state}{incremental change}{exit condition}] {body}
        self.ins_fut_2(ls_word(".for"))

    def do_for_in(self):    # [{initial state}{incremental change}{exit condition}] for {body}
        self.ins_fut_1(ls_word(".for"))

    def do_for_f(self):   # [{initial state}{incremental change}{exit condition}] {body} .for*     uses side stack f    makes counter available
        self.check_stack("for*", 2)
        self.check_types("for*", ["seq", "block"])
        if len(self.past[-2]) != 3:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FOR{Fore.YELLOW}: argument list error {Fore.MAGENTA}", end="")
            my_print(a)
            print(f" incorrect length, expected 3{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.meta_fut([2, 0, "%a0 push_f {copy_f %a2 .not} {copy_f %b pop_f %a1 push_f} .while _end_loop_ pop_f drop"])  # [init inc cond] body --> init {cond} while {body inc}

    def do_for_f_pre(self):   # for: [{initial state}{incremental change}{exit condition}] {body}
        self.ins_fut_2(ls_word(".for*"))

    def do_for_f_in(self):    # [{initial state}{incremental change}{exit condition}] for {body}
        self.ins_fut_1(ls_word(".for*"))

    def do_filter(self):    # [list] {condition} .filter --> [filtered list]        uses side stacks f, g, e
        self.check_stack("filter", 2)
        self.check_types("filter", ["seq", "block"])
        self.meta_fut([0, 0, """over swap .map swap push_g [] push_h
        {if {pop_g .first* swap push_g pop_h swap .concat push_h}{pop_g .first* drop push_g}} .each
        pop_g drop pop_h"""])

    def do_filter_pre(self):    # filter: [list] {condition}
        self.ins_fut_2(ls_word(".filter"))

    def do_filter_in(self):    # [list] filter {condition}
        self.ins_fut_1(ls_word(".filter"))

    def do_reduce(self): # [list] {action} .reduce --> action progressively applied to list        *** action assumed to be postfix ***    uses side stacks e, r, s
        self.check_stack("reduce", 2)
        self.check_types("reduce", ["seq", "block"])
        if len(self.past[-2]) == 0 or len(self.past[-1]) == 0:
            self.pop_past()
        else:
            self.meta_fut([0, 0, "push_r .first* push_s {pop_s swap copy_r .exec push_s} .each pop_r drop pop_s"])

    def do_reduce_pre(self):     # total: [list] {action}
        self.ins_fut_2(ls_word(".reduce"))

    def do_reduce_in(self):     # [list] total {action}
        self.ins_fut_1(ls_word(".reduce"))

    def do_case(self):  # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .case        uses side stacks o, p
        self.check_stack("case", 2)
        self.check_types("case", ["any", "seq"])
        self.meta_fut([0, 0, """[{True}{drop}] .append push_p push_o {pop_p .len 0 .>}
        { .first* swap push_p copy_o swap .delist drop .type 'BLOCK' .~= { {} swap .append} .iff \\ break .append .iff}
        .while _end_loop_ pop_o drop pop_p drop"""])

    def do_case_pre(self):  # case: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_2(ls_word(".case"))

    def do_case_in(self):   # object case [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_1(ls_word(".case"))

    def do_case_star(self):  # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .case        uses side stacks o, p
        self.check_stack("case*", 2)
        self.check_types("case*", ["any", "seq"])
        self.meta_fut([0, 0, """[{True}{drop drop}] .append push_p dup push_o {pop_p .len 0 .>}
        { .first* swap push_p copy_o swap .delist drop .type 'BLOCK' .~= { {} swap .append} .iff \\ break .append .iff}
        .while _end_loop_ pop_o drop pop_p drop"""])

    def do_case_star_pre(self):  # case: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_2(ls_word(".case*"))

    def do_case_star_in(self):   # object case [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_1(ls_word(".case*"))

    def do_match(self):  # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .match       uses side stacks o, p
        self.check_stack("match", 2)
        # types can be anything, can be used as dictionary lookup
        self.meta_fut([0, 0, """[{dup}{nop}] .append push_p push_o {pop_p .len 0 .>}
        { .first* swap push_p copy_o swap .delist drop .type 'BLOCK' .~= { {} swap .append} .iff
            \\ break .append swap .type 'BLOCK' .~= { {} swap .append} .iff \\ .== .append swap .iff}
        .while _end_loop_ pop_o drop pop_p drop"""])

    def do_match_pre(self):  # match: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_2(ls_word(".match"))

    def do_match_in(self):   # object match [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_1(ls_word(".match"))

    def do_match_star(self):  # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .match*       uses side stacks o, p
        self.check_stack("match*", 2)
        # types can be anything, can be used as dictionary lookup
        self.meta_fut([0, 0, """[{dup}{nop}] .append push_p dup push_o {pop_p .len 0 .>}
        { .first* swap push_p copy_o swap .delist drop .type 'BLOCK' .~= { {} swap .append} .iff
            \\ break .append swap .type 'BLOCK' .~= { {} swap .append} .iff \\ .== .append swap .iff}
        .while _end_loop_ pop_o drop pop_p drop"""])

    def do_match_star_pre(self):  # match*: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_2(ls_word(".match*"))

    def do_match_star_in(self):   # object match* [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_1(ls_word(".match*"))

# of

    def do_type(self):    # .type    leaves type of item on TOS, preserved
        self.check_stack("type", 1)
        item = self.past[-1]
        result = ls_type(item)
        self.push_past(result)

    def do_type_pre(self):    # type:
        self.ins_fut_1(ls_word(".type"))

    def do_len(self):   #   seq .len     pushes the length of seq on the stack, preserving seq
        self.check_stack("len", 1)
        self.check_types("len", ["seq"])
        seq = peek_n(self.past, -1)
        if not is_seq(seq):
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}LEN {Fore.CYAN}{seq}{Fore.YELLOW}: not a sequence{Style.RESET_ALL}", flush = True)
            length = -1
        else:
            length = len(seq)
        self.push_past(length)

    def do_len_pre(self):    # len: seq --> seq n
        self.ins_fut_1(ls_word(".len"))

    def do_first(self):  # [a b c] .first ->  a    extracts the leftmost item in seq, pushes it on the stack
        self.check_stack("first", 1)
        self.check_types("first", ["seq"])
        seq = self.pop_past()
        length = len(seq)
        if length == 0:
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}FIRST {Fore.CYAN}{seq}{Fore.YELLOW}: empty{Style.RESET_ALL}", flush = True)
            self.push_past(False)
        else:
            item = pop_left(seq)
            self.push_past(item)

    def do_first_pre(self):  # first: [a b c] --> a
        self.ins_fut_1(ls_word(".first"))

    def do_last(self):  # [a b c] .last --> c    extracts the rightmost item in seq, pushes it on the stack
        self.check_stack("last", 1)
        self.check_types("last", ["seq"])
        seq = self.pop_past()
        length = len(seq)
        if length == 0:
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}LAST {Fore.CYAN}{seq}{Fore.YELLOW}: empty{Style.RESET_ALL}", flush = True)
            self.push_past(False)
        else:
            item = pop_right(seq)
            self.push_past(item)

    def do_last_pre(self):     # last: [a b c] -->  c
        self.ins_fut_1(ls_word(".last"))

    def do_first_star(self):  # [a b c] .first* -> [b c] a    extracts the leftmost item in seq, pushes it on the stack, preserving what's left of seq
        self.check_stack("first*", 1)
        self.check_types("first*", ["seq"])
        seq = peek_n(self.past, -1)
        length = len(seq)
        if length == 0:
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}FIRST* {Fore.CYAN}{seq}{Fore.YELLOW}: empty{Style.RESET_ALL}", flush = True)
            self.push_past(False)
        else:
            item = pop_left(seq)
            self.push_past(item)

    def do_first_star_pre(self):  # first*: [a b c] --> [b c] a
        self.ins_fut_1(ls_word(".first*"))

    def do_last_star(self):  # [a b c] .last* --> [a b] c    extracts the rightmost item in seq, pushes it on the stack, preserving what's left of seq
        self.check_stack("last*", 1)
        self.check_types("last*", ["seq"])
        seq = peek_n(self.past, -1)
        length = len(seq)
        if length == 0:
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}LAST* {Fore.CYAN}{seq}{Fore.YELLOW}: empty{Style.RESET_ALL}", flush = True)
            self.push_past(False)
        else:
            item = pop_right(seq)
            self.push_past(item)

    def do_last_star_pre(self):     # last: [a b c] --> [a b] c
        self.ins_fut_1(ls_word(".last*"))

    def do_but_first(self):     # [1 2 3] .but_first --> [2 3]
        self.check_stack("but_first", 1)
        self.check_types("but_first", "seq")
        self.push_fut(ls_word("drop"))
        self.push_fut(ls_word(".first*"))

    def do_but_first_pre(self):
        self.ins_fut_1(ls_word(".but_first"))

    def do_but_last(self):     # [1 2 3] .but_last --> [1 2]
        self.check_stack("but_last", 1)
        self.check_types("but_last", "seq")
        self.push_fut(ls_word("drop"))
        self.push_fut(ls_word(".last*"))

    def do_but_last_pre(self):
        self.ins_fut_1(ls_word(".but_last"))

    def do_delist(self):   # [a b c] .delist -> a b c 3
        self.check_stack("delist", 1)
        self.check_types("delist", "seq")
        seq = self.pop_past()
        if not is_seq(seq):
            self.push_past(seq)
            self.push_past(0)
        else:
            how_many = depth(seq)
            self.ext_past(seq)
            self.push_past(how_many)

    def do_delist_pre(self):    #   delist: [a b c] --> a b c 3
        self.ins_fut_1(ls_word(".delist"))

    def do_enlist(self):    #   a b c d e 2 enlist --> a b c [d e]
        self.check_stack("enlist", 1)
        self.check_types("enlist", ["int"])
        how_many = self.pop_past()
        self.check_stack("enlist", how_many)
        new = ls_slice(self.past, -how_many)
        new = ls_list(new)
        self.push_past(new)

    def do_enlist_pre(self):    #   a b c d e enlist: 2 --> a b c [d e]
        self.ins_fut_1(ls_word(".enlist"))

    def do_enlist_all(self):
        new_list = copy_of(self.past)
        new_list = ls_list(new_list)
        self.do_clear()
        self.push_past(new_list)

    def do_nth(self):  # [list] num .nth --> [list] list[num]       preserves [list]
        self.check_stack("nth", 2)
        self.check_types("nth", ["seq", "int"])
        where = self.pop_past()
        what = self.past[-1]
        if not is_int(where):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}NTH expected an integer, not {Fore.CYAN}{where}{Style.RESET_ALL}", flush = True)
            raise ValueError
        if not is_seq(what):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}NTH expected a sequence, not {Fore.CYAN}{what}{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = copy_of(what[where])
        self.push_past(item)

    def do_nth_pre(self):  # nth: [list] num
        self.ins_fut_2(ls_word(".nth"))

    def do_nth_in(self):   # [list] nth num
        self.ins_fut_1(ls_word(".nth"))

    def do_insert(self):    # [list] item place .insert  --> [list with item inserted]   place 0 = front, -1 = back
        self.check_stack("insert", 3)
        self.check_types("insert", ["seq", "any", "int"])
        where = self.pop_past()
        what = self.pop_past()
        target = self.past[-1]
        if not is_int(where):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}INSERT expected an integer, not {Fore.CYAN}{where}{Style.RESET_ALL}", flush = True)
            raise ValueError
        if not is_seq(target):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}INSERT expected a sequence, not {Fore.CYAN}{target}{Style.RESET_ALL}", flush = True)
            raise ValueError
        target.insert(where, what)

    def do_insert_pre(self):    # insert: [list] item place
        self.ins_fut_3(ls_word(".insert"))

    def do_insert_in(self):    # [list] insert item place
        self.ins_fut_2(ls_word(".insert"))

    def do_delete(self):    # [list] where .delete --> [list without item]      first = 0, last = -1
        self.check_stack("delete", 2)
        self.check_types("delete", ["seq", "int"])
        where = self.pop_past()
        target = self.past[-1]
        if not is_int(where):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}DELETE expected an integer, not {Fore.CYAN}{where}{Style.RESET_ALL}", flush = True)
            raise ValueError
        if not is_seq(target):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}DELETE expected a sequence, not {Fore.CYAN}{target}{Style.RESET_ALL}", flush = True)
            raise ValueError
        pop_n(target, where)

    def do_delete_pre(self):    # delete: [list] where
        self.ins_fut_1(ls_word(".delete"))

# Stack functions

    def do_open_scope(self):   #   N |>   -> new local variables, new data stack, N items from old stack moved to new, locals A..N initialized with data
        self.check_stack("(", 1)
        self.check_types("(", [["int", "bool"]])
        how_many = self.pop_past()
        preserved = False
        temp_data = deque([])
        if is_bool(how_many):
            if how_many:
                push_stack(self.past_data, copy_of(self.past))
                preserved = True
            how_many = depth(self.past)
        self.check_stack("(", how_many)
        push_stack(self.local_vars, {})
        for char in uppers:     # create new local variables A..Z
            self.local_vars[-1][char] = ""
        if how_many < 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}{how_many} {Fore.RED}( {Fore.YELLOW}: must be zero or positive {Style.RESET_ALL}", flush = True)
            raise ValueError
        if how_many > 0:
            top = min(how_many, 26)
            for i in range(how_many):        # copy n items off past data stack
                temp1 = self.pop_past()
                push_left(temp_data, temp1)
                if i < 26:                  # there are only 26 letters
                    letter = chr(top - (i+1) + ord('A'))
                    self.local_vars[-1][letter] = temp1    #   set local data A..N
        if not preserved:
            push_stack(self.past_data, copy_of(self.past))
        self.past.clear()
        if how_many > 0:
            self.ext_past(temp_data)

    def do_close_scope(self):  #   <| -> delete local variables, restore old stack, push remaining items onto old stack
        if len(self.past_data) > 0:
            temp_data = copy_of(self.past)
            self.past.clear()
            self.past = pop_stack(self.past_data)
            if not is_empty(temp_data):
                self.ext_past(temp_data)
            self.local_vars[-1].clear()
            pop_stack(self.local_vars)
        else:       # This shouldn't be possible
            print(f"\n{Fore.RED}Warning: {Fore.CYAN}){Fore.YELLOW} without previous {Fore.CYAN}({Style.RESET_ALL}", flush = True)
            print(f"\n{Fore.MAGENTA}Clearing data stack and local variables instead{Style.RESET_ALL}", flush = True)
            self.past.clear()
            self.local_vars[0].clear()
            for char in uppers:     # create new local variables A..Z
                self.local_vars[0][char] = ""

    def do_clear(self): #   clear   clears the data stack, leaves local variables alone
        self.past.clear()

    def do_push_(self, which):   # move top of stack to top of side stack a..z
        self.check_stack("push_", 1)
        if which not in lowers:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}PUSH_{Fore.MAGENTA}{which} {Fore.YELLOW}: must be upper case letter{Style.RESET_ALL}", flush = True)
            raise ValueError
        if is_empty(self.past):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}PUSH_{Fore.MAGENTA}{which} {Fore.YELLOW}: data stack is empty{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = self.pop_past()
        push_right(self.side[which], item)

    def do_pop_(self, which): # move top of a side stack a..z to top of data stack
        if which not in lowers:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}POP_{Fore.MAGENTA}{which} {Fore.YELLOW}: must be lower case letter{Style.RESET_ALL}", flush = True)
            raise ValueError
        if is_empty(self.side[which]):
            print(f"\n{Fore.RED}Warning: {Fore.CYAN}POP_{Fore.MAGENTA}{which} {Fore.YELLOW}: side stack is empty, pushing {Fore.CYAN}False{Style.RESET_ALL}", flush = True)
            self.push_past(False)
        item = pop_right(self.side[which])
        self.push_past(item)

    def do_copy_(self, which): # copy top of a side stack a..z to top of data stack
        if which not in lowers:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}COPY_{Fore.MAGENTA}{which} {Fore.YELLOW}: must be lower case letter{Style.RESET_ALL}", flush = True)
            raise ValueError
        if is_empty(self.side[which]):
            print(f"\n{Fore.RED}Warning: {Fore.CYAN}COPY_{Fore.MAGENTA}{which} {Fore.YELLOW}: side stack is empty, pushing {Fore.CYAN}False{Style.RESET_ALL}", flush = True)
            self.push_past(False)
        item = self.side[which][-1]
        self.push_past(item)

    def do_depth_(self, which): # depth of side stack a..z
        if which not in lowers:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}DEPTH_{Fore.MAGENTA}{which} {Fore.YELLOW}: must be lower case letter{Style.RESET_ALL}", flush = True)
            raise ValueError
        how_deep = depth(self.side[which])
        self.push_past(how_deep)

    def do_drop(self):  # a b c -> a b
        self.check_stack("drop", 1)
        self.pop_past()

    def do_swap(self):  # a b c -> a c b
        self.check_stack("swap", 2)
        self.past[-1], self.past[-2] = self.past[-2], self.past[-1]

    def do_roll(self):  # a b c -> b c a
        self.check_stack("roll", 3)
        item = pop_n(self.past, -3)
        self.push_past(item)

    def do_over(self):  # a b c -> a b c b
        self.check_stack("over", 2)
        item = peek_n(self.past, -2)
        self.push_past(item)

    def do_reverse(self):   # a b c d e f -> f e d c b a
        self.past.reverse()

    def do_dup(self):   # a b c --> a b c c
        self.check_stack("dup", 1)
        item = peek_n(self.past, -1)
        self.push_past(item)

    def do_rot_r(self): # a b c d e f 2 .rot_r -> e f a b c d      rotate stack to the right n places
        self.check_stack("rot_r", 2)
        self.check_types("rot_r", ["int"])
        how_many = self.pop_past()
        if not is_int(how_many):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}ROT_R expected a number, not {Fore.CYAN}{how_many}{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.past.rotate(how_many)

    def do_rot_r_pre(self):     # a b c d e f rot_r: 2 --> e f a b c d
        self.ins_fut_1(ls_word(".rot_r"))

    def do_rot_l(self):  # a b c d e f 2 .rot_l -> c d e f a b
        self.check_stack("rot_l", 2)
        self.check_types("rot_l", ["int"])
        how_many = self.pop_past()
        if not is_int(how_many):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}ROT_L expected a number, not {Fore.CYAN}{how_many}{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.past.rotate(-how_many)

    def do_rot_l_pre(self):     # a b c d e f rot_l: 2 -> c d e f a b
        self.ins_fut_1(ls_word(".rot_l"))

    def do_depth(self):     # depth of data stack
        how_deep = len(self.past)
        self.push_past(how_deep)

    def do_restore_stack(self):   #   restores an old copy of the data stack, overwriting current version.  Ignores local variables.
        if len(self.past_data) == 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}RESTORE{Fore.YELLOW}: nothing to restore{Style.RESET_ALL}", flush = True)
            raise ValueError
        new = pop_right(self.past_data)
        self.past.clear()
        self.past = new

    def do_save_stack(self):  #   saves a copy of the data stack.  Ignores local variables
        new = copy_of(self.past)
        push_right(self.past_data, new)

# Math

    def do_plus(self):  # a b .+ --> a+b
        self.check_stack("+", 2)
        self.check_types("+", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        c = a + b
        c = round(c, 15)
        self.push_past(c)

    def do_plus_pre(self):  # +: a b
        self.ins_fut_2(ls_word(".+"))

    def do_plus_in(self):   # a + b
        self.ins_fut_1(ls_word(".+"))

    def do_minus(self):     # a b .- --> a-b
        self.check_stack("-", 2)
        self.check_types("-", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        c = a - b
        c = round(c, 15)
        self.push_past(c)

    def do_minus_pre(self):  # -: a b
        self.ins_fut_2(ls_word(".-"))

    def do_minus_in(self):   # a - b
        self.ins_fut_1(ls_word(".-"))

    def do_multiply(self):  # a b .* --> a*b
        self.check_stack("*", 2)
        self.check_types("*", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        ans = a * b
        ans = round(ans, 15)
        self.push_past(ans)

    def do_multiply_pre(self):  # *: a b
        self.ins_fut_2(ls_word(".*"))

    def do_multiply_in(self):   # a * b
        self.ins_fut_1(ls_word(".*"))

    def do_divide(self):    # a b ./ --> a/b
        self.check_stack("/", 2)
        self.check_types("/", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        if b == 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}{a} / {b} {Fore.YELLOW} divide by zero {Style.RESET_ALL}", flush = True)
            raise ValueError
        ans = a/b
        round(ans, 15)
        self.push_past(ans)

    def do_divide_pre(self):  # /: a b
        self.ins_fut_2(ls_word("./"))

    def do_divide_in(self):   # a / b
        self.ins_fut_1(ls_word("./"))

    def do_int_divide(self):    # a b .// --> a//b      integer division
        self.check_stack("//", 2)
        self.check_types("//", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        if b == 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}{a} // {b} {Fore.YELLOW} divide by zero {Style.RESET_ALL}", flush = True)
            raise ValueError
        sign = a * b
        if sign > 0:
            ans = math.floor(a / b)
        elif sign == 0:
            ans = 0
        else:
            ans = math.ceil(a / b)
        # ans = a // b
        # if ans < 0 and (ans != a/b):
        #     ans += 1
        # ans = round(ans, 15)
        self.push_past(int(ans))

    def do_int_divide_pre(self):  # //: a b --> a//b
        self.ins_fut_2(ls_word(".//"))

    def do_int_divide_in(self):   # a // b --> a//b
        self.ins_fut_1(ls_word(".//"))

    def do_modulus(self):       # a b .% --> a%b    modulus (remainder)
        self.check_stack("%", 2)
        self.check_types("%", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        if b == 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}{a} % {b} {Fore.YELLOW} divide by zero {Style.RESET_ALL}", flush = True)
            raise ValueError
        frac = a % b
        if a * b < 0 and frac != 0:
            frac = frac - b
        frac = round(frac, 15)
        if is_int(a) and is_int(b):
            frac = int(frac)
        self.push_past(frac)

    def do_modulus_pre(self):  # %: a b
        self.ins_fut_2(ls_word(".%"))

    def do_modulus_in(self):   # a % b
        self.ins_fut_1(ls_word(".%"))

    def do_div_mod(self):   # a b ./% --> a//b a%b   division with remainder
        self.check_stack("/%", 2)
        self.check_types("/%", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        if b == 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}{a} /% {b} {Fore.YELLOW} divide by zero {Style.RESET_ALL}", flush = True)
            raise ValueError
        sign = a * b
        if sign > 0:
            ans = math.floor(a / b)
        elif sign == 0:
            ans = 0
        else:
            ans = math.ceil(a / b)
        # ans = a // b
        # if ans < 0 and ans != a / b:
        #     ans += 1
        # ans = round(ans, 15)
        self.push_past(int(ans))
        frac = a % b
        frac = round(frac, 15)
        if a * b < 0 and frac != 0:
            frac = frac - b
        if is_int(a) and is_int(b):
            frac = int(frac)
        self.push_past(frac)


    def do_div_mod_pre(self):  # /%: a b --> a//b a%b
        self.ins_fut_2(ls_word("./%"))

    def do_div_mod_in(self):   # a /% b --> a//b a%b
        self.ins_fut_1(ls_word("./%"))

    def do_power(self):       # a b .power --> a to power of b
        self.check_stack("power", 2)
        self.check_types("power", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        c = a**b
        c = round(c, 15)
        self.push_past(c)

    def do_power_pre(self):  # power: a b
        self.ins_fut_2(ls_word(".power"))

    def do_power_in(self):   # a power b
        self.ins_fut_1(ls_word(".power"))

    def do_root(self):  # a b .root --> b'th root of a  (a to power of 1/b)
        self.check_stack("root", 2)
        self.check_types("root", ["num", "num"])
        b = self.pop_past()
        a = self.pop_past()
        if b == 0:
            c = 1
        elif b == 1:
            c = a
        elif b == 2:
            c = math.sqrt(a)
        elif b == 3:
            c = math.cbrt(a)
        elif b == -1:
            c = 1/a
        else:
            b = 1/b
            c = math.pow(a, b)
        c = round(c, 15)
        self.push_past(c)

    def do_root_pre(self):  # root: a b
        self.ins_fut_2(ls_word(".root"))

    def do_root_in(self):   # a root b
        self.ins_fut_1(ls_word(".root"))

    def do_ln(self):    # a .ln --> natural log of a
        self.check_stack("ln", 1)
        self.check_types("ln", ["num"])
        a = self.pop_past()
        c = math.log(a)
        c = round(c, 15)
        self.push_past(c)

    def do_ln_pre(self):    # ln: a
        self.ins_fut_1(ls_word(".ln"))

    def do_exp(self):   # a .exp --> e raise dto the a'th power
        self.check_stack("exp", 1)
        self.check_types("exp", ["num"])
        a = self.pop_past()
        c = math.exp(a)
        c = round(c, 15)
        self.push_past(c)

    def do_exp_pre(self):   # exp: a
        self.ins_fut_1(ls_word(".exp"))

    def do_log(self):   # a b .log --> logarithm of a with base b
        self.check_stack("log", 2)
        self.check_types("log", ["num"])
        b = self.pop_past()
        a = self.pop_past()
        c = math.log(a, b)
        c = round(c, 15)
        self.push_past(c)

    def do_log_pre(self):   # log: a b
        self.ins_fut_2(ls_word(".log"))

    def do_log_in(self):    # a log b
        self.ins_fut_1(ls_word(".log"))

    def do_sqr(self):   # a .sqr --> a**2
        self.check_stack("sqr", 1)
        self.check_types("sqr", ["num"])
        a = self.pop_past()
        c = a ** 2
        c = round(c, 15)
        self.push_past(c)

    def do_sqr_pre(self):   # sqr: a
        self.ins_fut_1(ls_word(".sqr"))

    def do_sqrt(self):   # a .sqrt --> square root of a
        self.check_stack("sqrt", 1)
        self.check_types("sqrt", ["num"])
        a = self.pop_past()
        c = math.sqrt(a)
        c = round(c, 15)
        self.push_past(c)

    def do_sqrt_pre(self):   # sqrt: a
        self.ins_fut_1(ls_word(".sqrt"))

    def do_sin(self):   # a .sin        sin of a in radians
        self.check_stack("sin", 1)
        self.check_types("sin", ["num"])
        a = self.pop_past()
        c = math.sin(a)
        c = round(c, 15)
        self.push_past(c)

    def do_sin_pre(self):   # sin: a
        self.ins_fut_1(ls_word(".sin"))

    def do_cos(self):   # a .cos --> cos of a in radians
        self.check_stack("cos", 1)
        self.check_types("cos", ["num"])
        a = self.pop_past()
        c = math.cos(a)
        c = round(c, 15)
        self.push_past(c)

    def do_cos_pre(self):   # cos: a
        self.ins_fut_1(ls_word(".cos"))

    def do_tan(self):   # a .tan --> tan of a in radians
        self.check_stack("tan", 1)
        self.check_types("tan", ["num"])
        a = self.pop_past()
        c = math.tan(a)
        c = round(c, 15)
        self.push_past(c)

    def do_tan_pre(self):   # tan: a
        self.ins_fut_1(ls_word(".tan"))

    def do_deg_rad(self):   # a .deg>rad --> convert degrees to radians
        self.check_stack("deg>rad", 1)
        self.check_types("deg>rad", ["num"])
        a = self.pop_past()
        c = math.radians(a)
        c = round(c, 15)
        self.push_past(c)

    def do_deg_rad_pre(self):   # deg>rad: a
        self.ins_fut_1(ls_word(".deg>rad"))

    def do_rad_deg(self):   # a .rad>deg --> convert radians to degrees
        self.check_stack("rad>deg", 1)
        self.check_types("rad>deg", ["num"])
        a = self.pop_past()
        c = math.degrees(a)
        c = round(c, 15)
        self.push_past(c)

    def do_rad_deg_pre(self):   # rad>deg: a
        self.ins_fut_1(ls_word(".rad>deg"))

    def do_asin(self):  # a .asin --> arcsin of a in radians
        self.check_stack("asin", 1)
        self.check_types("asin", ["num"])
        a = self.pop_past()
        c = math.asin(a)
        c = round(c, 15)
        self.push_past(c)

    def do_asin_pre(self):   # asin: a
        self.ins_fut_1(ls_word(".asin"))

    def do_acos(self):   # a .acos --> arccos of a in radians
        self.check_stack("acos", 1)
        self.check_types("acos", ["num"])
        a = self.pop_past()
        c = math.acos(a)
        c = round(c, 15)
        self.push_past(c)

    def do_acos_pre(self):   # acos: a
        self.ins_fut_1(ls_word(".acos"))

    def do_atan(self):   # a .atan --> arctan of a in radians
        self.check_stack("atan", 1)
        self.check_types("atan", ["num"])
        a = self.pop_past()
        c = math.atan(a)
        c = round(c, 15)
        self.push_past(c)

    def do_atan_pre(self):   # atan: a
        self.ins_fut_1(ls_word(".atan"))


# Boolean logic

    def do_make_bool(self):
        self.check_stack("make_bool", 1)
        item = self.pop_past()
        self.push_past(make_bool(item))

    def do_make_bool_pre(self):
        self.ins_fut_1(ls_word(".make_bool"))

    def do_less(self):  # a b .<
        self.check_stack("<", 2)
        self.check_types("<", ["alphanum", "similar"])
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a < b)

    def do_less_pre(self):  #   <: a b
        self.ins_fut_2(ls_word(".<"))

    def do_less_in(self):   # a < b
        self.ins_fut_1(ls_word(".<"))

    def do_greater(self):   # a b .>
        self.check_stack(">", 2)
        self.check_types(">", ["alphanum", "similar"])
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a > b)

    def do_greater_pre(self):  #   >: a b
        self.ins_fut_2(ls_word(".>"))

    def do_greater_in(self):   # a > b
        self.ins_fut_1(ls_word(".>"))

    def do_equal(self):     # a b .=
        self.check_stack("=", 2)    # This seems excessive, but proved necessary to get around some of Python's quirks
        b = self.pop_past()
        a = self.pop_past()
        if is_bool(a) and is_bool(b):
            self.push_past(a == b)
        elif is_number(a) and is_number(b):
            self.push_past(a == b)
        elif is_alpha(a) and is_alpha(b):
            self.push_past(a == b)
        elif is_seq(a) and is_seq(b):
            self.push_past(a == b)
        elif is_bool(a):            # 0 = False, you're the main culprit here
            c = make_bool(b)
            self.push_past( a == c)
        elif is_bool(b):
            c = make_bool(a)
            self.push_past(b == c)
        elif type(a) != type(b):
            self.push_past(False)
        else:
            self.push_past(a == b)

    def do_equal_pre(self):  #   =: a b
        self.ins_fut_2(ls_word(".="))

    def do_equal_in(self):   # a = b
        self.ins_fut_1(ls_word(".="))

    def do_equalt(self):     # a b .=
        self.check_stack("==", 2)
        b = self.pop_past()
        a = self.pop_past()
        if type(a) is type(b):
            self.push_past(a == b)
        else:
            self.push_past(False)

    def do_equalt_pre(self):  #   =: a b
        self.ins_fut_2(ls_word(".=="))

    def do_equalt_in(self):   # a = b
        self.ins_fut_1(ls_word(".=="))

    def do_net(self):   # a b .~==      Strictly not equal to
        self.check_stack("~==", 2)
        b = self.pop_past()
        a = self.pop_past()
        if type(a) == type(b):
            self.push_past(a != b)
        else:
            self.push_past(True)

    def do_net_pre(self):  #   =: a b
        self.ins_fut_2(ls_word(".~=="))

    def do_net_in(self):   # a = b
        self.ins_fut_1(ls_word(".~=="))

    def do_le(self):        #   a b .<=
        self.check_stack("<=", 2)
        self.check_types("<=", ["alphanum", "similar"])
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a <= b)

    def do_le_pre(self):  #   <=: a b
        self.ins_fut_2(ls_word(".<="))

    def do_le_in(self):   # a .<= b
        self.ins_fut_1(ls_word(".<="))

    def do_ge(self):        # a b .>=
        self.check_stack(">=", 2)
        self.check_types(">=", ["alphanum", "similar"])
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a >= b)

    def do_ge_pre(self):  #   >=: a b
        self.ins_fut_2(ls_word(".>="))

    def do_ge_in(self):   # a >= b
        self.ins_fut_1(ls_word(".>="))

    def do_ne(self):        # a b .~=   not equals
        self.check_stack("~=", 2)
        b = self.pop_past()
        a = self.pop_past()
        if is_bool(a) and is_bool(b):
            self.push_past(a != b)
        elif is_number(a) and is_number(b):
            self.push_past(a != b)
        elif is_alpha(a) and is_alpha(b):
            self.push_past(a != b)
        elif is_seq(a) and is_seq(b):
            self.push_past(a != b)
        elif is_bool(a):
            c = make_bool(b)
            self.push_past( a != c)
        elif is_bool(b):
            c = make_bool(a)
            self.push_past(b != c)
        elif type(a) != type(b):
            self.push_past(True)
        else:
            self.push_past(a != b)
        # b = self.pop_past()
        # a = self.pop_past()
        # self.push_past(a != b)

    def do_ne_pre(self):  #   ~=: a b
        self.ins_fut_2(ls_word(".~="))

    def do_ne_in(self):   # a ~= b
        self.ins_fut_1(ls_word(".~="))

    def do_not(self):   # Boolean .not T --> F
        self.check_stack("not", 1)
        a = self.pop_past()
        a = make_bool(a)
        self.push_past(not a)

    def do_not_pre(self):  #   not: F --> T
        self.ins_fut_1(ls_word(".not"))

    def do_and(self):        # a b .and
        self.check_stack("and", 2)
        b = self.pop_past()
        a = self.pop_past()
        a = make_bool(a)
        b = make_bool(b)
        self.push_past(a and b)

    def do_and_pre(self):  #   and: a b
        self.ins_fut_2(ls_word(".and"))

    def do_and_in(self):   # a and b
        self.ins_fut_1(ls_word(".and"))

    def do_or(self):        # a b .or
        self.check_stack("or", 2)
        b = self.pop_past()
        a = self.pop_past()
        a = make_bool(a)
        b = make_bool(b)
        self.push_past(a or b)

    def do_or_pre(self):  #   or: a b
        self.ins_fut_2(ls_word(".or"))

    def do_or_in(self):   # a or b
        self.ins_fut_1(ls_word(".or"))

    def do_xor(self):        # a b .xor
        self.check_stack("xor", 2)
        b = self.pop_past()
        a = self.pop_past()
        a = make_bool(a)
        b = make_bool(b)
        self.push_past(a != b)

    def do_xor_pre(self):  #   or: a b
        self.ins_fut_2(ls_word(".xor"))

    def do_xor_in(self):   # a or b
        self.ins_fut_1(ls_word(".xor"))

    def do_bit_not(self):       # bitwise not
        self.check_stack("bit_not", 1)
        self.check_types("bit_not", "int")
        a = self.pop_past()
        c = ~a
        self.push_past(c)

    def do_bit_not_pre(self):
        self.ins_fut_2(ls_word(".bit_not"))

    def do_bit_not_in(self):
        self.ins_fut_1(ls_word(".bit_not"))

    def do_bit_and(self):       # bitwise and
        self.check_stack("bit_and", 2)
        self.check_types("bit_and", ["int", "int"])
        b = self.pop_past()
        a = self.pop_past()
        c = a & b
        self.push_past(c)

    def do_bit_and_pre(self):
        self.ins_fut_2(ls_word(".bit_and"))

    def do_bit_and_in(self):
        self.ins_fut_1(ls_word(".bit_and"))

    def do_bit_or(self):       # bitwise and
        self.check_stack("bit_or", 2)
        self.check_types("bit_or", ["int", "int"])
        b = self.pop_past()
        a = self.pop_past()
        c = a | b
        self.push_past(c)

    def do_bit_or_pre(self):
        self.ins_fut_2(ls_word(".bit_or"))

    def do_bit_or_in(self):
        self.ins_fut_1(ls_word(".bit_or"))

    def do_bit_xor(self):       # bitwise and
        self.check_stack("bit_xor", 2)
        self.check_types("bit_xor", ["int", "int"])
        b = self.pop_past()
        a = self.pop_past()
        c = a ^ b
        self.push_past(c)

    def do_bit_xor_pre(self):
        self.ins_fut_2(ls_word(".bit_xor"))

    def do_bit_xor_in(self):
        self.ins_fut_1(ls_word(".bit_xor"))

    def do_bit_r(self):       # bitwise right shift     int how_many .bit_r
        self.check_stack("bit_r", 2)
        self.check_types("bit_r", ["int", "int"])
        how_many = self.pop_past()
        a = self.pop_past()
        if how_many >= 0:
            c = a >> how_many
        else:
            c = a << how_many
        self.push_past(c)

    def do_bit_r_pre(self):
        self.ins_fut_2(ls_word(".bit_r"))

    def do_bit_r_in(self):
        self.ins_fut_1(ls_word(".bit_r"))

    def do_bit_l(self):       # bitwise left shift      int how_many .bit_l
        self.check_stack("bit_l", 2)
        self.check_types("bit_l", ["int", "int"])
        how_many = self.pop_past()
        a = self.pop_past()
        if how_many >= 0:
            c = a << how_many
        else:
            c = a >> how_many
        self.push_past(c)

    def do_bit_l_pre(self):
        self.ins_fut_2(ls_word(".bit_l"))

    def do_bit_l_in(self):
        self.ins_fut_1(ls_word(".bit_l"))



    def do_concat(self):        # [a] [b] .concat --> [a b]      concatenate two items/blocks/lists
        self.check_stack("concat", 2)
        b = self.pop_past()
        a = self.pop_past()
        if is_block(a) and is_seq(b):   #   {a}{b} --> {a b}
            c = a + ls_block(b)                   #   {a}[b] --> {a b}
            c = ls_block(c)
            self.push_past(c)
        elif is_list(a) and is_seq(b):  #   [a][b] --> [a b]
            c = a + ls_list(b)                   #   [a]{b} --> [a b]
            c = ls_list(c)
            self.push_past(c)
        elif is_block(a):               #   {a} 1 --> {a 1}
            c = a + ls_block([b])
            c = ls_block(c)
            self.push_past(c)
        elif is_list(a):                #   [a] 1 --> [a 1]
            c = a + ls_list([b])
            c = ls_list(c)
            self.push_past(c)
        elif is_block(b):               #   1 {b} --> {1 b}
            c = ls_block([a]) + b
            c = ls_block(c)
            self.push_past(c)
        elif is_list(b):             #   1 [b] --> [1 b]
            c = ls_list([a]) + b
            c = ls_list(c)
            self.push_past(c)
        else:                           #   1 2 --> [1 2]
            c = [a] + [b]
            c = ls_list(c)
            self.push_past(c)

    def do_concat_pre(self):    # concat: [a]{b} --> [a b]
        self.ins_fut_2(ls_word(".concat"))

    def do_concat_in(self):     # {a} concat [b] --> {a b}
        self.ins_fut_1(ls_word(".concat"))

    def do_print(self):
        self.check_stack("print", 1)
        item = self.pop_past()
        my_print(item, False)

    def do_print_pre(self):
        self.ins_fut_1(ls_word(".print"))

    def do_print_q(self):
        self.check_stack("print_quote", 1)
        item = self.pop_past()
        my_print(item, True)

    def do_print_q_pre(self):
        self.ins_fut_1(ls_word(".print_quote"))

    def do_println(self):
        self.check_stack("println", 1)
        item = self.pop_past()
        my_println(item, False)

    def do_println_pre(self):
        self.ins_fut_1(ls_word(".println"))

    def do_println_q(self):
        self.check_stack("println_quote", 1)
        item = self.pop_past()
        my_println(item, True)

    def do_println_q_pre(self):
        self.ins_fut_1(ls_word(".println_quote"))


    def do_emit(self):     # number .emit    print char version of int
        self.check_stack("emit", 1)
        self.check_types("emit", ["num"])
        item = self.pop_past()
        print(chr(item), end = "")

    def do_emit_pre(self):  # emit: number
        self.ins_fut_1(ls_word(".emit"))

    def do_dump(self):  # print stack, stack preserved
        my_pretty_println(self.past, True)

    def do_get_line(self):  # input a line from keyboard (stdin)
        line = input()
        self.push_past(line)

    def do_get_char(self):  # read a single keystroke
        line = getche()
        self.push_past(line)

    def do_get_char_silent(self):  # read a single key, no echo
        line = getch()
        self.push_past(line)

    def do_valid_number_q(self):   # string .valid_num? --> string True/False
        self.check_stack("valid_num?", 1)
        self.check_types("valid_num?", "alphanum")
        item = self.past[-1]
        self.push_past(is_valid_number(item))

    def do_valid_number_q_pre(self):
        self.ins_fut_1(ls_word(".valid_num?"))

    def do_swap_ff(self):
        self.swap_fut()

    def do_swap_fp(self):
        self.check_stack("swap_fp", 1)
        self.swap_fut_past()

    def do_ins_fut_0(self):
        self.check_stack("ins_f0", 1)
        item = self.pop_past()
        self.push_fut(item)

    def do_ins_fut_1(self):
        self.check_stack("ins_f1", 1)
        item = self.pop_past()
        self.ins_fut_1(item)

    def do_ins_fut_2(self):
        self.check_stack("ins_f2", 1)
        item = self.pop_past()
        self.ins_fut_2(item)

    def do_ins_fut_3(self):
        self.check_stack("ins_f3", 1)
        item = self.pop_past()
        self.ins_fut_3(item)

    def do_ins_fut_4(self):
        self.check_stack("ins_f4", 1)
        item = self.pop_past()
        self.ins_fut_4(item)

    def do_user_meta(self):  # [num_past, num_future, "pattern"] _meta_
        self.check_stack("_meta_", 1)
        self.check_types("_meta_", ["seq"])
        pattern = self.pop_past()
        new = self.do_meta(self.past, self.future, pattern)
        self.ext_fut(new)

    def do_err_msg(self):   # string .err_msg       returns a string to print in case of error
        self.check_stack("err_msg", 1)
        self.check_types("err_msg", ["alpha"])
        user_err = self.pop_past()
        return user_err

    def do_err_msg_pre(self):
        self.ins_fut_1(ls_word(".err_msg"))


    def do_str_to_list(self):
        self.check_stack("str>list", 1)
        self.check_types("str>list", ["str"])
        a = self.pop_past()
        b = []
        for c in a:
            b.append(c)
        self.push_past(ls_list(b))

    def do_str_to_list_pre(self):
        self.ins_fut_1(ls_word(".str>list"))

    def do_str_to_list_sp(self):
        self.check_stack("str>list_sp"), 1
        self.check_types("str>list_sp", ["str"])
        a = self.pop_past()
        b = a.split()
        self.push_past(ls_list(b))

    def do_str_to_list_sp_pre(self):
        self.ins_fut_1(ls_word(".str>list_sp"))

    def do_list_to_str(self):
        self.check_stack("list>str", 1)
        self.check_types("list>str", ["seq"])
        a = self.pop_past()
        b = "".join(a)
        self.push_past(b)

    def do_list_to_str_pre(self):
        self.ins_fut_1(ls_word(".list>str"))

    def do_list_to_str_sp(self):
        self.check_stack("list>str_sp", 1)
        self.check_types("list>str_sp", ["seq"])
        a = self.pop_past()
        b = " ".join(a)
        self.push_past(b)

    def do_list_to_str_sp_pre(self):
        self.ins_fut_1(ls_word(".list>str_sp"))

    def do_rev_list(self):  # reverse a sequence
        self.check_stack("rev", 1)
        self.check_types("rev", ["seq"])
        a = self.pop_past()
        a.reverse()
        self.push_past(a)

    def do_rev_list_pre(self):
        self.ins_fut_1(ls_word(".rev"))

    def do_in(self):    # item [list] .in --> Boolean
        self.check_stack("in", 2)
        self.check_types("in", ["seq"])
        where = self.pop_past()
        what = self.pop_past()
        answer = what in where
        self.push_past(answer)

    def do_in_pre(self):    # in: item [list]
        self.ins_fut_2(ls_word(".in"))

    def do_in_in(self):     # item in [list]
        self.ins_fut_1(ls_word(".in"))

    def do_str_word(self):
        self.check_stack("str>word", 1)
        self.check_types("str>word", ["alpha"])
        item = self.pop_past()
        item = item.strip()
        if item == "":
            item = "False"
        if is_valid_number(item):
            self.push_past(item)
            self.do_str_num()
        elif not is_valid_word(item):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>WORD{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(item, True)
            print(f"{Fore.YELLOW} is not a valid word{Style.RESET_ALL}", flush = True)
            raise ValueError
        else:
            if item in ["True", "true", "TRUE", "t", "T"]:
                self.push_past(True)
            elif item in ["False", "false", "FALSE", "f", "F"]:
                self.push_past(False)
            else:
                self.push_past(ls_word(item))

    def do_str_word_pre(self):
        self.ins_fut_1(ls_word(".str_word"))

    def do_word_str(self):
        self.check_stack("word>str", 1)
        self.check_types("word>str", ["alpha"])
        item = self.pop_past()
        self.push_past(str(item))

    def do_word_str_pre(self):
        self.ins_fut_1(ls_word(".word_str"))

    def do_list_to_block(self):
        self.check_stack("list>block", 1)
        self.check_types("list>block", ["seq"])
        a = self.pop_past()
        if not is_seq(a):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}LIST>BLOCK{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a, True)
            print(f"{Fore.YELLOW} is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = ls_block(a)
        self.push_past(b)

    def do_list_to_block_pre(self):
        self.ins_fut_1(ls_word(".list>block"))

    def do_block_to_list(self):
        self.check_stack("block>list", 1)
        self.check_types("block>list", ["seq"])
        a = self.pop_past()
        b = ls_list(a)
        self.push_past(b)

    def do_block_to_list_pre(self):
        self.ins_fut_1(ls_word(".block>list"))

    def do_append(self): #   [appendee] appender .append --> [appendee appender]
        self.check_stack("append", 2)
        self.check_types("append", ["seq", "any"])
        appender = self.pop_past()
        appendee = self.pop_past()
        push_right(appendee, appender)
        self.push_past(appendee)

    def do_append_pre(self):
        self.ins_fut_2(ls_word(".append"))

    def do_append_in(self):
        self.ins_fut_1(ls_word(".append"))

    def do_join(self): #   "String1" "String2" .join --> "String1String2"
        self.check_stack("join", 2)
        self.check_types("join", ["alpha", "alpha"])
        appender = self.pop_past()
        appendee = self.pop_past()
        appendee += appender
        self.push_past(str(appendee))

    def do_join_pre(self):
        self.ins_fut_2(ls_word(".join"))

    def do_join_in(self):
        self.ins_fut_1(ls_word(".join"))

    def do_str_num(self):   # "123" --> 123
        self.check_stack("str>num", 1)
        self.check_types("str>num", "alphanum")
        a = self.pop_past()
        num = convert_to_number(a)
        if num is not False:
            self.push_past(num)
        else:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>NUM{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a, True)
            print(f"{Fore.YELLOW} is not a valid number{Style.RESET_ALL}", flush = True)
            raise ValueError

    def do_str_num_pre(self):
        self.ins_fut_1(ls_word(".str>num"))

    def do_num_str(self):   # 123 --> "123"
        self.check_stack("num>str", 1)
        self.check_types("num>str", ["num"])
        a = self.pop_past()
        self.push_past(str(a))

    def do_num_str_pre(self):
        self.ins_fut_1(ls_word(".num>str"))

    def do_range(self): # start stop .range --> [start, next, next ... stop]
        self.check_stack("range", 2)
        self.check_types("range", ["alphaint", "same"])
        stop = self.pop_past()
        start = self.pop_past()
        result = ls_list([])
        if is_int(start) and is_int(stop):
            if start == stop:
                result = ls_list([stop])
            elif start < stop:
                for counter in range(start, stop+1):
                    push_right(result, counter)
            else:
                for counter in range(start, stop-1, -1):
                    push_right(result, counter)
            self.push_past(result)
        elif is_string(start) and is_string(stop) and len(start) == 1 and len(stop) == 1:
            n_start = ord(start)
            n_stop = ord(stop)
            if start == stop:
                result = ls_list([stop])
            elif n_start < n_stop:
                for counter in range(n_start, n_stop+1):
                    item = chr(counter)
                    push_right(result, item)
            else:
                for counter in range(n_start, n_stop-1, -1):
                    item = chr(counter)
                    push_right(result, item)
            self.push_past(result)
        else:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}RANGE{Fore.YELLOW}: cannot resolve range from {Fore.BLUE}{start}{Fore.YELLOW} to {Fore.CYAN}{stop}{Style.RESET_ALL}", flush = True)
            raise ValueError

    def do_range_pre(self):
        self.ins_fut_2(ls_word(".range"))

    def do_range_in(self):
        self.ins_fut_1(ls_word(".range"))

    def do_range_by(self): # start stop step .range_by --> [start, start+step, ... stop]
        self.check_stack("range_by", 3)
        self.check_types("range_by", ["num", "num", "num"])
        step = self.pop_past()
        stop = self.pop_past()
        start = self.pop_past()
        result = ls_list([])
        if is_float(start) or is_float(stop) or is_float(step):
            start = float(start)
            stop = float(stop)
            step = float(step)
        if start == stop:
            result = ls_list([stop])
        elif step == 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}RANGE_BY{Fore.YELLOW}: infinite loop attempted by step {Fore.MAGENTA}{step} {Style.RESET_ALL}", flush = True)
            raise ValueError
        elif (start < stop and step > 0):
            result = ls_list([])
            item = start
            while item <= stop:
                push_right(result, item)
                item += step
        elif (start > stop and step < 0):
            result = ls_list([])
            item = start
            while item >= stop:
                push_right(result, item)
                item += step
        else:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}RANGE_BY{Fore.YELLOW}: cannot resolve range from {Fore.BLUE}{start}{Fore.YELLOW} to {Fore.CYAN}{stop}{Fore.YELLOW} by {Fore.MAGENTA}{step} {Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(result)

    def do_range_by_pre(self):  # range_by: start stop step
        self.ins_fut_3(ls_word(".range_by"))

    def do_range_by_in(self):   # start stop range_by step
        self.ins_fut_1(ls_word(".range_by"))

    def do_sort(self):  # [4 2 3 1] .sort --> [1 2 3 4]     numbers or strings, not both
        self.check_stack("sort", 1)
        self.check_types("sort", ["seq"])
        target = self.pop_past()
        if not all_str_or_num(target):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}SORT{Fore.YELLOW}: list must contain all alpha or all numeric, not {Style.RESET_ALL}", flush = True, end = "")
            my_pretty_print(target, True)
            raise ValueError
        result = sorted(target)
        self.push_past(result)

    def do_sort_pre(self):  # sort: [1 5 3 4 2] --> [1 2 3 4 5]
        self.ins_fut_1(ls_word(".sort"))

    def do_zip(self):   #  [1 2 3] [a b c] .zip --> [[1 a] [2 b] [3 c]]
        self.check_stack("zip", 2)
        self.check_types("zip", ["seq", "seq"])
        b = self.pop_past()
        a = self.pop_past()
        c = ls_list(zip(a,b))
        for i, v in enumerate(c):
            c[i] = ls_list(c[i])
        self.push_past(c)

    def do_zip_pre(self):
        self.ins_fut_2(ls_word(".zip"))

    def do_zip_in(self):
        self.ins_fut_1(ls_word(".zip"))

    def do_unzip(self):
        self.check_stack("unzip", 1)
        self.check_types("unzip", ["seq"])
        a = self.pop_past()
        for count, item in enumerate(a):
            if not (is_seq(item) and len(item) == 2):
                a = ls_slice(a, count)
                break
        b, c = zip(*a)
        b = ls_list(b)
        c = ls_list(c)
        self.push_past(b)
        self.push_past(c)

    def do_unzip_pre(self):
        self.ins_fut_1(ls_word(".unzip"))

    def do_char_int(self):  # ' ' .char>int --> 32      "hello".char>int --> [...]
        self.check_stack("char>int", 1)
        self.check_types("char>int", "str")
        a = self.pop_past()
        if len(a) == 0:
            self.push_past(0)
        elif len(a) == 1:
            self.push_past(ord(a))
        else:
            resp = ls_list([])
            for c in a:
                push_right(resp, ord(c))
            self.push_past(resp)

    def do_char_int_pre(self):
        self.ins_fut_1(ls_word(".char>int"))

    def do_int_char(self):  # 32 .int>char --> ' '      [...].int>char --> "hello"
        self.check_stack("int>char", 1)
        self.check_types("char>int", [["INT", "LIST"]])
        a = self.pop_past()
        if is_list(a):
            if len(a) == 0:
                self.push_past("")
            else:
                resp = ""
                for i in a:
                    if is_int(i):
                        resp += chr(i)
                    else:
                        print(f"\n{Fore.RED}Error: {Fore.CYAN}INT>CHAR{Fore.YELLOW}: list must contain all alpha or all integers, not {Fore.RED}{i} {Style.RESET_ALL} ", flush = True)
                        my_pretty_print(a, True)
                        raise ValueError
                self.push_past(resp)
        else:
            self.push_past(chr(a))


    def do_int_char_pre(self):
        self.ins_fut_1(ls_word(".int>char"))
