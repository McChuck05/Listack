# Listack
Listack: a symmetric, stackless, stack-based, concatenative  language

Listack is an experiment in making a symmetric, stackless, stack-based, concatenative language. Listack was inspired by both Factor and Falsish , which is itself a variant of False inspired by fish ><>.  The user-defined type system was inspired by Euphoria.

Listack is symmetric in that most command words are available in a prefix, infix, and postfix form. The user can choose which forms to use, and can thus mimic Lisp (prefix), Forth (postfix), or use a mix of all three forms in the style of most imperative languages. The prefix and infix forms are automatically created from the base postfix form depending on the number of arguments the word has. 

Listack is stackless in that the implementation splits the difference between a Turing machine and the lambda calculus, with a stack for past data, the current command, and then a queue for future commands. Commands are read from the front of the queue, and the data computed by these commands is pushed onto the stack, creating, in effect, an infinite tape. As such, the language is implemented as a simple loop with no recursion and no return stack. Invocations of functions ("words") merely place the function definition on the front of the command queue. Loops are implemented by repeatedly pushing the body of the loop back onto the front of the command queue. There is no call, no return, no goto, no instruction pointer, only adding words to the front of the command queue.  All functions are inline functions.

Concatenative languages, which are normally stack-based, are similar to many functional languages in that function composition is accomplished by typing one command after another. The output from one word is the input to the next word via the data stack, much like the unix pipe ("|") command.

Listack is a portmanteau of List and Stack based programming. It was created by Charles Fout and originally implemented in Python 3.10 in January 2023.

The current version is Listack v0.4.0.6, 13 June 2023, written in Nim 1.6.12.
What's new:  Simplified type system, added user-customizable combined types.

Invoke with:  ./listack code_file_to_run.ls
or use the interactive repl:  ./listack
options: -debug -verbose


https://esolangs.org/wiki/Listack
