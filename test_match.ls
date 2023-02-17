"generics" .load

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
        \ .== .append swap                           # add ".==" to the end of condition
        .iff}                                       # --> object {condition .=} {body break} .iff
    pop_p drop pop_o drop                           # reset side stacks
}     # prototype

cr
3 {.print sp} .times*  cr println:"Beginning key_3"
cr
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

dump
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
dump
cr

err_msg:"reduce test"
[1,2,3,4,5]{.+}.reduce.println
[1] {.+} .reduce .println
[]{.+}.reduce .println
[]{}.reduce.println
[1 2 3]{}.reduce.println
[1 2 3] {.print sp} .reduce .println
cr cr
err_msg:"range test"
1 10 .range .println
10 1 .range .println
"a" "z" .range .println
range: "z" "a" .println
" " range "z" .println
1 .. 10 .print
"d" .. 'a' .println
cr
dump
cr
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

dump

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

 println:"match* test"
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

cr
err_msg:"Sorting test"

print:"Sorting:" [5 1 4 2 3] dup .println
print:"Sorted: " .sort .println
print:"Sorting:" [a k aa e m d aaa p str] dup .println
print:"Sorted: " .sort .println



err_msg:"Zip test"
cr
println:"Zip test"

[1 2 3] [a b c] .zip .println
{4 5.0 6} zip ["d" e "f" g h] .println_quote
[7 8 9] zip {} .println
[1 2 3 4][a b c d] .zip dup .print print:" --> " .unzip swap .print .println
[1 2 3 4][a b c d e] .zip "f" .append dup .print print:" --> " .unzip swap .print .println
unzip: ([1 a] [2 b] [3 c] [(4 d)(5 e)] [6 7 f g] 8 h ) swap .print sp .println
println:"Unzip test complete"
cr


[1 2 3 4 5] {.first* .print sp} until {.len = 0} drop
cr
"test1" ".println" .exec
{.println} "delayed_print" .init
"test2" delayed_print .exec
delayed_print dup .print " = ".print !delayed_print
cr

{print:"Type a number (0 to quit): " get_line
    .valid_num? if {
        .str>num dup dup
            <=>
            {.print println:" is Negative"}
            {.print println:" is Zero"}
            {.print println:" is Positive"}
    }
    else {dup .print_quote println:" is not a number!"}
} until {0 .=}

-2.5 1 ./% swap .print sp .println

34 .str>num .print_quote sp
"3.14159" .str>num .println_quote

cr

"Stress testing scope rules" dup .println .err_msg
3.14 True|>False|>"|>"<|<|
dump clear cr
1..30 .delist|> dump A .print sp Z .println<| dump cr
4times(drop)True|>dump A.print sp Z.println<|dump cr        # deliberate obfuscation to stress test parser
False|>dump A .print sp Z .println 26 (drop) .times<| dump cr


err_msg:"Test of fail/halt"
# fail
halt
println:"After halt?"
