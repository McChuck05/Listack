# system

# while
create_stack: "_while_cond"
create_stack: "_while_body"

def: "_while" [] 
  {@!_while_cond 
  {@!_while_body _begin_loop_ 
  # dump get_char `H  .= iff {exit}
   _while}
  .iff}

def: "while" [Block, Block] 
  {@>_while_body @>_while_cond 
  _while _end_loop_
  @<_while_body drop @<_while_cond drop}

def: "while" [Bool, Block] 
  {@>_while_body @>_while_cond 
  _while _end_loop_
  @<_while_body drop @<_while_cond drop}

      # {condition to continue} while {body to execute}
      # {true} while {println:"infinite loop"}

# until
def: "until" [Block, Block] 
  { {not} .concat @>_while_cond @>_while_body
  @!_while_body _begin_loop_ _while _end_loop_}   
      # always executes body at least once
      # {body to execute} until {condition to terminate}  
      # {println:"infinite loop"} until {false}

# each
create_stack: "_each_list"
create_stack: "_each_block"

def: "each" [Coll, Block]  
  {@>_each_block @>_each_list 
    _each_list .len 0 .!= {     # iff
      {_each_list len 0 .>} 
      {@<_each_list  first* swap @>_each_list @!_each_block} 
      .while } .iff
  @<_each_list drop @<_each_block drop}

      # [list of things to act upon] {action to take on each list element} .each
      # [1 2 3] {print 32.emit} .each

# apply_each
def: "apply_each" [Coll, Coll] 
  {@>_each_block @>_each_list
    _each_list .len 0 .!= {     # iff
    { _each_block len  0 .> }
    { _each_list @<_each_block first* swap @>_each_block .each}  
  .while } .iff
  @<_each_list drop @<_each_block drop}

      # [list of things to act upon] [{action 1} {action 2} {action 3}] .apply_each
      # [1 2 3 4] [{print 32.emit} {dup .+ print 32.emit} {dup .* print 32.emit}] .apply_each

# apply_each_with
create_stack: "_each_with"

def: "apply_each_with" [Coll, Coll, Block]
  {@>_each_with @>_each_block @>_each_list
    { _each_block len  0 .> }
    { _each_list @<_each_block first* swap @>_each_block .each @!_each_with}  
  .while
  @<_each_list drop @<_each_block drop @<_each_with drop}

# map
create_stack: "_map_collect"

def: "map" [Coll, Block]
  { depth 2 .- @>_map_collect 
  .each
  depth @<_map_collect .- .enlist }

# times
def: "times" [Block, Int]
  {dup 0 .> 
    {1 .range swap \drop .prepend .each}
    {drop2} .if }

def: "times" [Int, Block]
  {swap dup 0 .>
    {1 .range swap \drop .prepend .each}
    {drop2} .if }

# times*
def: "times*" [Block, Int]    # leaves the counter on TOS for body to use
  {dup 0 .> 
    {1 .range swap .each}
    {drop2} .if }

def: "times*" [Int, Block]    # can work either way for convenience
  {swap dup 0 .>
    {1 .range swap .each}
    {drop2} .if }

# for
def: "for" [Coll, Block]    
  {@>_while_body .len* 3 .= if
  { first* swap first* @<_while_body swap .concat @>_while_body last \dup swap .concat @>_while_cond .eval 
  _while _end_loop_}
  {@<_while_body drop "for error: [{initial state}{incremental change}{halting condition}] expected but not found" set_err} _end_}

        # for: [{initial state}{incremental change}{halting condition}] {body to execute}

# reduce
create_stack: "_reduce_body"
create_stack: "_reduce_collect"

def: "reduce" [Coll Block]
  {@>_reduce_body @>_reduce_collect _reduce_body len 0 .= _reduce_collect len 0 .= .or .not {      # iff
    @<_reduce_collect first* @>_reduce_collect 
    { @<_reduce_collect swap _reduce_body eval @>_reduce_collect} .each } .iff
    @<_reduce_body drop @<_reduce_collect}

        # [list to be reduced] {reduction algorithm} .reduce
        # [1 2 3 4] {.+} .reduce --> 10

# filter
create_stack: "_filter_original"
create_stack: "_filter_final"

def: "filter" [Coll, Block]
  { [] @>_filter_final over @>_filter_original .map
  each {if 
    {@<_filter_original first* @<_filter_final swap .append @>_filter_final @>_filter_original}
    {@<_filter_original first* drop @>_filter_original}}
  @<_filter_original drop @<_filter_final}

        # [list to be filtered] {filtering function} .filter
        # [0 1 -2 3 -4 5 -6] {0 .<} .filter --> [-2 -4 -6]
        
# case
create_stack: "_case_item"
create_stack: "_case_list"

def: "case" [Any, Coll]
  { [{true}{_case_item >none}] .append    # add default case
  @>_case_list @>_case_item 
  {_case_list .len 0 .>}  # while
    {@<_case_list first* swap @>_case_list 
    .delist drop swap _case_item swap   # if
      {.eval break} {drop} .if} 
  .while _end_loop_  
  @<_case_item drop @<_case_list drop}

def: "case*" [Any, Coll]
  { [{true}{>none}] .append    # add default case
  @>_case_list @>_case_item 
  {_case_list .len 0 .>}  # while
    {@<_case_list first* swap @>_case_list 
    .delist drop swap _case_item swap   # if
      {_case_item swap .eval break} {drop} .if}
  .while _end_loop_  
  @<_case_item drop @<_case_list drop}

# match
def: "match" [Item, Coll]
  { over {_case_item >none} 2 .enlist .append   # add default case
  @>_case_list @>_case_item 
  {_case_list .len 0 .>}  # while
    {@<_case_list first* swap @>_case_list 
    .delist drop swap _case_item .==  # if
      {.eval break} {drop} .if}
  .while _end_loop_  
  @<_case_item drop @<_case_list drop}

def: "match*" [Item, Coll]
  { over {>none} 2 .enlist .append   # add default case
  @>_case_list @>_case_item 
  {_case_list .len 0 .>}  # while
    {@<_case_list first* swap @>_case_list 
    .delist drop swap _case_item .==  # if
      {_case_item swap .eval break} {drop} .if}
  .while _end_loop_  
  @<_case_item drop @<_case_list drop}

# dip & keep
create_stack: "_dipped"

# a b {commands} .dip --> a commands b
def: "dip" [Any, Any] {swap @>_dipped eval @<_dipped}

# a b {commands} .keep --> a b commands b
def: "keep" [Any, Any] {over @>_dipped eval @<_dipped}

# [1 2 3] <nth 2 --> [1 2] 3
def: "<nth" [Coll, Int] {.extract}
def: "<nth" [String, Int] {.extract}

# [1 2 3] >nth 2 42 --> [1 2 42]
def: ">nth" [Coll, Int, Any] {@>_dipped {.delete} .keep @<_dipped .insert}
def: ">nth" [String, Int, String] {@>_dipped {.delete} .keep @<_dipped .insert}
def: ">nth" [String, Int, Char] {@>_dipped {.delete} .keep @<_dipped .insert}

# i[1 2 3] >>nth 2 42 --> [1 2 42 3]
def: ">>nth" [Coll, Int, Any] {.insert}
def: ">>nth" [String, Int, String] {.insert}
def: ">>nth" [String, Int, Char] {.insert}

# end of system
   
  