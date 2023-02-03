# Listack v0.34
# ls_commands.py
# executes most of the languages functions
# Copyright McChuck, 2023
# May be freely redistributed and used with attribution under GPL3.


import sys, os, copy
import math
from ls_parser import parse_commands
from ls_meta import do_meta
from ls_helpers import *
from collections import deque
from colorama import Fore, Back, Style
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
        self.future = deque(commands_in)
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

    def swap_fut(self):
        self.future[0], self.future[1] = self.future[1], self.future[0]

    def swap_fut_past(self):
        a = pop_fut()
        b = pop_past()
        push_fut(b)
        push_past(a)

    def meta_fut(self, pattern):
        new = do_meta(self.past, self.future, pattern)
        self.ext_fut(new)

    def meta_past(self, pattern):
        new = do_meta(self.past, self.future, pattern)
        self.ext_past(new)

#######################

    def do_move_to_stack(self):   #  \ item --> pushes item to past without execution or evaluation
        item = self.pop_fut()
        self.push_past(item)

    def do_make_block(self):    # ` word --> converts word into a block and pushes it onto the do_move_to_stack
        item = self.pop_fut()   # this word should normally never be executed, as it is handled by the parser
        if is_seq(item):
            item = ls_block(item)
        else:
            item = ls_block([item])
        ls.push_past(item)

    def do_exec(self):     # {item}.exec // [item].exec // item.exec   -> item placed at front of command queue
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

    def do_open_scope(self):   #   N '('   -> new local variables, new data stack, N items from old stack moved to new, locals A..N initialized with data
        push_stack(self.local_vars, {})
        for char in uppers:     # create new local variables A..Z
            self.local_vars[-1][char] = ""
        how_many = self.pop_past()
        if not is_int(how_many):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}open_block({Fore.CYAN}{how_many}{Fore.YELLOW}): not an integer{Style.RESET_ALL}", flush = True)
            raise ValueError
        if how_many > depth(self.past):
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}open_block({Fore.CYAN}{how_many}{Fore.YELLOW}): data stack isn't that deep{Style.RESET_ALL}", flush = True)
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}adjusted to: {Fore.CYAN}{how_many}{Style.RESET_ALL}", flush = True)
            how_many = depth(self.past)
        temp_data = deque([])
        for i in range(how_many):        # copy n items off past data stack
            temp1 = self.pop_past()
            push_left(temp_data, temp1)
            letter = chr(how_many - (i+1) + ord('A'))
            self.local_vars[-1][letter] = temp1    #   set local data A..N
        push_stack(self.past_data, copy_of(self.past))
        self.past.clear()
        self.ext_past(temp_data)

    def do_close_scope(self):  #   ')' -> delete local variables, restore old stack, push remaining items onto old stack
        if len(self.past_data) > 0:
            temp_data = copy_of(self.past)
            self.past.clear()
            self.past = pop_stack(self.past_data)
            if len(temp_data) > 0:
                self.ext_past(temp_data)
            self.local_vars[-1].clear()
            pop_stack(self.local_vars)
        else:
            print(f"\n{Fore.RED}Warning: {Fore.CYAN}){Fore.YELLOW} without previous {Fore.CYAN}({Style.RESET_ALL}", flush = True)
            print(f"\n{Fore.MAGENTA}Clearing data stack and local variables instead{Style.RESET_ALL}", flush = True)
            self.past.clear()
            self.local_vars[0].clear()

    def do_clear(self): #   clear   clears the data stack, leaves local variables alone
        self.past.clear()

    def do_if(self):   #   postfix        a {condition} {true} {false} .if --> {a true} // {false}
        self.push_fut(ls_word(".exec"))
        self.push_fut(ls_word(".choose"))

    def do_if_pre(self):    # prefix      a if: {condition} {true} {false} --> {a true} // {false}
        self.ins_fut_3(ls_word(".if"))

    def do_if_in(self):     #   infix     a {condition} if {true} {false} --> {a true} // {false}
        self.ins_fut_2(ls_word(".if"))

    def do_if_star(self):   #   postfix        a {condition} {true} {false} .if* --> {a true} // {false}
        self.meta_past([4, 0, "#a #b {#a %c} #d"])  # 'cont' and 'break' require 'begin_while' and '.while'
        self.push_fut(ls_word(".if"))

    def do_if__star_pre(self):    # prefix      a if*: {condition} {true} {false} --> {a true} // {false}
        self.ins_fut_3(ls_word(".if*"))

    def do_if_star_in(self):     #   infix     a {condition} if* {true} {false} --> {a true} // {false}
        self.ins_fut_2(ls_word(".if*"))

    def do_iff(self):   # a cond {true} .iff      if and only if, no else clause
        self.push_past(ls_block([ls_word("nop")]))
        self.push_fut(ls_word(".exec"))
        self.push_fut(ls_word(".choose"))

    def do_iff_pre(self):   # a iff: cond {true}
        self.ins_fut_2(ls_word(".iff"))

    def do_iff_in(self):    # a cond iff {true}
        self.ins_fut_1(ls_word(".iff"))

    def do_iff_star(self):   # a cond {true} .iff*   --> {a true} // nop   if and only if, no else clause
        self.meta_past([3, 0, "#a #b {#a %c} {nop}"])
        self.push_fut(ls_word(".if"))

    def do_iff_star_pre(self):   # a iff*: cond {true}  --> {a true} // nop
        self.ins_fut_2(ls_word(".iff*"))

    def do_iff_star_in(self):    # a cond iff* {true}  --> {a true} // nop
        self.ins_fut_1(ls_word(".iff*"))

# then
# else

    def do_while(self):    # postfix WHILE      condition body .while
        self.meta_fut([2, 0, "%a {%b begin_while #a #b .while} {nop} .if"])  # 'cont' and 'break' require 'begin_while' and '.while'

    def do_while_pre(self):  # prefix WHILE:       while: condition body
        self.ins_fut_2(ls_word(".while"))

    def do_while_in(self):  # infix WHILE         condition while body
        self.ins_fut_1(ls_word(".while"))

# break
# cont
# exit
# halt
# begin_while
# end
# nop

    def do_def(self):  #   {words} "name" .def     creates function "name" with instruction set {words}.
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}DEF{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        func_name = self.pop_past()
        if not is_string(func_name):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}DEF: {Fore.CYAN}{func_name}{Fore.YELLOW} is not a valid name{Style.RESET_ALL}", flush = True)
            raise ValueError
        if func_name in self.local_vars[-1].keys():
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}DEF: local variable {Fore.CYAN}{func_name}{Fore.YELLOW} already exists{Style.RESET_ALL}", flush = True)
            raise ValueError
        func_body = self.pop_past()
        if func_name in self.global_funcs.keys():
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

    def do_init(self):  # value "name" .init     creates a variable with an initial value from the stack
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}INIT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        var_name = self.pop_past()
        if not is_string(var_name):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}INIT {Fore.CYAN}{var_name}{Fore.YELLOW} not a valid name{Style.RESET_ALL}", flush = True)
            raise ValueError
        value = self.pop_past()
        if var_name in self.global_funcs.keys():
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}INIT global function {Fore.CYAN}{var_name}{Fore.YELLOW} already exists{Style.RESET_ALL}", flush = True)
            raise ValueError
        if var_name in self.local_vars[-1].keys():
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}INIT local variable {Fore.CYAN}{var_name}{Fore.YELLOW} already exists, overwriting with {Fore.CYAN}{value}{Style.RESET_ALL}", flush = True)
        new_var = {var_name: value}
        self.local_vars[-1].update(new_var)

    def do_init_pre(self): # init: "name" value             NOTE reversed order.
        self.swap_fut()
        self.ins_fut_2(ls_word(".init"))

    def do_init_in(self): # value init "name"
        self.ins_fut_1(ls_word(".init"))

    def do_call(self):  # "name" .call       Put reference at front of command queue.  If a block or function, it will be expanded.
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}CALL{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}SET{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        var_name = self.pop_past()
        if not is_string(var_name):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}GET {Fore.CYAN}{var_name}{Fore.YELLOW} not a valid name{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}GET{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        var_name = self.pop_past()
        if not is_string(var_name):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}GET {Fore.CYAN}{var_name}{Fore.YELLOW} not a valid name{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FREE{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        if not is_string(var_name):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}FREE: {Fore.CYAN}{var_name}{Fore.YELLOW} not a valid name{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        self.meta_fut([1, 0, "push_e {pop_e .len 0 .>} {.extract_l swap push_e %a} .while drop"])

    def do_each_pre(self):   # each: block seq
        # self.swap_fut()
        self.ins_fut_2(ls_word(".each"))

    def do_each_in(self):   # seq each block
        self.ins_fut_1(ls_word(".each"))

    def do_map(self):   # seq block .map         like each, but collects values into a list   uses EACH
        self.meta_fut([0, 0, "2 (.each enlist_all)"])

    def do_map_pre(self):   # map: block list
        self.ins_fut_2(ls_word(".map"))

    def do_map_in(self):    # list map block
        self.ins_fut_1(ls_word(".map"))

    def do_times(self):     # num {block} .times        uses side stack n
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}TIMES{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        num = self.past[-2]
        if not is_int(num):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}TIMES{Fore.YELLOW}: ", end="")
            my_print(num)
            print(f" is not an integer{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.meta_fut([1, 0, "+ 1 push_n {pop_n - 1 dup push_n 0 .>} #a .while pop_n drop"])

    def do_times_in(self):
        self.ins_fut_1(ls_word(".times"))

    def do_times_pre(self):
        self.ins_fut_2(ls_word(".times"))

    def do_times_n(self):     # num {block} .times        uses side stack n
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}TIMES{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        num = self.past[-2]
        if not is_int(num):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}TIMES{Fore.YELLOW}: ", end="")
            my_print(num)
            print(f" is not an integer{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.meta_fut([1, 0, "+ 1 push_n {pop_n - 1 dup push_n 0 .>} \ copy_n #a .concat .while pop_n drop"])

    def do_times_n_in(self):
        self.ins_fut_1(ls_word(".times*"))

    def do_times_n_pre(self):
        self.ins_fut_2(ls_word(".times*"))

    def do_for(self):   # [{initial state}{incremental change}{exit condition}] {body} .for     uses side stack f
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FOR{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        if not is_seq(self.past[-2]):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FOR{Fore.YELLOW}: expected argument list {Fore.MAGENTA}", end="")
            my_print(a)
            print(f" is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        if len(self.past[-2]) != 3:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FOR{Fore.YELLOW}: argument list error {Fore.MAGENTA}", end="")
            my_print(a)
            print(f" incorrect length, expected 3{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.meta_fut([2, 0, "%a0 push_f {copy_f %a2 .not} while {%b pop_f %a1 push_f} pop_f drop"])  # [init inc cond] body --> init {cond} while {body inc}

    def do_for_pre(self):   # for: [{initial state}{incremental change}{exit condition}] {body}
        self.ins_fut_2(ls_word(".for"))

    def do_for_in(self):    # [{initial state}{incremental change}{exit condition}] for {body}
        self.ins_fut_1(ls_word(".for"))

    def do_for_f(self):   # [{initial state}{incremental change}{exit condition}] {body} .for     uses side stack f
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FOR{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        if not is_seq(self.past[-2]):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FOR{Fore.YELLOW}: expected argument list {Fore.MAGENTA}", end="")
            my_print(a)
            print(f" is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        if len(self.past[-2]) != 3:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}FOR{Fore.YELLOW}: argument list error {Fore.MAGENTA}", end="")
            my_print(a)
            print(f" incorrect length, expected 3{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.meta_fut([2, 0, "%a0 push_f {copy_f %a2 .not} while {copy_f %b pop_f %a1 push_f} pop_f drop"])  # [init inc cond] body --> init {cond} while {body inc}

    def do_for_f_pre(self):   # for: [{initial state}{incremental change}{exit condition}] {body}
        self.ins_fut_2(ls_word(".for*"))

    def do_for_f_in(self):    # [{initial state}{incremental change}{exit condition}] for {body}
        self.ins_fut_1(ls_word(".for*"))

    def do_filter(self):    # [list] {condition} .filter --> [filtered list]        uses side stacks f, g, e
        self.meta_fut([0, 0, "over swap .map swap push_g [] push_h {if {pop_g .extract_l swap push_g pop_h swap .concat push_h}{pop_g .extract_l drop push_g}} .each  pop_g drop pop_h"])

    def do_filter_pre(self):    # filter: [list] {condition}
        self.ins_fut_2(ls_word(".filter"))

    def do_filter_in(self):    # [list] filter {condition}
        self.ins_fut_1(ls_word(".filter"))

    def do_total(self): # [list] {action} .total --> total of action applied to list        *** action assumed to be postfix ***    uses side stacks e, t, u
        # self.meta_fut([0, 0, "2 (drop .extract_l swap $A $C A {C swap B.exec $C} .each clear C)"])
        self.meta_fut([0, 0, "push_t .extract_l push_u {pop_u swap copy_t .exec push_u} .each pop_t drop pop_u"])

    def do_total_pre(self):     # total: [list] {action}
        self.ins_fut_2(ls_word(".total"))

    def do_total_in(self):     # [list] total {action}
        self.ins_fut_1(ls_word(".total"))

    def do_case(self):  # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .case        uses side stacks o, p
        # self.meta_fut([0, 0, "[[{True}{drop}]] .concat 2 (clear {B .len 0 .>} while { .extract_l swap $B A swap .delist drop \\ break .concat .iff})"])
        self.meta_fut([0, 0, "[{True}{drop}] .append push_p push_o {pop_p .len 0 .>} while { .extract_l swap push_p copy_o swap .delist drop .type 'BLOCK' .!= { {} swap .append} .iff \\ break .append .iff} pop_o drop pop_p drop"])

    def do_case_pre(self):  # case: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_2(ls_word(".case"))

    def do_case_in(self):   # object case [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_1(ls_word(".case"))

    def do_match(self):  # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .case       uses side stacks o, p
        # self.meta_fut([0, 0, "[[{dup}{nop}]] .concat 2 (clear {B .len 0 .>} while { .extract_l swap $B A swap .delist drop \\ break .concat swap \\ .= .concat swap .iff})"])

        # self.meta_fut([0, 0, "[[{dup}{nop}]] .concat push_p push_o {pop_p .len 0 .>} while { .extract_l swap push_p copy_o swap .delist drop \\ break .concat .list>block swap \\ .= .concat .list>block swap .iff} pop_o drop pop_p drop"])

        self.meta_fut([0, 0, "[{dup}{nop}] .append push_p push_o {pop_p .len 0 .>} while { .extract_l swap push_p copy_o swap .delist drop .type 'BLOCK' .!= { {} swap .append} .iff \\ break .append swap .type 'BLOCK' .!= { {} swap .append} .iff \\ .= .append swap .iff} pop_o drop pop_p drop"])
    def do_match_pre(self):  # case: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_2(ls_word(".match"))

    def do_match_in(self):   # object case [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
        self.ins_fut_1(ls_word(".match"))

# of

    def do_type(self):    # .type    leaves type of item on TOS, preserved
        if len(self.past) == 0:
            self.push_past(False)
        else:
            item = self.past[-1]
            if is_list(item):
                self.push_past("LIST")
            elif is_block(item):
                self.push_past("BLOCK")
            elif is_int(item):
                self.push_past("INT")
            elif is_float(item):
                self.push_past("FLOAT")
            elif is_string(item):
                self.push_past("STR")
            elif is_word(item):
                self.push_past("WORD")
            elif is_bool(item):
                self.push_past("BOOL")
            else:
                self.push_past(False)  # how did you get here?

    def do_type_pre(self):    # type:
        self.ins_fut_1(ls_word(".type"))

    def do_len(self):   #   seq .len     pushes the length of seq on the stack, preserving seq
        seq = peek_n(self.past, -1)
        if not is_seq(seq):
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}LEN {Fore.CYAN}{seq}{Fore.YELLOW}: not a sequence{Style.RESET_ALL}", flush = True)
            length = -1
        else:
            length = len(seq)
        self.push_past(length)

    def do_len_pre(self):    # len: seq --> seq n
        self.ins_fut_1(ls_word(".len"))

    def do_extract_left(self):  # [a b c] .extract_l -> [b c] a    extracts the leftmost item in seq, pushes it on the stack, preserving what's left of seq
        seq = peek_n(self.past, -1)
        if not is_seq(seq):
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}EXTRACT_L {Fore.CYAN}{seq}{Fore.YELLOW}: not a sequence{Style.RESET_ALL}", flush = True)
            self.push_past(seq)
        length = len(seq)
        if length == 0:
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}EXTRACT_L {Fore.CYAN}{seq}{Fore.YELLOW}: empty{Style.RESET_ALL}", flush = True)
            self.push_past(False)
        item = pop_left(seq)
        self.push_past(item)

    def do_extract_left_pre(self):  # extract_l: [a b c] --> [b c] a
        self.ins_fut_1(ls_word(".extract_l"))

    def do_extract_right(self):  # [a b c] .extract_r --> [a b] c    extracts the rightmost item in seq, pushes it on the stack, preserving what's left of seq
        seq = peek_n(self.past, -1)
        if not is_seq(seq):
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}EXTRACT_R {Fore.CYAN}{seq}{Fore.YELLOW}: not a sequence{Style.RESET_ALL}", flush = True)
            self.push_past(seq)
        length = len(seq)
        if length == 0:
            print(f"\n{Fore.RED}Warning: {Fore.YELLOW}EXTRACT_R {Fore.CYAN}{seq}{Fore.YELLOW}: empty{Style.RESET_ALL}", flush = True)
            self.push_past(False)
        item = pop_right(seq)
        self.push_past(item)

    def do_extract_r_pre(self):     # extract_r: [a b c] --> [a b] c
        self.ins_fut_1(ls_word(".extract_r"))

    def do_delist(self):   # [a b c] .delist -> a b c 3
        seq = self.pop_past()
        if not is_seq(seq):
            self.push_past(seq)
            self.push_past(0)
        else:
            self.ext_past(seq)
            how_many = depth(seq)
            self.push_past(how_many)

    def do_delist_pre(self):    #   delist: [a b c] --> a b c 3
        self.ins_fut_1(ls_word(".delist"))

    def do_enlist(self):    #   a b c d e 2 enlist --> a b c [d e]
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}ENLIST{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        how_many = self.pop_past()
        if not is_int(how_many):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}ENLIST expected a number, not {Fore.CYAN}{how_many}{Style.RESET_ALL}", flush = True)
            raise ValueError
        if how_many > depth(self.past):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}ENLIST {Fore.CYAN}{how_many}{Fore.YELLOW}: too many items{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}NTH{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 3:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}INSERT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}DELETE{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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

    def do_push_(self, which):   # move top of stack to top of side stack a..z
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
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Warning: {Fore.CYAN}DROP{Fore.YELLOW}: stack is already empty,{Style.RESET_ALL}", flush = True)
        self.pop_past()

    def do_swap(self):  # a b c -> a c b
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}SWAP{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.past[-1], self.past[-2] = self.past[-2], self.past[-1]

    def do_roll(self):  # a b c -> b c a
        if len(self.past) < 3:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}ROLL{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = pop_n(self.past, -3)
        self.push_past(item)

    def do_over(self):  # a b c -> a b c b
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}OVER{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = peek_n(self.past, -2)
        self.push_past(item)

    def do_reverse(self):   # a b c d e f -> f e d c b a
        self.past.reverse()

    def do_dup(self):   # a b c --> a b c c
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}DUP{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = peek_n(self.past, -1)
        self.push_past(item)

    def do_rot_r(self): # a b c d e f 2 .rot_r -> e f a b c d      rotate stack to the right n places
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}ROT_R{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        how_many = self.pop_past()
        if not is_int(how_many):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}ROT_R expected a number, not {Fore.CYAN}{how_many}{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.past.rotate(how_many)

    def do_rot_r_pre(self):     # a b c d e f rot_r: 2 --> e f a b c d
        self.ins_fut_1(ls_word(".rot_r"))

    def do_rot_l(self):  # a b c d e f 2 .rot_l -> c d e f a b
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}ROT_L{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}+{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}+ expected numbers, not {Fore.CYAN}{a}, {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(a+b)

    def do_plus_pre(self):  # +: a b
        self.ins_fut_2(ls_word(".+"))

    def do_plus_in(self):   # a + b
        self.ins_fut_1(ls_word(".+"))

    def do_minus(self):     # a b .- --> a-b
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}-{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}- expected numbers, not {Fore.CYAN}{a} {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(a-b)

    def do_minus_pre(self):  # -: a b
        self.ins_fut_2(ls_word(".-"))

    def do_minus_in(self):   # a - b
        self.ins_fut_1(ls_word(".-"))

    def do_multiply(self):  # a b .* --> a*b
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}*{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}* expected numbers, not {Fore.CYAN}{a} {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(a*b)

    def do_multiply_pre(self):  # *: a b
        self.ins_fut_2(ls_word(".*"))

    def do_multiply_in(self):   # a * b
        self.ins_fut_1(ls_word(".*"))

    def do_divide(self):    # a b ./ --> a/b
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}/{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}/ expected numbers, not {Fore.CYAN}{a} {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
        if b == 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}{a} / {b} {Fore.YELLOW} divide by zero {Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(a/b)

    def do_divide_pre(self):  # /: a b
        self.ins_fut_2(ls_word("./"))

    def do_divide_in(self):   # a / b
        self.ins_fut_1(ls_word("./"))

    def do_int_divide(self):    # a b .// --> a//b      integer division
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}//{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}// expected numbers, not {Fore.CYAN}{a} {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
        if b == 0:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}{a} // {b} {Fore.YELLOW} divide by zero {Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(a//b)

    def do_int_divide_pre(self):  # //: a b --> a//b
        self.ins_fut_2(ls_word(".//"))

    def do_int_divide_in(self):   # a // b --> a//b
        self.ins_fut_1(ls_word(".//"))

    def do_modulus(self):       # a b .% --> a%b    modulus (remainder)
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}MOD{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}MOD expected numbers, not {Fore.CYAN}{a} {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(a % b)

    def do_modulus_pre(self):  # %: a b
        self.ins_fut_2(ls_word(".%"))

    def do_modulus_in(self):   # a % b
        self.ins_fut_1(ls_word(".%"))

    def do_div_mod(self):   # a b ./% --> a//b a%b   division with remainder
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}DIVMOD{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}DIVMOD expected numbers, not {Fore.CYAN}{a} {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
        if is_int(a) and is_int(b):
            self.push_past(a // b)
        else:
            self.push_past(a/b)
        self.push(a % b)
    def do_div_mod_pre(self):  # /%: a b --> a//b a%b
        self.ins_fut_2(ls_word("./%"))

    def do_div_mod_in(self):   # a /% b --> a//b a%b
        self.ins_fut_1(ls_word("./%"))

    def do_power(self):       # a b .power --> a to power of b
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}POWER{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}POWER expected numbers, not {Fore.CYAN}{a} {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
        c = a**b
        self.push_past(c)

    def do_power_pre(self):  # power: a b
        self.ins_fut_2(ls_word(".power"))

    def do_power_in(self):   # a power b
        self.ins_fut_1(ls_word(".power"))

    def do_root(self):  # a b .root --> b'th root of a  (a to power of 1/b)
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}ROOT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if not(is_number(a) and is_number(b)):
            print(f"\n{Fore.RED}Error: {Fore.YELLOW}ROOT expected numbers, not {Fore.CYAN}{a} {b}{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        self.push_past(c)

    def do_root_pre(self):  # root: a b
        self.ins_fut_2(ls_word(".root"))

    def do_root_in(self):   # a root b
        self.ins_fut_1(ls_word(".root"))

    def do_ln(self):    # a .ln --> natural log of a
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}LN{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.log(a)
        self.push_past(c)

    def do_ln_pre(self):    # ln: a
        self.ins_fut_1(ls_word(".ln"))

    def do_exp(self):   # a .exp --> e raise dto the a'th power
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}EXP{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.exp(a)
        self.push_past(c)

    def do_exp_pre(self):   # exp: a
        self.ins_fut_1(ls_word(".exp"))

    def do_log(self):   # a b .log --> logarithm of a with base b
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}LOG{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        c = math.log(a, b)
        self.push_past(c)

    def do_log_pre(self):   # log: a b
        self.ins_fut_2(ls_word(".log"))

    def do_log_in(self):    # a log b
        self.ins_fut_1(ls_word(".log"))

    def do_sqr(self):   # a .sqr --> a**2
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}SQR{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = a ** 2
        self.push_past(c)

    def do_sqr_pre(self):   # sqr: a
        self.ins_fut_1(ls_word(".sqr"))

    def do_sqrt(self):   # a .sqrt --> square root of a
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}SQRT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.sqrt(a)
        self.push_past(c)

    def do_sqrt_pre(self):   # sqrt: a
        self.ins_fut_1(ls_word(".sqrt"))

    def do_sin(self):   # a .sin        sin of a in radians
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}SIN{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.sin(a)
        self.push_past(c)

    def do_sin_pre(self):   # sin: a
        self.ins_fut_1(ls_word(".sin"))

    def do_cos(self):   # a .cos --> cos of a in radians
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}COS{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.cos(a)
        self.push_past(c)

    def do_cos_pre(self):   # cos: a
        self.ins_fut_1(ls_word(".cos"))

    def do_tan(self):   # a .tan --> tan of a in radians
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}TAN{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.tan(a)
        self.push_past(c)

    def do_tan_pre(self):   # tan: a
        self.ins_fut_1(ls_word(".tan"))

    def do_deg_rad(self):   # a .deg>rad --> convert degrees to radians
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}DEG>RAD{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.radians(a)
        self.push_past(c)

    def do_deg_rad_pre(self):   # deg>rad: a
        self.ins_fut_1(ls_word(".deg>rad"))

    def do_rad_deg(self):   # a .rad>deg --> convert radians to degrees
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}RAD>DEG{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.degrees(a)
        self.push_past(c)

    def do_rad_deg_pre(self):   # rad>deg: a
        self.ins_fut_1(ls_word(".rad>deg"))

    def do_asin(self):  # a .asin --> arcsin of a in radians
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}ASIN{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.asin(a)
        self.push_past(c)

    def do_asin_pre(self):   # asin: a
        self.ins_fut_1(ls_word(".asin"))

    def do_acos(self):   # a .acos --> arccos of a in radians
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}ACOS{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.acos(a)
        self.push_past(c)

    def do_acos_pre(self):   # acos: a
        self.ins_fut_1(ls_word(".acos"))

    def do_atan(self):   # a .atan --> arctan of a in radians
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}ATAN{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        c = math.atan(a)
        self.push_past(c)

    def do_atan_pre(self):   # atan: a
        self.ins_fut_1(ls_word(".atan"))


# Boolean logic

    def do_less(self):  # a b .<
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}<{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a < b)

    def do_less_pre(self):  #   <: a b
        self.ins_fut_2(ls_word(".<"))

    def do_less_in(self):   # a < b
        self.ins_fut_1(ls_word(".<"))

    def do_greater(self):   # a b .>
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}>{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a > b)

    def do_greater_pre(self):  #   >: a b
        self.ins_fut_2(ls_word(".>"))

    def do_greater_in(self):   # a > b
        self.ins_fut_1(ls_word(".>"))

    def do_equal(self):     # a b .=
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}={Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        if is_bool(a) and is_bool(b):
            self.push_past(a == b)
        elif type(a) != type(b):
            self.push_past(False)
        else:
            self.push_past(a == b)

    def do_equal_pre(self):  #   =: a b
        self.ins_fut_2(ls_word(".="))

    def do_equal_in(self):   # a = b
        self.ins_fut_1(ls_word(".="))

    def do_le(self):        #   a b .<=
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}+{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a <= b)

    def do_le_pre(self):  #   <=: a b
        self.ins_fut_2(ls_word(".<="))

    def do_le_in(self):   # a .<= b
        self.ins_fut_1(ls_word(".<="))

    def do_ge(self):        # a b .>=
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}>={Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a >= b)

    def do_ge_pre(self):  #   >=: a b
        self.ins_fut_2(ls_word(".>="))

    def do_ge_in(self):   # a >= b
        self.ins_fut_1(ls_word(".>="))

    def do_ne(self):        # a b .!=   not equals
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}!={Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        self.push_past(a != b)

    def do_ne_pre(self):  #   !=: a b
        self.ins_fut_2(ls_word(".!="))

    def do_ne_in(self):   # a != b
        self.ins_fut_1(ls_word(".!="))

    def do_not(self):   # Boolean .not T --> F
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}NOT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        a = make_bool(a)
        self.push_past(not a)

    def do_not_pre(self):  #   not: F --> T
        self.ins_fut_1(ls_word(".not"))

    def do_and(self):        # a b .and
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}AND{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}OR{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}XOR{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = self.pop_past()
        a = self.pop_past()
        a = make_bool(a)
        b = make_bool(b)
        self.push_past(a != b)

    def do_xor_pre(self):  #   or: a b
        self.ins_fut_2(ls_word(".xor"))

    def do_xor_in(self):   # a or b
        self.ins_fut_1(ls_word(".xor"))



    def do_concat(self):        # [a] [b] .concat --> [a b]      concatenate two items/blocks/lists
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}CONCAT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}PRINT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = self.pop_past()
        my_print(item, False)

    def do_print_pre(self):
        self.ins_fut_1(ls_word(".print"))

    def do_print_q(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}PRINT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = self.pop_past()
        my_print(item, True)

    def do_print_q_pre(self):
        self.ins_fut_1(ls_word(".print_quote"))

    def do_println(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}PRINTLN{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = self.pop_past()
        my_println(item, False)

    def do_println_pre(self):
        self.ins_fut_1(ls_word(".println"))

    def do_println_q(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}PRINTLN_QUOTE{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = self.pop_past()
        my_println(item, True)

    def do_println_q_pre(self):
        self.ins_fut_1(ls_word(".println_quote"))


    def do_emit(self):     # number .emit    print char version of int
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}EMIT{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = self.pop_past()
        print(chr(item), end = "")

    def do_emit_pre(self):  # emit: number
        self.ins_fut_1(ls_word(".emit"))

    def do_dump(self):  # print stack, stack preserved
        my_println(self.past, True)

    def do_get_line(self):  # input a line from keyboard (stdin)
        line = input()
        self.push_past(line)

    def do_get_char(self):  # read a single keystroke
        line = getche()
        self.push_past(line)

    def do_get_char_silent(self):  # read a single key, no echo
        line = getch()
        self.push_past(line)

    def do_swap_ff(self):
        self.swap_fut()

    def do_swap_fp(self):
        self.swap_fut_past()

    def do_ins_fut_1(self):
        item = self.pop_past()
        self.ins_fut_1(item)

    def do_ins_fut_2(self):
        item = self.pop_past()
        self.ins_fut_2(item)

    def do_ins_fut_3(self):
        item = self.pop_past()
        self.ins_fut_3(item)

    def do_user_meta(self):  # [num_past, num_future, "pattern"] _meta_
        pattern = self.pop_past()
        new = do_meta(self.past, self.future, pattern)
        self.ext_fut(new)

    def do_str_to_list_c(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>LIST_CHAR{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        if not is_string(a):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>LIST_CHAR{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a)
            print(f"{Fore.YELLOW} is not a string{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = []
        for c in a:
            b.append(c)
        self.push_past(ls_list(b))

    def do_str_to_list_c_pre(self):
        self.ins_fut_1(ls_word(".str>list_char"))

    def do_str_to_list_w(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>LIST_WORD{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        if not is_string(a):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>LIST_WORD{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a)
            print(f"{Fore.YELLOW} is not a string{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = a.split()
        self.push_past(ls_list(b))

    def do_str_to_list_w_pre(self):
        self.ins_fut_1(ls_word(".str>list_char"))

    def do_list_to_str(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}LIST>STR{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        if not is_seq(a):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}LIST>STR{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a)
            print(f"{Fore.YELLOW} is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = "".join(a)
        self.push_past(b)

    def do_list_to_str_pre(self):
        self.ins_fut_1(ls_word(".list>str"))

    def do_list_to_str_sp(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}LIST>STR_SP{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        if not is_seq(a):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}LIST>STR_SP{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a)
            print(f"{Fore.YELLOW} is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = " ".join(a)
        self.push_past(b)

    def do_list_to_str_pre_sp(self):
        self.ins_fut_1(ls_word(".list>str"))

    def do_rev_list(self):  # reverse a sequence
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}REV{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        if not is_seq(a):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}REV{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a)
            print(f"{Fore.YELLOW} is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        a.reverse()
        self.push_past(a)

    def do_rev_list_pre(self):
        self.ins_fut_1(ls_word(".rev"))

    def do_in(self):    # item [list] .in --> Boolean
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}IN{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        where = self.pop_past()
        if not is_seq(a):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}IN{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a)
            print(f"{Fore.YELLOW} is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        what = self.pop_past()
        answer = what in where
        self.push_past(answer)

    def do_in_pre(self):    # in: item [list]
        self.ins_fut_2(ls_word(".in"))

    def do_in_in(self):     # item in [list]
        self.ins_fut_1(ls_word(".in"))

    def do_str_word(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>WORD{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = self.pop_past()
        if not is_string(item):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>WORD{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(item)
            print(f"{Fore.YELLOW} is not a string{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = item.strip()
        for c in item:
            if c in " \t\r\n[]{}'\"":
                print(f"\n{Fore.RED}Error: {Fore.CYAN}STR>WORD{Fore.YELLOW}: {Fore.MAGENTA}", end="")
                my_print(item, True)
                print(f"{Fore.YELLOW} is not a valid word{Style.RESET_ALL}", flush = True)
                raise ValueError
        self.push_past(ls_word(item))

    def do_str_word_pre(self):
        self.ins_fut_1(ls_word(".str_word"))

    def do_word_str(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}WORD>STR{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        item = self.pop_past()
        if not is_word(item):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}WORD>STR{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(item, True)
            print(f"{Fore.YELLOW} is not a word{Style.RESET_ALL}", flush = True)
            raise ValueError
        self.push_past(str(item))

    def do_word_str_pre(self):
        self.ins_fut_1(ls_word(".word_str"))

    def do_list_to_block(self):
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}LIST>BLOCK{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
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
        if len(self.past) < 1:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}BLOCK>LIST{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        a = self.pop_past()
        if not is_seq(a):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}BLOCK>LIST{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(a, True)
            print(f"{Fore.YELLOW} is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        b = ls_list(a)
        self.push_past(b)

    def do_block_to_list_pre(self):
        self.ins_fut_1(ls_word(".block>list"))

    def do_append(self): #   [appendee] appender .append --> [appendee appender]
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}APPEND{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        appender = self.pop_past()
        appendee = self.pop_past()
        if not is_seq(appendee):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}APPEND{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(appendee, True)
            print(f"{Fore.YELLOW} is not a sequence{Style.RESET_ALL}", flush = True)
            raise ValueError
        push_right(appendee, appender)
        self.push_past(appendee)

    def do_append_pre(self):
        self.ins_fut_2(ls_word(".append"))

    def do_append_in(self):
        self.ins_fut_1(ls_word(".append"))

    def do_join(self): #   "String1" "String2" .join --> "String1String2"
        if len(self.past) < 2:
            print(f"\n{Fore.RED}Error: {Fore.CYAN}JOIN{Fore.YELLOW}: stack is too low{Style.RESET_ALL}", flush = True)
            raise ValueError
        appender = self.pop_past()
        appendee = self.pop_past()
        if not is_alpha(appendee):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}JOIN{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(appendee, True)
            print(f"{Fore.YELLOW} is not a string{Style.RESET_ALL}", flush = True)
            raise ValueError
        if not is_alpha(appender):
            print(f"\n{Fore.RED}Error: {Fore.CYAN}JOIN{Fore.YELLOW}: {Fore.MAGENTA}", end="")
            my_print(appender, True)
            print(f"{Fore.YELLOW} is not a string{Style.RESET_ALL}", flush = True)
            raise ValueError
        appendee += appender
        self.push_past(str(appendee))

    def do_join_pre(self):
        self.ins_fut_2(ls_word(".join"))

    def do_join_in(self):
        self.ins_fut_1(ls_word(".join"))
