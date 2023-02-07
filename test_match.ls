"generics.ls" .load

def: ".mat" {
[{dup dup}{" not matched: ".print}] .append        # add a default condition body pair to the list

    push_p, push_o                                  # o = object, p = condition-body pair list
    {pop_p .len 0 .>} while                         # while there are any condition-body pairs left
    { .first* swap push_p                           # extract first condition-body pair, store reduced list
        copy_o swap .delist drop                    # --> object {condition} {body}
        \ break .concat .list>block                 # add "break" to the end of body
        swap \ .= .concat .list>block swap          # add ".=" to the end of condition
        .iff}                                       # --> object {condition .=} {body break} .iff
    pop_p drop pop_o drop                           # reset side stacks
}     # prototype

[
[1 "one"]
[2 "two"]
[3 "three"]
[True "True?"]
[[True] "[True?]"]
] "match_1" .init

cr println:"Beginning mat_1"
print:"4: " 4 match_1 .mat .println
print:"3: " 3 match_1 .mat .println
print:"2: " 2 match_1 .mat .println
print:"1: " 1 match_1 .mat .println
print:"0 (no match, default): " 0 match_1 .mat .println
cr
print:"True: " True match_1 .mat .println
print:"[False]: " [False] match_1 .mat .println
print:"[True]: " [True] match_1 .mat .println
print:"{True}: " {True} match_1 .mat .println

[
[1 "one"]
[2 "two"]
[3 "three"]
[True "True?"]
[[True] "[True?]"]
[dup "User default"]
] "match_2" .init

cr println:"Beginning mat_2"
print:"4: " 4 match_2 .mat .println
print:"3: " 3 match_2 .mat .println
print:"2: " 2 match_2 .mat .println
print:"1: " 1 match_2 .mat .println
print:"0 (no match, default): " 0 match_2 .mat .println
10 .emit
print:"True: " True match_2 .mat .println
print:"[False]: " [False] match_2 .mat .println
print:"[True]: " [True] match_2 .mat .println
print:"{True}: " {True} match_2 .mat .println

4 [1 .=] [println:"4 [=] 1"] .iff drop      # a non-empty list evaluates to True, the 4 is not used
3 {1 .=} {println:"3 {=} 1"} {println:"3 {~=} 1"} .if

[
[1 "one"]
[2 "two"]
[3 "three"]
[4 "four"]
[True "True?"]
[[True] "[True?]"]
[dup "default"]
] "match_3" .init

cr println:"Beginning match_3"
print:"4: " 4 match_3 .match  .println
print:"3: " 3 match_3 .match .println
print:"2: " 2 match_3 .match .println
print:"1: " 1 match_3 .match .println
print:"0 (no match, default): " 0 match_3 .match .println
dump
10 .emit
print:"True: " True match_3 .match .println
print:"[]: " [] match_3 .match .println
print:"[False]: " [False] match_3 .match .println
print:"[True]: " [True] match_3 .match .println
print:"{True}: " {True} match_3 .match .println
dump
println:"match_3 finished!"

cr

1 2 3.0 "happy!" [] True .concat concat \ break dump clear

# 1 2 3.0 "This is an error".println]                                          ###### parsing error test

def: "key" {

[{dup dup}{.print " not matched!".println}] .append        # add a default condition-body pair to the list
    push_p, push_o                                  # (A)p = object, (B)o = condition-body list
    {pop_p .len 0 .>} while                         # while there are any condition-body pairs left
    { .first* swap push_p                        # extract first condition-body pair, store reduced list
        copy_o swap .delist drop                    # --> object {condition} {body}
        .type BLOCK .~=               # swap "LIST" .= .or .not
            { {} swap .append} .iff
        \ break .append                             # add "break" to the end of body
        swap
        .type BLOCK .~=           # swap "LIST" .= .or .not
            { {} swap .append} .iff
        \ .= .append swap                           # add ".=" to the end of condition
        .iff}                                       # --> object {condition .=} {body break} .iff
    pop_p drop pop_o drop                           # reset side stacks
}     # prototype

5 {cr} .times  println:"Beginning key_3"
print:"4: " 4 match_3 key  .println
print:"3: " 3 match_3 key .println
print:"2: " 2 match_3 key .println
print:"1: " 1 match_3 key .println
print:"0 (no match, default): " 0 match_3 key .println
dump
10 .emit
print:"True: " True match_3 key .println
print:"[]: " [] match_3 key .println
print:"[False]: " [False] match_3 key .println
print:"[True]: " [True] match_3 key .println
print:"{True}: " {True} match_3 key .println
dump
println:"key_3 finished!"

cr

"Join " join "test 1" .println
"Join" .str>word " test 2" .join .println
join: \Join " test 3" .println
join: \ JOIN " test 4" .println 10

cr

[" work? ", "34", " 867.5309 ", "-34", "-3.14159 ", "/%", ' \ ' ".2" "3." ".command" "command:", "", "True"] {.str>word dup .print_quote sp .type .println} .each
cr

1 2 3 # just to have something on the stack
# println:"This should fail:"

# "two words" .str>word
# checking parser
123.45 0.123 123.0 123. 456 [123.] clear
["123", "123.45", "456.", ".456"] {.str>num .print sp} .each
cr
[1,2,3,4,5]{.+}.reduce.println
[1] {.+} .reduce .println
[]{.+}.reduce .println
[]{}.reduce.println
[1 2 3]{}.reduce.println
[1 2 3] {.print sp} .reduce .println
1 10 .range .println
10 1 .range .println
"a" "z" .range .println
range: "z" "a" .println
" " range "z" .println
1 .. 10 .print
"d" .. 'a' .println

println:"Fibonacci test"

def: "simple_fib" {0 swap times* {.+}}

5 simple_fib .println  # --> 15

def:".fib" {.type = "INT"
    if {dup > 0
        if {simple_fib.println}
        else {drop 0.println}}
    else {print:"fib error: " .print_quote " is not an integer".println}}

def: "fib:" {\ .fib _ins_f1}   # '\' pushes the next command word to the stack

 10 .fib # --> 55
 fib: 12 # --> 78
 -2.fib # --> 0
 fib:"abc"



 1 < 2 .print sp "d" < 'a' .println
 0 3. .5 .range_by .println_quote
 range_by:1-4-.75.println
 0 10 range_by 2  .println

# 'a' .. 10 .print cr                                                              ####### range error test

cr
 println:"case* test"
 [
 [{= 1}{.print sp}]
 [{= 2}{.print sp}]
 [{= 3}{.print sp}]
 [{True}{print:"not found: ".println drop}]
 ] "case4" .init

 1 case* case4 cr
 2 case* case4 cr
 3 case* case4 cr
 4 case* case4 cr

 println:"case* test 2"
 [
 [{= 1}{.print sp}]
 [{= 2}{.print sp}]
 [{= 3}{.print sp}]
 # no user default
 ] "case5" .init

 1 case* case5 cr
 2 case* case5 cr
 3 case* case5 cr
 4 case* case5 cr

 println:"match*test"
 [
 [1 {.print sp}]
 [2 {.print sp}]
 [3 {.print sp}]
 [dup {print:"not found: ".println}]
 ] "match4" .init

 1 match* match4 cr
 2 match* match4 cr
 3 match* match4 cr
 4 match* match4 cr


print:"Sorting:" [5 1 4 2 3] dup .println
print:"Sorted: " .sort .println
print:"Sorting:" [a k aa e m d aaa p str] dup .println
print:"Sorted: " .sort .println


[1 2 3] [a b c] .zip .println
{4 5.0 6} zip ["d" e "f" g h] .println_quote
[7 8 9] zip {} .println
[1 2 3 4][a b c d] .zip dup .print print:" --> " .unzip swap .print .println
[1 2 3 4][a b c d e] .zip "f" .append dup .print print:" --> " .unzip swap .print .println
unzip: [[1 a] [2 b] [3 c] [[4 d][5 e]] [6 7 f g] 8 h ] swap .print .println


[1 2 3 4 5] {.first* .print sp} until {.len = 0} drop

"test1" ".println" .exec
{.println} "delayed_print" .init
"test2" delayed_print .exec
delayed_print dup .print " = ".print !delayed_print


{print:"Type a number (0 to quit): " get_line
    .valid_num? if {
        .str>num dup dup
            <=>
            {.print println:" is Positive"}
            {.print println:" is Zero"}
            {.print println:"is Negative"}
    }
    else {dup .print_quote println:" is not a number!"}
} until {0 .=}


\abc "abc" dump 2dup
.= print:" = ? ".println
.== print:" == ? ".println

err_msg:"This used to be a deliberate error"
34 .str>num .print
