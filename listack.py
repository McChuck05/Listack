# Listack v0.34
# listack.py
# main program with execution loop
# Invoke as: python listack.py target_file.ls [debug]
# Copyright McChuck, 2023
# May be freely redistributed and used with attribution under GPL3.


import sys, os, copy
from ls_parser import parse_commands
from ls_helpers import *
from ls_commands import ls_commands
from collections import deque
from colorama import Fore, Back, Style
try:
    from getch import getch, getche         # Linux
except ImportError:
    from msvcrt import getch, getche        # Windows

lowers = "abcdefghijklmnopqrstuvwxyz"   #   global stacks
uppers = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"   #   local variables
digits = "0123456789"
sugar = ["then", "else", "do", "of"]


def main_loop(commands_in, debug):
    ls = ls_commands(commands_in)
    current = ""
    breaking = False
    continuing = False
    exiting = False
    past_begin = False

    try:
        while ls.future:
            current = ls.pop_fut()
            if debug:
                print(f"{Fore.CYAN}PAST: {Style.RESET_ALL}", end="")
                my_println(ls.past, True)
                print(f"{Fore.YELLOW}>>>{Fore.RED}", end="")
                my_print(current, True)
                print(f"{Fore.YELLOW}<<<{Style.RESET_ALL}", flush=True)
                print(f"{Fore.MAGENTA}FUTURE: {Style.RESET_ALL}", end="")
                my_println(ls.future, True)
                print("\n", flush=True)
                getch()

            if breaking:
                if current == "begin_while":
                    past_begin = True
                elif current == ".while" and past_begin:
                    breaking = False
                    past_begin = False
                continue

            if continuing:
                if current == "begin_while":
                    continuing = False
                continue

            if exiting:
                if current == "end":    # user needs to insert this himself, but there is one auto-added to the end of program
                    exiting = False
                continue

            if is_seq(current):
                ls.push_past(current)

            elif is_number(current):
                ls.push_past(current)

            elif is_bool(current):
                ls.push_past(current)

            elif current == "":
                ls.push_past("")

            elif current == "\\":        # \ word            pushes next word onto the stack
                ls.do_move_to_stack()

            elif current[0] == "`":     # ` word             make next command word into a block and push to the stack
                ls.make_block()

            elif current[0] == "$":     # quick alias for $name.set
                push_right(ls.past, current[1:])
                ls.do_set()

            elif current[0] == "@":     # quick alias for @name.get
                push_right(ls.past, current[1:])
                ls.do_get()

            elif current[0] == "~":     # quick alias for name.call
                push_right(ls.past, current[1:])
                ls.do_call()

            elif is_string(current):    # strings, like blocks and lists, are not evaluated
                ls.push_past(current)

# basic control flow

            elif current == ".exec":    #   postfix           [item] .exec -> item
                ls.do_exec()

            elif current == "exec:":    #   prefix           exec: [item] -> item
                ls.do_exec_pre()

            elif current == ".choose":    #   postfix CHOOSE     cond true false .choose -> true/false      NOTE: .if == .choose .exec
                ls.do_choose()

            elif current == "choose:":    #   prefix CHOOSE      choose: cond true false -> true/false
                ls.do_choose_pre()

            elif current == "choose":    #   infix CHOOSE      cond choose true false -> true/false
                ls.do_choose_in()

            elif current == ".if":  #   postfix conditional  a {cond} {true} {false} .if -> true/false
                ls.do_if()

            elif current == "if":   #   infix conditional   a {cond} if {true} {false} -> true/false
                ls.do_if_in()

            elif current == "if:":  #   prefix conditional  a if: {cond} {true} {false} -> true/false
                ls.do_if_pre()

            elif current == ".if*":  #   a {cond} {a true} {false} .if -> true/false
                ls.do_if_star()

            elif current == "if*":   #    a {cond} if {a true} {false} -> true/false
                ls.do_if_star_in()

            elif current == "if*:":  #  a if: {cond} {a true} {false} -> true/false
                ls.do_if_star_pre()

            elif current == ".iff": # a cond {true} .iff        if and only if (no else)
                ls.do_iff()

            elif current == "iff:": # a iff: cond {true}
                ls.do_iff_pre()

            elif current == "iff":  # a cond iff {true}
                ls.do_iff_in()

            elif current == ".iff*": # a cond {true} .iff*  --> {a true} nop      if and only if (no else)
                ls.do_iff_star()

            elif current == "iff*:": # a iff*: cond {true}  --> {a true} nop
                ls.do_iff_star_pre()

            elif current == "iff*":  # a cond iff* {true}  --> {a true} nop
                ls.do_iff_star_in()

            elif current == ".while":   # postfix loop      a {cond} {body} .while -> a cond if {body begin_while {cond} {body} .while} {nop}
                ls.do_while()

            elif current == "while:":   # prefix loop       a while: [cond] [body] -> a cond if {body begin_while {cond} {body} .while} {nop}
                ls.do_while_pre()

            elif current == "while":    # infix loop        a {cond} while {body} -> a cond if {body begin_while {cond} {body} .while} {nop}
                ls.do_while_in()

            elif current == "break":    # break out of a while loop
                breaking = True

            elif current == "cont":     # stop executing the current while body and continue with the loop
                continuing = True

            elif current in sugar:      # "then", "else", "do", "of"
                continue

            elif current == "exit":     # ignore everything until end
                exiting = True

            elif current == "halt":     # halt execution
                print(f"\n{Fore.RED}Listack halted!{Style.RESET_ALL}")
                exit(1)

            elif current == "begin_while":    # tag for cont and break
                pass

            elif current == "end":      # tag for exit
                pass

            elif current == "nop":      # do nothing, no operation
                pass

# local variables and global functions

            elif current == ".def":     # {words} "name" def       define a global function "name" that executes words
                ls.do_def()            # overwrites existing function of same name

            elif current == "def:":     # def: "name" {words}       NOTE reversed order
                ls.do_def_pre()

            elif current == "def":     # {words} def "name"
                ls.do_def_in()

            elif current == ".init":     #   value "name" .init     creates a local variable "name" and assigns value
                ls.do_init()

            elif current == "init:":    # init: "name" value        NOTE reversed order
                ls.do_init_pre()

            elif current == "init":    # value init "name"
                ls.do_init_in()

            elif current == ".call":     # "name" .call   executes the contents of variable/function "name", unpacking if a block
                ls.do_call()

            elif current == "call:":    # call: "name"
                ls.do_call_pre()

            elif current == ".set":      # value "name" set ->       set a pre-existing variable or function value
                ls.do_set()

            elif current == "set:":     # set: "name" value         NOTE reversed order
                ls.do_set_pre()

            elif current == "set":     # value set "name"
                ls.do_set_in()

            elif current == ".get":     # "name" .get -> value       get a variable or function value
                ls.do_get()

            elif current == "get:":     # get: "name"
                ls.do_get_pre()

            elif current == ".free":    # "varname" .free       delete a variable
                ls.do_free()

            elif current == "free:":    # free: "varname"
                ls.do_free_pre()

# scope

            elif current == "(":        # open scope        n ( -> new stack with n items copied to it, new local vars a..n initialized with items
                ls.do_open_scope()

            elif current == ")":        # close scope       ) -> copies all stack items to lower stack, deletes current stack and local variables.
                ls.do_close_scope()

# combinators

            elif current == ".each":      # seq block EACH    applies block to each item in seq     uses side stack e
                ls.do_each()

            elif current == "each:":     # EACH: seq block
                ls.do_each_pre()

            elif current == "each":    # seq EACH block
                ls.do_each_in()

            elif current == ".map":      # postfix   list block .map    like EACH, but collects values into a list    uses side stack e (each)
                ls.do_map()

            elif current == "map:":     # prefix    map: block list
                ls.do_map_pre()

            elif current == "map":     # infix     list map block
                ls.do_map_in()

            elif current == ".times":   # n {block} .times --> execute {block} n times, n stored in side_n      uses side stack n
                ls.do_times()

            elif current == "times":    # times: n {block}
                ls.do_times_in()

            elif current == "times:":   # n times {block}
                ls_do_times_pre()

            elif current == ".times*":   # n {block} .times --> execute {n block} n times, n stored in side_n      uses side stack n
                ls.do_times_n()           # current value of n is TOS for body to use

            elif current == "times*":    # times: n {block}
                ls.do_times_n_in()

            elif current == "times*:":   # n times {block}
                ls_do_times_n_pre()

            elif current == ".for":     # [{initial state}{incremental change}{exit condition}] {body} .for     uses side stack f
                ls.do_for()

            elif current == "for:":     # for: [{initial state}{incremental change}{exit condition}] {body}
                ls.do_for_pre()

            elif current == "for":      # [{initial state}{incremental change}{exit condition}] for {body}
                ls.do_for_in()

            elif current == ".for*":     # [{initial state}{incremental change}{exit condition}] {body} .for     uses side stack f
                ls.do_for_f()     # counter is TOS for body to use

            elif current == "for*:":     # for: [{initial state}{incremental change}{exit condition}] {body}
                ls.do_for_f_pre()

            elif current == "for*":      # [{initial state}{incremental change}{exit condition}] for {body}
                ls.do_for_f_in()

            elif current == ".filter":  # [list] {condition} .filter    --> [filtered list]
                ls.do_filter()          # uses side stacks g, h, e (each)

            elif current == "filter:":  # filter: [list] {condition}
                ls.do_filter_pre()

            elif current == "filter":   # [list] filter {condition}
                ls.do_filter_in()

            elif current == ".total":   # [list] {action} .total --> total of action applied to the elements of list [1 2 3]{.+}.total --> 6
                ls.do_total()           # uses side stacks t, u, e (each)

            elif current == "total:":   # total: [list] {action}        *** action MUST be postfix ***
                ls.do_total_pre()

            elif current == "total":    # [list] total {action}
                ls.do_total_in()

            elif current == ".case":    # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .case    "[{True}{drop}]" is added to ensure there is a default case
                ls.do_case()            # uses side stacks o, p

            elif current == "case:":    # case: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_case_pre()

            elif current == "case":     # object case [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_case_in()

            elif current == ".match":    # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .match    "[{dup}{nop}]" is added to ensure there is a default case
                ls.do_match()           # uses side stacks o, p

            elif current == "match:":    # match: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_match_pre()

            elif current == "match":     # object match [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_match_in()

# list functions

            elif current == ".type":    # .type  leaves type of top stack item, preserved.  LIST, BLOCK, INT, FLOAT, STR, BOOL, WORD
                ls.do_type()

            elif current == "type:":    # type:
                ls.do_type_pre()

            elif current == ".len":      # {a b c} .len -> {a b c} 3     pushes the length of seq on the stack, preserving seq
                ls.do_len()

            elif current == "len:":      # len: [a b c] --> [a b c] 3
                ls_do_len_pre()

            elif current == ".extract_l":  # [a b c] .extract_l -> [b c] a
                ls.do_extract_left()

            elif current == "extact_l:":    # extract_l: [a b c] --> [b c] a
                ls.do_extract_left_pre()

            elif current == ".extract_r":  # [a b c] .extract_l -> [a b] c
                ls.do_extract_right()

            elif current == "extract_r:":   # extract_r: [a b c] --> [a b] c
                ls.do_extract_right_pre()

            elif current == ".delist":  # [a b c] delist -> a b c 3         leaves item and '0' if item is not a sequence
                ls.do_delist()

            elif current == "delist:":  # delist: {a b c} --> a b c 3
                ls.do_delist_pre()

            elif current == ".enlist":   # a b c d e 2 enlist --> a b c [d e]
                ls.do_enlist()

            elif current == "enlist:":  # a b c d e f enlist: 2 --> a b c [d e]
                ls.do_enlist_pre()

            elif current == "enlist_all":   # a b c d e enlist_all --> [a b c d e]
                ls.do_enlist_all()

            elif current == ".nth": # [list] n .nth --> [list] list[n]      preserves [list]        n is integer    first = 0, last = -1
                ls.do_nth()

            elif current == "nth:": # nth: [list] n
                ls.do_nth_pre()

            elif current == "nth":  # [list] nth n
                ls.do_nth_in()

            elif current == ".insert":  # [list] item place .insert  --> [list with item inserted]       place 0 = start, -1 = end
                ls.do_insert()

            elif current == "insert:":  # insert: [list] item place
                ls.do_insert_pre()

            elif current == "insert":   # [list] insert item place
                ls.do_insert_in()

            elif current == ".delete":  # [list] where .delete  --> [list without item]
                ls.do_delete()

            elif current == "delete:":  # delete: [list] where
                ls.do_delete_pre()

            elif current == "delete":   # [list] delete where
                ls.do_delete_in()

            elif current == ".concat":  # [a b c] 4 .concat -> [a b c 4]        concatenate 2 items/lists/blocks
                ls.do_concat()  # if two different sequences, takes type of first one   {a b c} [1 2 3] CONCAT -> {a b c 1 2 3}

            elif current == "concat:":  # concat: [a]{b} --> [a b]
                ls.do_concat_pre()

            elif current == "concat":  # {a} concat [b] --> {a b}
                ls.do_concat_in()

            elif current == ".str>list_char":     # convert string to list of characters
                ls.do_str_to_list_c()

            elif current == "str>list_char:":
                ls_do_str_to_list_c_pre()

            elif current == ".str>list_word":     # convert string to list of words, separated by blank-space
                ls.do_str_to_list_w()

            elif current == "str>list_word:":
                ls_do_str_to_list_w_pre()

            elif current == ".list>str":    # convert sequence to string
                ls.do_list_to_str()

            elif current == "list>str:":
                ls.do_list_to_str_pre()

            elif current == ".list>str_sp":
                ls.do_list_to_str_sp()

            elif current == "list>str_sp:":
                ls.do_list_to_str_sp_pre()

            elif current == ".rev":
                ls.do_rev_list()

            elif current == "rev:":
                ls.do_rev_list_pre()

            elif current == ".in":  # item [list] .in
                ls.do_in()

            elif current == "in:":  # in: item [list]
                ls.do_in_pre()

            elif current == "in":   # item in [list]
                ls.do_in_in()

            elif current in ["LIST", "BLOCK", "BOOL", "INT", "FLOAT", "STR", "WORD"]:
                ls.push_past(ls_word(current))

            elif current == ".str>word": #   "name" .str>word --> name
                ls.do_str_word()

            elif current == "str>word:":
                ls.do_str_word_pre()

            elif current == ".word>str": #   name .word>str --> "name"
                ls.do_word_str()

            elif current == "word>str:":
                ls.do_word_str_pre()

            elif current == ".list>block":  # [a b c]] .list>block --> {a b c}
                ls.do_list_to_block()

            elif current == "list>block:":
                ls.do_list_to_block_pre()

            elif current == ".block>list":  # {a b c} .block>list --> [a b c]
                ls.do_block_to_list()

            elif current == "block>list:":
                ls.do_block_to_list_pre()

            elif current == ".append":      # [a b] c .append --> [a b c]   [a b ] [c] .append --> [a b [c]]
                ls.do_append()

            elif current == "append:":
                ls.do_append_pre()

            elif current == "append":   # [1 2] append 3 --> [1 2 3]
                ls.do_append_in()

            elif current == ".join":    # "hello " "there!" .join --> "Hello there!"
                ls.do_join()

            elif current == "join:":
                ls.do_join_pre()

            elif current == "join":
                ls.do_join_in()

# Stack functions

            elif current[:5] == "push_":  # move top of data stack to top of a side stack a..z
                ls.do_push_(current[5])

            elif current[:4] == "pop_":    # move top of a side stack a..z to top of data stack
                ls.do_pop_(current[4])

            elif current[:5] == "copy_":    # copy top of side stack a..z to top of data pop_stack
                ls.do_copy_(current[5])

            elif current[:6] == "depth_:":  # push depth of side stack z..a to the data pop_stack
                ls.do_depth_(current[6])

            elif current == "drop":     # a b c DROP -> a b
                ls.do_drop()

            elif current == "swap":     # a b c SWAP -> a c b
                ls.do_swap()

            elif current == "roll":     # a b c ROLL -> b c a
                ls.do_roll()

            elif current == "reverse":  # a b c d e f REVERSE -> f e d c b a
                ls.do_reverse()

            elif current == "over":     # a b c OVER -> a b c b
                ls.do_over()

            elif current == "dup":      # a b c -> a b c c
                ls.do_dup()

            elif current == ".rot_r":   # a b c d e 2 .rot_r --> d e a b c      rotate stack n places to the right
                ls.do_rot_r()

            elif current == "rot_r:":   # a b c d e rot_r: 2 --> d e a b c
                ls.do_rot_r_pre()

            elif current == "depth":    # pushes length of past stack
                ls.do_depth()

            elif current == "restore_stack":  # restores an old copy of data stack.  Ignores local variables
                ls.do_restore_stack()

            elif current == "save_stack":     # saves a copy of the data stack
                ls.do_save_stack()

            elif current == "clear":    # clears the data stack
                ls.do_clear()

# Math

            elif current == ".+":    # a b .+ --> a+b
                ls.do_plus()

            elif current == "+:":   # +: a b --> a+b
                ls.do_plus_pre()

            elif current == "+":   # a + b --> a+b
                ls.do_plus_in()

            elif current == ".-":    # a b .- --> a-b
                ls.do_minus()

            elif current == "-:":   # -: a b --> a-b
                ls.do_minus_pre()

            elif current == "-":   # a - b --> a-b
                ls.do_minus_in()

            elif current == ".*":    # a b .* --> a*b
                ls.do_multiply()

            elif current == "*:":   # *: a b --> a*b
                ls.do_multiply_pre()

            elif current == "*":   # a * b --> a*b
                ls.do_multiply_in()

            elif current == "./":    # a b ./ --> a/b   error if b == 0
                ls.do_divide()

            elif current == "/:":    # /: a b --> a/b   error if b == 0
                ls.do_divide_pre()

            elif current == "/":    # a / b --> a/b   error if b == 0
                ls.do_divide_in()

            elif current == ".//":   # a b .// --> a//b   error if b == 0
                ls.do_int_divide()

            elif current == "//:":   # //: a b --> a//b   error if b == 0
                ls.do_int_divide_pre()

            elif current == "//":   # a // b --> a//b   error if b == 0
                ls.do_int_divide_in()

            elif current in [".%", ".mod"]:    # a b .% --> a%b  .mod   (modulus = remainder)
                ls.do_modulus()

            elif current in ["%:", "mod:"]:    # %: a b --> a%b  mod:
                ls.do_modulus_pre()

            elif current in ["%", "mod"]:    # a % b --> a%b  mod
                ls.do_modulus_in()

            elif current in ["./%", ".divmod"]:   # a b ./% --> a//b a%b     .divmod    division with remainder
                ls.do_div_mod()

            elif current in ["/%:", "divmod:"]:   # /%: a b --> a//b a%b     divmod:
                ls.do_div_mod_pre()

            elif current in ["/%", "divmod"]:   # a /% b --> a//b a%b       divmod
                ls.do_div_mod_in()

            elif current == ".power":    # a b .power --> a**b      a to the power of b
                ls.do_power()

            elif current == "power:":   # power: a b --> a**b
                ls.do_power_pre()

            elif current == "power":    # a power b --> a**b
                ls.do_power_in()

            elif current == ".root":   # a b .root --> a**(1/b)     b'th root of a
                ls.do_root()

            elif current == "root:":   # root: a b
                ls.do_root()

            elif current == "root":   # a root b
                ls.do_root()

            elif current == ".ln":  # a .ln --> natural log of a
                ls.do_ln()

            elif current == "ln:":  # ln: a
                ls.do_ln_pre()

            elif current == ".exp": # a .exp --> e raised to the a'th power
                ls.do_exp()

            elif current == "exp:": # exp: a
                ls.do_exp_pre()

            elif current == ".log": # a b .log --> logarithm of a with base b
                ls.do_log()

            elif current == "log:": # log: a b
                ls.do_log_pre()

            elif current == "log":  # a log b
                ls.do_log_in()

            elif current == ".sqr": # a .sqr --> a**2
                ls.do_sqr()

            elif current == "sqr:": # sqr: a
                ls.do_sqr_pre()

            elif current == ".sqrt": # a .sqrt --> square root of a
                ls.do_sqrt()

            elif current == "sqrt:": # sqrt: a
                ls.do_sqrt_pre()

            elif current == ".sin": # a .sin
                ls.do_sin()

            elif current == "sin:": # sin: a --> sin of a radians
                ls.do_sin_pre()

            elif current == ".cos": # a .cos  --> cos of a radians
                ls.do_cos()

            elif current == "cos:": # cos: a
                ls._do_cos_pre()

            elif current == ".tan": # a .tan --> tan of a radians
                ls.do_tan()

            elif current == "tan:": # tan: a
                ls.do_tan_pre()

            elif current == ".deg>rad": # a .deg>rad --> convert degrees to radians
                ls.do_deg_rad()

            elif current == "deg>rad:": # deg>rad: a
                ls.do_deg_rad_pre()

            elif current == ".rad>deg": # a .rad>deg --> convert radians to degrees
                ls.do_rad_deg()

            elif current == "rad>deg:": # rad>deg: a
                ls.do_rad_deg_pre()

            elif current == "pi":   # pi = 3.14159...
                ls.push_past(3.141592653589793)

# Boolean logic

            elif current in [False, "False", "false", "FALSE", "F", "f"]:
                ls.push_past(False)

            elif current in [True, "True", "true", "TRUE" , "T", "t"]:
                ls.push_past(True)

            elif current == ".<":    # a b .<
                ls.do_less()

            elif current == "<:":    # <: a b
                ls.do_less_pre()

            elif current == "<":    # < a b <
                ls.do_less_in()

            elif current == ".>":       # a b .>
                ls.do_greater()

            elif current == ">:":       # >: a b
                ls.do_greater_pre()

            elif current == ">":       # a > b
                ls.do_greater_in()

            elif current == ".=":        # a b .=       equal to
                ls.do_equal()

            elif current == "=:":        # =: a b
                ls.do_equal_pre()

            elif current == "=":        # a = b
                ls.do_equal_in()

            elif current == ".>=" or current == ".!<":       # a b .>=
                ls.do_ge()

            elif current == ">=:" or current == "!<:":       # >=: a b
                ls.do_ge_pre()

            elif current == ">=" or current == "!<":       # a >= b
                ls.do_ge_in()

            elif current == ".<=" or current == ".!>":       # a b .<=
                ls.do_le()

            elif current == "<=:" or current == "!>:":       # <=: a b
                ls.do_le_pre()

            elif current == "<=" or current == "!>":       # a <= b
                ls.do_le_in()

            elif current == ".!=":   # a b .!=      not equal to
                ls.do_ne()

            elif current == "!=:":  # !=: a b       literal ! =
                ls.do_ne_pre()

            elif current == "!=":   # a != b
                ls.do_ne_in()

            elif current == ".not":      # Boolean   T .not --> F
                ls.do_not()

            elif current == "not:":      # not: F --> T
                ls.do_not_pre()

            elif current == ".and":       # Boolean    T F .and --> F
                ls.do_and()

            elif current == "and:":      #  and: T T --> T
                ls.do_and_pre()

            elif current == "and":    # F and T --> F
                ls.do_and_in()

            elif current == ".or":       # Boolean    T F .or --> T
                ls.do_or()

            elif current == "or:":      #  or: F F --> F
                ls.do_or_pre()

            elif current == "or":    # F or T --> T
                ls.do_or_in()

            elif current == ".xor":       # Boolean    T F .xor --> T
                ls.do_xor()

            elif current == "xor:":      #  xor: T T --> F
                ls.do_xor_pre()

            elif current == "xor":    # F or F --> T
                ls.do_xor_in()

# input and output

            elif current == ".print":
                ls.do_print()

            elif current == "print:":
                ls.do_print_pre()

            elif current == ".print_quote":
                ls.do_print_q()

            elif current == "print_quote:":
                ls.so_print_q_pre()

            elif current == ".println":
                ls.do_println()

            elif current == "println:":
                ls.do_println_pre()

            elif current == ".println_quote":
                ls.do_println_q()

            elif current == "println_quote:":
                ls.do_println_q_pre()

            elif current == ".emit":     # number emit       print character version of int
                ls.do_emit()

            elif current == "emit:":    # emit: number
                ls.do_emit_pre()

            elif current == "dump":     # print stack, no change
                ls.do_dump()

            elif current == "get_line":   # read line from keyboard (stdin)
                ls.do_get_line()

            elif current == "get_char":  # read one key stroke
                ls.do_get_char()

            elif current == "get_char_silent":  # read one key stroke without echoing it to the screen
                ls.do_get_char_silent()

# meta programming

            elif current == "_swap_ff": # swap top two items on the future queue
                ls.do_swap_ff()

            elif current == "_swap_fp": # swap the top elements of future and past
                ls.do_swap_fp()

            elif current == "_ins_f1":  # insert TOS 1 deep in future q
                ls.do_ins_fut_1()

            elif current == "_ins_f2":  # insert TOS 2 deep in future q
                ls.do_ins_fut_2()

            elif current == "_ins_f3":  # insert TOS 3 deep in future q
                ls.do_ins_fut_3()

            elif current == "_meta_":    # [num_past, num_future, "pattern"] _meta --> new future
                ls.do_user_meta()

# user defined variables and functions

            elif current in ls.local_vars[-1]:  # get
                item = copy_of(ls.local_vars[-1][current])
                ls.push_past(item)

            elif current in ls.global_funcs:    # call
                item = copy_of(ls.global_funcs[current])
                if is_block(item):
                    ls.ext_fut(item)
                else:
                    ls.push_fut(item)

# anything else is a fatal error

            elif is_word(current):
                print(f"\n{Fore.RED}Error:{Fore.YELLOW} Unrecognized command: {Fore.MAGENTA}{current}{Style.RESET_ALL}\n", flush = True)
                raise ValueError
            else:
                print(f"\n{Fore.RED}Error:{Fore.YELLOW} Syntax error: {Fore.MAGENTA}{current}{Fore.YELLOW}\nHow did this happen?{Style.RESET_ALL}\n", flush = True)
                raise ValueError

    except (ValueError, IndexError):
        print(f"\n{Fore.CYAN}{ls.past}", flush=True)
        print(f"{Fore.YELLOW}>>>{Fore.RED}{current}{Fore.YELLOW}<<<{Style.RESET_ALL}", flush=True)
        print(f"{Fore.MAGENTA}{ls.future}{Style.RESET_ALL}\n", flush=True)
        raise


def main(args):
    debug = False
    if len(args) < 1:
        print("Error:  No program file specified.")
        raise ValueError
    file_arg = args[0]
    parsed = deque([])
    raw = ""
    if len(args) == 2 and args[1] == "debug":
        debug = True
    try:
        with open(file_arg, "r") as in_file:
            raw = in_file.read()
            in_file.close()
        parsed = parse_commands(raw)
        parsed.append(ls_word("end"))
        if debug:
            print(f"{Fore.YELLOW}Listack beginning with:{Fore.GREEN}")
            my_print(parsed, True)
            print(f"{Style.RESET_ALL}\n\n", flush=True)
        main_loop(parsed, debug)
        print(f"\n\n{Fore.GREEN}Listack completed successfully! {Style.RESET_ALL}")
    except (ValueError, IndexError):
        print(f"\n\n{Back.RED}Something went wrong! {Style.RESET_ALL}")


if __name__ == '__main__':
    main(sys.argv[1:])
