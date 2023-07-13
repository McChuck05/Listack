# Listack
Listack: a symmetric, stackless, polymorphic, concatenative language

Listack is an experiment in making a symmetric, stackless, polymorphic, concatenative language. Listack was inspired by Factor, False, and fish ><>.  The user-defined type system was inspired by Euphoria.

Listack is symmetric in that most command words are available in a prefix, infix, and postfix form. The user can choose which forms to use, and can thus mimic Lisp (prefix), Forth (postfix), or use a mix of all three forms in the style of most imperative languages. The prefix and infix forms are automatically created from the base postfix form depending on the number of arguments the word has. The following are all equivalent, valid constructs:

    1+2
    +:1 2
    1 2.+
    +(1,2)

Listack is stackless in that all functions are inline functions.  The implementation splits the difference between a Turing machine and the lambda calculus, with a stack for past data, the current command, and then a queue for future commands. Commands are read from the front of the queue, and the data computed by these commands is pushed onto the stack, creating, in effect, an infinite tape. As such, the language is implemented as a simple loop with no recursion and no return stack. Invocations of functions ("words") merely place the function definition on the front of the command queue. Loops are implemented by repeatedly copying the body of the loop back onto the front of the command queue. There is no call, no return, no goto, no instruction pointer, only adding words to the front of the command queue.

Listack is fully polymorphic within the restriction of maintaining arity (the number of arguments to a function).  For example, '+' works with two integers, floats, mixed numbers, numbers and blocks, strings, characters, strings and characters, or characters and integers.  A namespace system is used to separate functions with similar names but different meanings or arities.  "Otherwise" is a catch-all type.

Concatenative languages, which are normally stack-based, are functional languages, where function composition is accomplished by simply typing one command after another. The output from one word is the input to the next word via the data stack, much like the unix pipe ("|") command.  Functions are first class data constructs (data are functions and functions are data), and anonymous functions (quotations/blocks) are the heart of the system.  Listack is an "impure" functional language, because side effects are readily available.  (Note that alterations to the data stack do not count as side effects, so your code can be as "pure" as you want it to be.)

Listack is a portmanteau of List and Stack based programming. It was created by Charles Fout and originally implemented in Python 3.10 in January 2023.

The current version is Listack v0.4.0.8, 21 June 2023, written in Nim 1.6.12.

Invoke with:  
  ./listack code_file_to_run.ls  
options: -debug -verbose

Or use the interactive repl:    
  ./listack


https://esolangs.org/wiki/Listack

https://concatenative.org/wiki/view/Listack
