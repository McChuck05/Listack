# system
_set_namespace: "system"

def_immediate: "sp" [] {32 .emit}
def_immediate: "cr" [] {10 .emit}
def_immediate: "dupd" [Any, Any] {over swap}    # {dup} dip
def_immediate: "swapd" [Any, Any, Any] {{swap} dip}
def_immediate: "clear_err" [] {drop_err}

def: "def" [Wordy, Listy, Word] {>block .def}
def: "def_immediate" [Wordy, Listy, Word] {>block .def_immediate}
def: "inc" [Num] {1 .+}
def: "dec" [Num] {1 .-}
def: "inc" [Char] {ord 1 .+ >char}
def: "dec" [Char] {ord 1 .- >char}

# while
create_global: "_while_cond"
create_global: "_while_body"

# internal use only
def: "_while_" [] 
  {@!_while_cond 
  {@!_while_body _begin_loop_ 
   _while_}
  .iff}

# {condition to continue} while {body to execute}
# {true} while {println:"infinite loop"}

def: "while" [Blocky, Blocky] 
  {@>_while_body @>_while_cond 
  _while_ _end_loop_
  @<_while_body drop @<_while_cond drop}

def: "while" [Bool, Blocky] 
  {@>_while_body @>_while_cond 
  _while_ _end_loop_
  @<_while_body drop @<_while_cond drop}

def: "while" [Bool, Word] {>block .while}
def: "while" [Blocky, Word] {>block .while}

      
# {body} until {condition}
def: "until" [Blocky, Blocky] 
  { {not} .concat @>_while_cond @>_while_body
  @!_while_body _begin_loop_ _while_ _end_loop_}   
      # always executes body at least once
      # {body to execute} until {condition to terminate}  
      # {println:"infinite loop"} until {false}

def: "until" [Word, Blocky] {swap >block swap .until}
def: "until" [Blocky, Bool] {>block .until}
def: "until" [Word, Bool] {>block swap >block swap .until}

# each
create_global: "_each_list"
create_global: "_each_block"

# [list of things to act upon] {action to take on each list element} .each
# [1 2 3] {print sp} .each
def: "each" [Coll, Executable]
  {@>_each_block @>_each_list 
    _each_list .len 0 .!= {     # iff
      {_each_list len 0 .>} 
      {@<_each_list  first* swap @>_each_list @!_each_block} 
      .while } .iff
  @<_each_list drop @<_each_block drop}

def: "each" [Item, Blocky] {swap >list swap .each}
def: "each" [Item, Word] {.eval}
 
# apply_each
# [list of things to act upon] [{action 1} {action 2} {action 3}] .apply_each
# [1 2 3 4] [{print sp} {dup .+ print sp} {dup .* print sp}] .apply_each
def: "apply_each" [Coll, List] 
  {@>_each_block @>_each_list
    _each_list .len 0 .!= {     # iff
    { _each_block len  0 .> }
    { _each_list @<_each_block first* swap @>_each_block .each}  
  .while } .iff
  @<_each_list drop @<_each_block drop}

def: "apply_each" [Item, List] {swap >list swap .apply_each}
def: "apply_each" [Coll, Word] {>list .apply_each}
def: "apply_each" [Item, Word] {.eval}
def: "apply_each" [Coll, Blocky]  {1 .enlist .apply_each}
def: "apply_each" [Item, Blocky]  {1 .enlist swap >list swap .apply_each}


# apply_each_then
create_global: "_each_then"
# as apply_each, but does Executable between runs
# [1 2 3 4 5] [{print sp} {dup .+ print sp} {dup .* print sp}] {cr} .apply_each_then

def: "apply_each_then" [Coll, List, Executable]
  {@>_each_then @>_each_block @>_each_list
    { _each_block len  0 .> }
    { _each_list @<_each_block first* swap @>_each_block .each @!_each_then}  
  .while
  @<_each_list drop @<_each_block drop @<_each_then drop}

def: "apply_each_then" [Item, List, Executable] {roll >list roll roll .apply_each_then}
def: "apply_each_then" [Item, Executable, Executable] {roll >list roll 1 .enlist roll .apply_each_then}
def: "apply_each_then" [Coll, Executable, Executable] {swap 1 .enlist swap .apply_each_then}


# map
create_global: "_map_collect"
create_global: "_map_type"

def: "map" [Coll, Executable]
  {depth 2 .- @>_map_collect
  swap type* @>_map_type swap
  .each
  depth @<_map_collect .- dup 0 .>= 
  {.enlist @<_map_type 
    [ ["List" {nop}]
      ["Block" {>block}]
      ["Seq" {>seq}]
    ] .match } 
  {drop [] >bad} .if}

def: "map" [Item, Executable] {swap >list swap .map}

def: "apply_map" [Coll, List] 
  {@>_each_block @>_each_list
    _each_list .len 0 .!= {     # iff
    { _each_block len  0 .> }
    { _each_list @<_each_block first* swap @>_each_block .map}  
  .while } .iff
  @<_each_list drop @<_each_block drop}

def: "apply_map" [Item, List] {swap >list swap .apply_map}
def: "apply_map" [Coll, Word] {>list .apply_map}
def: "apply_map" [Item, Word] {.map}
def: "apply_map" [Coll, Blocky]  {1 .enlist .apply_map}
def: "apply_map" [Item, Blocky]  {1 .enlist swap >list swap .apply_map}


def: "apply_map_then" [Coll, List, Executable]
  {@>_each_then @>_each_block @>_each_list
    { _each_block len  0 .> }
    { _each_list @<_each_block first* swap @>_each_block .map @!_each_then}  
  .while
  @<_each_list drop @<_each_block drop @<_each_then drop}

def: "apply_map_then" [Item, List, Executable] {roll >list roll roll .apply_map_then}
def: "apply_map_then" [Item, Executable, Executable] {roll >list roll 1 .enlist roll .apply_map_then}
def: "apply_map_then" [Coll, Executable, Executable] {swap 1 .enlist swap .apply_map_then}


create_global: "_apply_a"
create_global: "_apply_b"
create_global: "_apply_f"
def_immediate: "a_b_apply_f" [Any, Any, Int, Int, Executable]
  {@>_apply_f @>_apply_b @>_apply_a 
  _apply_a + _apply_b <= depth if { 
    @<_apply_b {> 1} {.enlist} .iff* @>_apply_b 
    @<_apply_a {> 1} {.enlist} .iff*
    @<_apply_b @<_apply_f eval}
  else {set_err: "a_b_apply_f : insufficient items on stack"} }

def_immediate: "bi_each" [Any, Executable, Executable] {1 2 \.apply_each a_b_apply_f}
def_immediate: "bi_map" [Any, Executable, Executable] {1 2 \.apply_map a_b_apply_f}


# times
create_global: "_times_counter"
def: "times" [Executable, Int]
  {dup 0 .>   # if
    {@>_times_counter {@<_times_counter dec dup @>_times_counter 0 .>=} swap .while 
      @<_times_counter drop}
    {drop2} .if}

def: "times" [Int, Executable] {swap .times}


# times*
def: "times*" [Executable, Int]
  {dup 0 .>   # if
    {@>_times_counter {@<_times_counter dup dec dup @>_times_counter 0 .>=} swap .while 
      @<_times_counter drop2}
    {drop2} .if}

def: "times*" [Int, Executable] {swap .times*}



# for: [{initial state}{continuing condition}{incremental change}] {body to execute}
def: "for" [Coll, Executable]    
  {@>_while_body .len* 3 .=   # if
    { .first* swap    dump # stack is now: {init} [{cont cond} {inc change}]
      .last* @<_while_body swap .concat @>_while_body   dump  # added incremental change to end of body, stack is now: {init} [{cont cond}]
      .last @>_while_cond   dump   # stack is now: {init}
      .eval   dump  # stack is now: init
      _while_ _end_loop_}   # the _while_cond and _while_body stacks are already set, so call _while_ instead of .while
    else {"for error: [{initial state}{incremental change}{halting condition}] expected but not found" set_err 
      @<_while_body drop} 
    .if  _end_}


# reduce
create_global: "_reduce_body"
create_global: "_reduce_collect"

def: "reduce" [Coll Executable]
  {@>_reduce_body @>_reduce_collect _reduce_body len 0 .= _reduce_collect len 0 .= .or .not {      # iff
    @<_reduce_collect first* @>_reduce_collect 
    { @<_reduce_collect swap @!_reduce_body @>_reduce_collect} .each } .iff
    @<_reduce_body drop @<_reduce_collect}

        # [list to be reduced] {reduction algorithm} .reduce
        # [1 2 3 4] {.+} .reduce --> 10


# filter
create_global: "_filter_original"
create_global: "_filter_final"

def: "filter" [Coll, Executable]
  { [] @>_filter_final over @>_filter_original .map
  each {if 
    {@<_filter_original first* @<_filter_final swap .append @>_filter_final @>_filter_original}
    {@<_filter_original first* drop @>_filter_original}}
  @<_filter_original drop @<_filter_final}

        # [list to be filtered] {filtering function} .filter
        # [0 1 -2 3 -4 5 -6] {0 .<} .filter --> [-2 -4 -6]
        

# case
create_global: "_case_item"
create_global: "_case_list"

def: "case" [Any, Coll]
  { [{drop true}{_case_item >bad}] .append    # add default case
  @>_case_list @>_case_item 
  {_case_list .len 0 .>}  # while
    {@<_case_list first* swap @>_case_list 
    .delist drop swap _case_item swap   # if
      {.eval break} {drop} .if} 
  .while _end_loop_  
  @<_case_item drop @<_case_list drop}

def: "case*" [Any, Coll]
  { [{drop true}{>bad}] .append    # add default case
  @>_case_list @>_case_item 
  {_case_list .len 0 .>}  # while
    {@<_case_list first* swap @>_case_list 
    .delist drop swap _case_item swap   # if
      {_case_item swap .eval break} {drop} .if}
  .while _end_loop_  
  @<_case_item drop @<_case_list drop}

# match
def: "match" [Any, Coll]
  { over {_case_item >bad} 2 .enlist .append   # add default case
  @>_case_list @>_case_item 
  {_case_list .len 0 .>}  # while
    {@<_case_list first* swap @>_case_list 
    .delist drop swap _case_item .==  # if
      {.eval break} {drop} .if}
  .while _end_loop_  
  @<_case_item drop @<_case_list drop}

def: "match*" [Any, Coll]
  { over {>bad} 2 .enlist .append   # add default case
  @>_case_list @>_case_item 
  {_case_list .len 0 .>}  # while
    {@<_case_list first* swap @>_case_list 
    .delist drop swap _case_item .==  # if
      {_case_item swap .eval break} {drop} .if}
  .while _end_loop_  
  @<_case_item drop @<_case_list drop}


# dip & keep
create_global: "_dipped"

# a b {commands} dip --> a commands b
def_immediate: "dip" [Any, Executable] {swap @>_dipped eval @<_dipped}

# a b {commands} keep --> a b commands b
def_immediate: "keep" [Any, Executable] {over @>_dipped eval @<_dipped}


def: "variable?" [Any] {local? swap global? roll .or}

def: "resolve" [Coll] {{variable? {eval} .iff} .map}
# 42 @>a [1 2 3 a 5] resolve --> [1 2 3 42 5]


# [1 2 [3 4 [5 6] 7] 8] nth* [2 2 1] --> [1 2 [3 4 [5 6] 7] 8] 6
def: "nth*" [Coll, List] {dupd {.nth nip}  .each}

# [1 2 [3 4 [5 6] 7] 8] nth [2, 2, 1] --> 6
def: "nth" [Coll, List] {{.nth nip}  .each}

# [1 2 3] <nth 2 --> [1 2] 3
def: "<nth" [Coll, Int] {.extract}
def: "<nth" [String, Int] {.extract}

# [1 2 3] >nth 2 42 --> [1 2 42]
def: ">nth" [Coll, Int, Any] {@>_dipped {.delete} keep @<_dipped .insert}
def: ">nth" [String, Int, String] {@>_dipped {.delete} keep @<_dipped .insert}
def: ">nth" [String, Int, Char] {@>_dipped {.delete} keep @<_dipped .insert}

# [1 2 3] >>nth 2 42 --> [1 2 42 3]
def: ">>nth" [Coll, Int, Any] {.insert}
def: ">>nth" [String, Int, String] {.insert}
def: ">>nth" [String, Int, Char] {.insert}


# 3 in* [1, 2, 3] --> [1, 2, 3] true
def: "in*" [Item, Coll] {{.in} keep swap}
def: "in*" [Coll, Coll] {{.in} keep swap}
def: "in*" [Char, String] {{.in} keep swap}
def: "in*" [String, String] {{.in} keep swap}

# [1, 2, 3] <-in 2 --> true
def: "<-in" [Coll, Item] {swap .in}
def: "<-in" [Coll, Coll] {swap .in}
def: "<-in" [String, Char] {swap .in}
def: "<-in" [String, String] {swap .in}

# [1, 2, 3] <-in* 2 --> [1, 2, 3] true
def: "<-in*" [Coll, Item] {swap {.in} keep swap}
def: "<-in*" [Coll, Coll] {swap {.in} keep swap}
def: "<-in*" [String, Char] {swap {.in} keep swap}
def: "<-in*" [String, String] {swap {.in} keep swap}


# 3 where* [1, 2, 3] --> [1, 2, 3] 2
def: "where*" [Item, Coll] {{.where} keep swap}
def: "where*" [Coll, Coll] {{.where} keep swap}
def: "where*" [Char, String] {{.where} keep swap}
def: "where*" [String, String] {{.where} keep swap}

# [1, 2, 3] <-where 2 --> 1
def: "<-where" [Coll, Item] {swap .where}
def: "<-where" [Coll, Coll] {swap .where}
def: "<-where" [String, Char] {swap .where}
def: "<-where" [String, String] {swap .where}

# [1, 2, 3] <-where* 2 --> [1, 2, 3] 1
def: "<-where*" [Coll, Item] {swap {.where} keep swap}
def: "<-where*" [Coll, Coll] {swap {.where} keep swap}
def: "<-where*" [String, Char] {swap {.where} keep swap}
def: "<-where*" [String, String] {swap {.where} keep swap}


# evaluate and object based on a type word
def: "x_obj?" [Object Word] {{obj_val*} dip .eval nip}    # true/false
def: "x_obj" [Object Word] {.x_obj? {>good} {>bad} .if}   # good/bad

def: "check_obj?" [Object] {check_obj good?}

def: "Null_obj" [Object] {\Null? .x_obj}
def: "Null_obj?" [Object] {\Null? .x_obj?}

def: "Int_obj" [Object] {\Int? .x_obj}
def: "Int_obj?" [Object] {\Int? .x_obj?}

def: "Float_obj" [Object] {\Float? .x_obj}
def: "Float_obj?" [Object] {\Float? .x_obj?}

def: "Bool_obj" [Object] {\Bool? .x_obj}
def: "Bool_obj?" [Object] {\Bool? .x_obj?}

def: "Char_obj" [Object] {\Char? .x_obj}
def: "Char_obj?" [Object] {\Char? .x_obj?}

def: "String_obj" [Object] {\String? .x_obj}
def: "String_obj?" [Object] {\String? .x_obj?}

def: "Word_obj" [Object] {\Word? .x_obj}
def: "Word_obj?" [Object] {\Word? .x_obj?}

def: "List_obj" [Object] {\List? .x_obj}
def: "List_obj?" [Object] {\List? .x_obj?}

def: "Block_obj" [Object] {\Block? .x_obj}
def: "Block_obj?" [Object] {\Block? .x_obj?}

def: "Seq_obj" [Object] {\Seq? .x_obj}
def: "Seq_obj?" [Object] {\Seq? .x_obj?}

def: "Object_obj" [Object] {\Object? .x_obj}
def: "Object_obj?" [Object] {\Object? .x_obj?}

def: "Coll_obj" [Object] {\Coll? .x_obj}
def: "Coll_obj?" [Object] {\Coll? .x_obj?}

def: "Item_obj" [Object] {\Item? .x_obj}
def: "Item_obj?" [Object] {\Item? .x_obj?}

def: "Num_obj" [Object] {\Num? .x_obj}
def: "Num_obj?" [Object] {\Num? .x_obj?}

def: "Alpha_obj" [Object] {\Alpha? .x_obj}
def: "Alpha_obj?" [Object] {\Alpha? .x_obj?}

def: "Alphanum_obj" [Object] {\Alphanum? .x_obj}
def: "Alphanum_obj?" [Object] {\Alphanum? .x_obj?}

def: "Wordy_obj" [Object] {\Wordy? .x_obj}
def: "Wordy_obj?" [Object] {\Wordy? .x_obj?}

def: "Blocky_obj" [Object] {\Blocky? .x_obj}
def: "Blocky_obj?" [Object] {\Blocky? .x_obj?}

def: "Listy_obj" [Object] {\Listy? .x_obj}
def: "Listy_obj?" [Object] {\Listy? .x_obj?}


# Evals executable if the argument is valid (not bad, not empty, not 0)
# similar to functional 'maybe'
def: "when*" [Any, Executable] {{dup >bool} dip {drop} .if}
def: "when" [Any, Executable] {{>bool} dip .iff}

def: "max" [Alphanum, Alphanum] {dup2 {.>} {drop} {nip} .if}
def: "min" [Alphanum, Alphanum] {dup2 {.<} {drop} {nip} .if}


# make a function that applies another to a list by pairs, producing a new list
# [1 2 3 4] {.+} .pairwise --> [3 5 7]
# then make map_reduce, which accumulates a result
# [1 2 3 4] {.+} .map_reduce --> [3 6 10]

create_global: "_pairwise_collect"
def: "pairwise" [Coll Executable]
  {@>_reduce_body dup @>_reduce_collect .empty @>_pairwise_collect _reduce_body len 0 .= _reduce_collect len 0 .= .or .not {      # iff
    @<_reduce_collect first* @>_reduce_collect 
    { @<_reduce_collect swap dup @>_reduce_collect @!_reduce_body 
      @<_pairwise_collect swap .append @>_pairwise_collect} .each } .iff
    @<_reduce_body drop @<_reduce_collect drop @<_pairwise_collect}

    # [list] {algorithm} .pairwise
    # [1 2 3 4] {.+} .pairwise --> [3 5 7]

def: "map_reduce" [Coll Executable]
  {@>_reduce_body dup @>_reduce_collect .empty @>_pairwise_collect _reduce_body len 0 .= _reduce_collect len 0 .= .or .not {      # iff
    @<_reduce_collect first* @>_reduce_collect 
    { @<_reduce_collect swap @!_reduce_body dup @>_reduce_collect
      @<_pairwise_collect swap .append @>_pairwise_collect} .each } .iff
    @<_reduce_body drop @<_reduce_collect drop @<_pairwise_collect}

    # [list] {algorithm} .map_reduce
    # [1 2 3 4] {.+} .map_reduce --> [3 6 10]


def: "flatten" [Coll]
  { dup empty swap {.concat} .each}

def: "stomp" [Coll] 
  {dup empty swap {Coll? iff {stomp} .concat} .each}

def_immediate: "both" [Any, Any, Executable]
  {dup @>_apply_f .eval swap @<_apply_f .eval swap}

_reset_namespace
# end of system
   
  
