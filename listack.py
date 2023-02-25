# Listack v0.38.1
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
import pickle
try:
    from getch import getch, getche         # Linux
except ImportError:
    from msvcrt import getch, getche        # Windows

lowers = "abcdefghijklmnopqrstuvwxyz"   #   global stacks
uppers = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"   #   local variables
digits = "0123456789"
sugar = ["then", "else", "do", "of"]
user_err = ""

def main_loop(commands_in, debug, verbose):
    ls = ls_commands(commands_in)
    global user_err
    current = ""
    breaking = False
    continuing = False
    exiting = False
    past_begin = False
    prev_list = ["", "", "", "", "", "", "", "", "", "", "", ""]
    running = True

    try:
        while ls.future and running:
            for count in range(11):
                prev_list[count] = prev_list[count+1]
            prev_list[11] = current
            current = ls.pop_fut()
            if debug:
                print(f"{Fore.CYAN}PAST: {Style.RESET_ALL}", end="")
                my_pretty_println(ls.past, True)
                print(f"{Fore.GREEN}>>>{Fore.RED}", end="")
                my_pretty_print(current, True)
                print(f"{Fore.GREEN}<<<{Style.RESET_ALL}", flush=True)
                print(f"{Fore.MAGENTA}FUTURE: {Style.RESET_ALL}", end="")
                immediate_future = copy_of(ls.future)
                immediate_future = ls_slice(immediate_future, 12)
                my_pretty_println(immediate_future, True)
                print("\n", flush=True)
                try:
                    getch()
                except KeyboardInterrupt:
                    pass

            if breaking:
                if current == "_begin_while_":
                    past_begin = True
                elif current == ".while" and past_begin:
                    breaking = False
                    past_begin = False
                continue

            if continuing:
                if current == "_begin_while_":
                    continuing = False
                continue

            if exiting:
                if current == "end":    # user needs to insert this himself, but there is one auto-added to the end of program
                    exiting = False
                continue

            elif is_seq(current):
                ls.push_past(current)

            elif is_number(current):
                ls.push_past(current)

            elif is_bool(current):
                ls.push_past(current)

            elif current == "":
                ls.push_past("")

            elif current in [ls_word("false"), ls_word("False"), ls_word("FALSE")]:
                ls.push_past(False)

            elif current in [ls_word("true"), ls_word("True"), ls_word("TRUE")]:
                ls.push_past(True)

            elif current == "\\":        # \ word            pushes next word onto the stack
                ls.do_move_to_stack()    # This should never execute.  It's here just in case.'

            elif current[0] == "\\":    # \word         ignore word, push to stack
                ls.push_past(ls_word(current[1:]))      # converts to word, whether it should be one or not

            elif current[0] == "`":     # ` word             make next command word into a block and push to the stack
                ls.make_block()

            elif current[0] == "$":     # quick alias for $name.set
                push_right(ls.past, current[1:])
                ls.do_set()

            elif current[0] == "@":     # quick alias for @name.get
                push_right(ls.past, current[1:])
                ls.do_get()

            elif current[0] == "!":     # quick alias for name.call
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
                running = False
                break

            elif current == "fail":     # halt execution, show error message
                print(f"\n{Fore.RED}Listack failed!{Style.RESET_ALL}")
                running = False
                raise ValueError

            elif current == "_begin_while_":    # tag for cont and break
                pass

            elif current == "end":      # tag for exit
                pass

            elif current == "nop":      # do nothing, no operation
                pass

            elif current == ".until":   # {body} {condition} .until     does body until condition is True, executes at least once
                ls.do_until()

            elif current == "until:":
                ls.do_until_pre()

            elif current == "until":
                ls.do_until_in()

            elif current == ".<=>":      # number {do if negative} {do if zero} {do if positive} .<=>
               ls.do_starship()

            elif current == "<=>:":     # <=>: number {do if negative} {do if zero} {do if positive}
                ls.do_starship_pre()

            elif current == "<=>":      # number <=> {do if negative} {do if zero} {do if positive}
                ls.do_starship_in()

# local variables and global functions

            elif current == ".def":     # {words} "name" def       define a global function "name" that executes words
                ls.do_def(verbose)            # overwrites existing function of same name

            elif current == "def:":     # def: "name" {words}       NOTE reversed order
                ls.do_def_pre()

            elif current == "def":     # {words} def "name"
                ls.do_def_in()

            elif current == ".init":     #   value "name" .init     creates a local variable "name" and assigns value
                ls.do_init(verbose)

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

            elif current == "|>":        # open scope        n |> -> new stack with n items copied to it, new local vars a..n initialized with items
                ls.do_open_scope()

            elif current == "<|":        # close scope       <| -> copies all stack items to lower stack, deletes current stack and local variables.
                ls.do_close_scope()

# combinators

            elif current == ".each":      # seq block EACH    applies block to each item in seq     uses side stack e
                ls.do_each()

            elif current == "each:":     # EACH: seq block
                ls.do_each_pre()

            elif current == "each":    # seq EACH block
                ls.do_each_in()

            elif current == ".apply_each":      # [seq] [{list}{of}{blocks}].apply_each    applies each block to each item in seq     uses side stacks d, e
                ls.do_apply_each()

            elif current == "apply_each:":     # apply_each: [seq] [{list}{of}{blocks}]
                ls.do_apply_each_pre()

            elif current == "apply_each":    # [seq] apply_each [{list}{of}{blocks}]
                ls.do_apply_each_in()

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

            elif current == ".reduce":   # [list] {action} .reduce --> action applied progressively to the elements of list [1 2 3]{.+}.reduce --> 6
                ls.do_reduce()           # uses side stacks r, s, e (each)

            elif current == "reduce:":   # total: [list] {action}        *** action MUST be postfix ***
                ls.do_reduce_pre()

            elif current == "reduce":    # [list] total {action}
                ls.do_reduce_in()

            elif current == ".case":    # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .case    "[{True}{drop}]" is added to ensure there is a default case
                ls.do_case()            # uses side stacks o, p

            elif current == "case:":    # case: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_case_pre()

            elif current == "case":     # object case [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_case_in()

            elif current == ".case*":    # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .case*
                ls.do_case_star()            # as case, but pushes object to TOS for body to use

            elif current == "case*:":    # case*: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_case_star_pre()

            elif current == "case*":     # object case* [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_case_star_in()

            elif current == ".match":    # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .match    "[{dup}{nop}]" is added to ensure there is a default case
                ls.do_match()           # uses side stacks o, p

            elif current == "match:":    # match: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_match_pre()

            elif current == "match":     # object match [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_match_in()

            elif current == ".match*":    # object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]] .match*
                ls.do_match_star()           # as match, but pushes object to stack for body to use

            elif current == "match*:":    # match*: object [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_match_star_pre()

            elif current == "match*":     # object match* [[{cond1}{body1}][{cond2}{body2}]...[True {default}]]
                ls.do_match_star_in()

# list functions

            elif current == ".type":    # .type  leaves type of top stack item, preserved.  LIST, BLOCK, INT, FLOAT, STR, BOOL, WORD
                ls.do_type()

            elif current == "type:":    # type:
                ls.do_type_pre()

            elif current == ".len":      # {a b c} .len -> {a b c} 3     pushes the length of seq on the stack, preserving seq
                ls.do_len()

            elif current == "len:":      # len: [a b c] --> [a b c] 3
                ls_do_len_pre()

            elif current == ".first":  # [a b c] .first -> a
                ls.do_first()

            elif current == "first:":    # first: [a b c] --> a
                ls.do_first_pre()

            elif current == ".last":  # [a b c] .last -> c
                ls.do_last()

            elif current == "last:":   # last: [a b c] --> c
                ls.do_last_pre()

            elif current == ".first*":  # [a b c] .first -> [b c] a     preserves list
                ls.do_first_star()

            elif current == "first*:":    # first: [a b c] --> [b c] a
                ls.do_first_star_pre()

            elif current == ".last*":  # [a b c] .last -> [a b] c       preserves list
                ls.do_last_star()

            elif current == "last*:":   # last: [a b c] --> [a b] c
                ls.do_last_star_pre()

            elif current == ".but_first":    # [1 2 3] .but_first --> [2 3]
                ls.do_but_first()

            elif current == "but_first:":   # but_first: [1 2 3] --> [2 3]
                ls.do_but_first_pre()

            elif current == ".but_last":    # [1 2 3] .but_last --> [1 2]
                ls.do_but_last()

            elif current == "but_last:":    # but_last: [1 2 3] --> [1 2]
                ls.do_but_last_pre()

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

            elif current == ".str>list":     # convert string to list of characters
                ls.do_str_to_list()          # "hello there" .str>list --> ['h' 'e' 'l' 'l' 'o' ' ' 't' 'h' 'e' 'r' 'e']

            elif current == "str>list:":
                ls_do_str_to_list_pre()

            elif current == ".str>list_sp":     # convert string to list of words, separated by blank-space
                ls.do_str_to_list_sp()          # "hello there" .str>list_sp --> ["hello" "there"]

            elif current == "str>list_sp:":
                ls_do_str_to_list_sp_pre()

            elif current == ".list>str":    # convert sequence to string
                ls.do_list_to_str()         # ["hello" "there"] .list>str --> "hellothere"

            elif current == "list>str:":
                ls.do_list_to_str_pre()

            elif current == ".list>str_sp":   # convert sequence to string, spaces between words
                ls.do_list_to_str_sp()        # {"hello" "there"} .list>str_word --> "hello there"

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

            elif current == ".str>num": # "123" .str>num --> 123
                ls.do_str_num()

            elif current == "str>num:":
                ls.do_str_num_pre()

            elif current == ".num>str": # 123 .num>str --> "123"
                ls.do_num_str()

            elif current == "num>str:":
                ls.do_num_str_pre()

            elif current == ".range":   # start stop .range --> [start, next, next ... stop]     works for integers and characters, going up or down
                ls.do_range()

            elif current == "range:":   # range: start stop
                ls.do_range_pre()

            elif current in ["range", ".."]:    # start .. stop    must have spaces around ".."
                ls.do_range_in()

            elif current == ".range_by":   # start stop step .range_by --> [start start+step ... stop]     works for integers and floats
                ls.do_range_by()

            elif current == "range_by:":    # range_by: start stop step
                ls.do_range_by_pre()

            elif current =="range_by":   # start stop range_by step
                ls.do_range_by_in()

            elif current == ".sort":    # [c d b a] .sort --> [a b c d]     [4 2 3 1] .sort --> [1 2 3 4]   strings or numbers, not both
                ls.do_sort()

            elif current == "sort:":
                ls.do_sort_pre()

            elif current == ".zip":     #   [1 2 3] [a b c] .zip --> [[1 a] [2 b] [3 c]]    always produces a list
                ls.do_zip()             # if unequal, the longer portion is discarded

            elif current == "zip:":     #   zip: {1 2 3} {a b c} --> [[1 a] [2 b] [3 c]]
                ls.do_zip_pre()

            elif current == "zip":      #   [1 2 3] zip {a b c} --> [[1 a] [2 b] [3 c]]
                ls.do_zip_in()

            elif current == ".unzip":   # [[1 a][2 b][3 c]] .unzip --> [1 2 3][a b c]
                ls.do_unzip()           # will discard any element after te first one that isn't a sequence of length 2

            elif current == "unzip:":
                ls.do_unzip_pre()

            elif current == ".char>int":    # ' ' .char>int --> 32      'hello' .char>int --> [...]
                ls.do_char_int()

            elif current == "char>int:":
                ls.do_char_int_pre()

            elif current == ".int>char":    # 32.int>char --> ' '       [...].int_char --> "hello"
                ls.do_int_char()

            elif current == "int>char:":
                ls.do_int_char_pre()

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

            elif current == ".bit_not": #   bitwise not
                ls.do_bit_not()

            elif current == "bit_not:":
                ls.do_bit_not_pre()

            elif current == ".bit_and": # bitwise and
                ls.do_bit_and()

            elif current == "bit_and:":
                ls.do_bit_and_pre()

            elif current == "bit_and":
                ls.do_bit_and_in()

            elif current == ".bit_or":  # bitwise or
                ls.do_bit_or()

            elif current == "bit_or:":
                ls.do_bit_or_pre()

            elif current == "bit_or":
                ls.do_bit_or_in()

            elif current == ".bit_xor": # bitwise xor
                ls.do_bit_xor()

            elif current == "bit_xor:":
                ls.do_bit_xor_pre()

            elif current == "bit_xor":
                ls.do_bit_xor_in()

            elif current == ".bit_r":   # int how_many .bit_r
                ls.do_bit_r()

            elif current == "bit_r:":   # bit_r: int how_many
                ls.do_bit_r_pre()

            elif current == "bit_r":    # int bit_r how_many
                ls.do_bit_r_in()

            elif current == ".bit_l":   # int how_many .bit_l
                ls.do_bit_l()

            elif current == "bit_l:":   # bit_l: int how_many
                ls.do_bit_l_pre()

            elif current == "bit_l":    # int bit_l how_many
                ls.do_bit_l_in()

# Boolean logic

            elif current in [False, True]:
                ls.push_past(current)

            elif current == ".make_bool":
                ls.do_make_bool()

            elif current == "make_bool:":
                ls.do_make_bool_pre()

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

            elif current == ".==":        # a b .==       equal to and same type
                ls.do_equalt()

            elif current == "==:":        # ==: a b
                ls.do_equalt_pre()

            elif current == "==":        # a == b
                ls.do_equalt_in()

            elif current == ".>=" or current == ".~<":       # a b .>=
                ls.do_ge()

            elif current == ">=:" or current == "~<:":       # >=: a b
                ls.do_ge_pre()

            elif current == ">=" or current == "~<":       # a >= b
                ls.do_ge_in()

            elif current == ".<=" or current == ".~>":       # a b .<=
                ls.do_le()

            elif current == "<=:" or current == "~>:":       # <=: a b
                ls.do_le_pre()

            elif current == "<=" or current == "~>":       # a <= b
                ls.do_le_in()

            elif current == ".~=":   # a b .~=      not equal to, forgiving of types
                ls.do_ne()

            elif current == "~=:":  # ~=: a b
                ls.do_ne_pre()

            elif current == "~=":   # a ~= b
                ls.do_ne_in()

            elif current == ".~==":   # a b .~==      strictly not equal to
                ls.do_net()

            elif current == "~==:":  # ~==: a b
                ls.do_net_pre()

            elif current == "~==":   # a ~== b
                ls.do_net_in()

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

            elif current == ".valid_num?":  # string valid_number? --> True if string is a valid number, False otherwise
                ls.do_valid_number_q()

            elif current == "valid_num?:":
                ls.do_valid_number_q_pre()

# meta programming

            elif current == "_swap_ff": # swap top two items on the future queue
                ls.do_swap_ff()

            elif current == "_swap_fp": # swap the top elements of future and past
                ls.do_swap_fp()

            elif current == "_ins_f0":  # insert TOS 0 deep in future q (push to front)
                ls.do_ins_fut_0()

            elif current == "_ins_f1":  # insert TOS 1 deep in future q
                ls.do_ins_fut_1()

            elif current == "_ins_f2":  # insert TOS 2 deep in future q
                ls.do_ins_fut_2()

            elif current == "_ins_f3":  # insert TOS 3 deep in future q
                ls.do_ins_fut_3()

            elif current == "_ins_f4":  # insert TOS 4 deep in fuutre q
                ls.do_ins_fut_4()

            elif current == "_meta_":    # [num_past, num_future, "pattern"] _meta --> new future
                ls.do_user_meta()

            elif current == ".load":     # "filename.ls" .load       loads and executes filename
                ls.do_load(verbose)     # file names must end in .ls

            elif current == "load:":    # load: "filename"      if "filename" does not end in ".ls", ."ls" is added
                ls.do_load_pre()

            elif current == ".err_msg": # string .err_msg       saves a message to print in case of error.
                user_err = ls.do_err_msg()

            elif current == "err_msg:": # err_msg: string        saves a message to print in case of error.
                user_err = ls.do_err_msg_pre()

# other

            elif current in ls.global_funcs:    # check for global function
                item = copy_of(ls.global_funcs[current])
                if is_block(item):      # unpack and execute code block
                    ls.ext_fut(item)
                elif is_word(item):     # execute word
                    ls.push_fut(item)
                else:
                    ls.push_past(item)  # push anything else to the stack, because that's where it will end up 

            else:
                found_local = False     # check for local variable
                for local_v in reversed(ls.local_vars):
                    if current in local_v:
                        item = copy_of(local_v[current])
                        ls.push_past(item)
                        found_local = True
                        break
                if not found_local:     # must be an error
                    if is_word(current):
                        print(f"\n{Fore.RED}Error:{Fore.YELLOW} Unrecognized command: {Fore.MAGENTA}{current}{Style.RESET_ALL}\n", flush = True)
                        raise ValueError
                    else:
                        print(f"\n{Fore.RED}Error:{Fore.YELLOW} Syntax error: {Fore.MAGENTA}{current}{Fore.YELLOW}\nHow did this happen?{Style.RESET_ALL}\n", flush = True)
                        raise ValueError

    except (ValueError, IndexError, KeyboardInterrupt):
        print(f"\n{Back.RED}Execution halted!{Style.RESET_ALL}")
        print(f"\n{Fore.YELLOW}>>>{Fore.RED}{current}{Fore.YELLOW}<<<{Style.RESET_ALL}", flush=True)
        print(f"\n{Fore.BLACK}{Style.BRIGHT}{Back.CYAN}{user_err}{Style.RESET_ALL}", flush=True)
        print(f"\n{Fore.CYAN}Data Stack: {Style.RESET_ALL}", flush=True, end="")
        my_pretty_println(ls.past, True)
        print(f"\n{Fore.MAGENTA}Current program state: {Style.RESET_ALL}", end = "")
        while len(prev_list) > 0:
            if prev_list[0] == "":
                prev_list = prev_list[1:]
            else:
                break
        my_pretty_print(prev_list, True)
        print(f" {Back.RED}{current}{Style.RESET_ALL}  ", end="")
        partial = copy_of(ls.future)
        partial = ls_slice(partial, 12)
        my_pretty_println(list(partial), True)
        if verbose:
            print(f"\n\n{Fore.YELLOW}Local variables:{Style.RESET_ALL}")
            for c in ls.local_vars[-1]:
                if c not in uppers:     # print user created variables on their own lines
                    print()
                print(f"{Fore.YELLOW}{c}{Style.RESET_ALL} = ", end="")
                my_pretty_print(ls.local_vars[-1][c], True)
                print("  ", sep="", end="")
            print(f"\n\n{Fore.YELLOW}Side stacks:{Style.RESET_ALL}")
            for c in lowers:
                print(f"{Fore.YELLOW}{c}{Style.RESET_ALL} = ", end="")
                my_pretty_print(ls.side[c], True)
                print("  ", end="")
            print(f"\n\n{Fore.YELLOW}Global functions{Style.RESET_ALL}")
            for c in ls.global_funcs:
                print(f"{Fore.YELLOW}{c}{Style.RESET_ALL} = ", end="")
                my_pretty_print(ls.global_funcs[c], True)
                print("\n")
            print()
        if running:
            raise


def main(args):
    debug = False
    verbose = False
    if len(args) < 1:
        print("Error:  No program file specified.")
        raise ValueError
    file_arg = args[0]
    parsed = deque([])
    raw = ""
    if "debug" in args:
        debug = True
    if "verbose" in args:
        verbose = True
    try:
        if file_arg.endswith(".ls"):        # unparsed text program
            with open(file_arg, "r") as in_file:
                raw = in_file.read()
                in_file.close()
            parsed = parse_commands(raw, 0, False, debug, verbose)
            parsed.append(ls_word("end"))
            file_arg += "p"
            with open(file_arg, "wb") as out_file:
                pickle.dump(parsed, out_file)
                out_file.close()
        elif file_arg.endswith(".lsp"):     # parsed and pickled program
            with open(file_arg, "rb") as in_file:
                parsed = pickle.load(in_file)
                in_file.close()
        if verbose:
            print(f"\n{Fore.YELLOW}Listack beginning with:{Fore.GREEN}")
            my_pretty_println(ls_block(parsed), True)
            print(f"{Style.RESET_ALL}\n\n", flush=True)
        main_loop(parsed, debug, verbose)
        print(f"\n\n{Fore.GREEN}Listack completed successfully! {Style.RESET_ALL}")
    except (ValueError, IndexError):
        print(f"\n\n{Fore.RED}Execution halted by error. {Style.RESET_ALL}")
        if verbose:
            raise
    except (KeyboardInterrupt):
        print(f"\n\n{Fore.RED}Execution halted by user. {Style.RESET_ALL}")


if __name__ == '__main__':
    main(sys.argv[1:])
