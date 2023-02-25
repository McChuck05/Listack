# assoc test
"generics".load


2 if: (0 .>)("True".println)("False".println)
-2 (0 .>) if ("True".println)("False".println)
2 (0 .>) {"True".println}{"False".println}.if
dump
cr
5 if*: (0 .>)(.print sp "True".println) ("False".println)
-5 (0 .>) if* (.print sp "True".println) ("False".println)
5 (0 .>)(.print sp "True".println)("False".println).if*
dump
cr
1 iff: (0 .>)("Exactly true".println)
-1 (0 .>)iff ("Exactly true".println)
1 (0 .>)("Exactly true".println).iff
dump
cr
5 iff*: (0 .>)(.print sp "Exactly true".println)
-5 (0 .>) iff* (.print sp "Exactly true".println)
5 (0 .>)(.print sp "Exactly true".println).iff*
dump
cr

<=>: 3 ("Negative".println)("Zero".println)("Positive".println)
0 <=> ("Negative".println)("Zero".println)("Positive".println)
-3 ("Negative".println)("Zero".println)("Positive".println) .<=>
cr

3 times (print:"Beetlejuice! ") cr
(1 2 3) (.len > 0) while (.first* .print sp) drop cr
(1 2 3) (.len > 0) (.first* .print sp).while drop cr
(4 5 6) (.print sp) .each cr
(4 5 6)each(.print sp) cr

"Level 0 " "level" .init
"0: ".print level .println
0 |> "Level 1 " "level" .init
"1: ".print level .println
0 |>
"2: " .print level .println <|
"1: " .print level .println <|
"0: " .print level .println

\.println ".my_println" .def
"Finished!".my_println
