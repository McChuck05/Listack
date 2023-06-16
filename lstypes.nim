import std/deques, std/tables

type
  LsTypeError* = object of CatchableError

  LsType* = enum
    Null, 
    Bool, 
    Char, String, Word, 
    Int, Float, 
    Block,  # {words words words}         sequence of code. Only blocks are unpacked for execution when called as functions.
    List,   # [values, values, values]    sequence of data.
    Seq,   # (words values items)        a sequence is immediately unpacked when executed. *use sparingly*  fix makes a real difference!
    Object # ($ {type} [args] [value] $)     object creator.  Type is a function to check value with.  Args are supplamental storage.

var typeMap*: Table[string, set[LsType]]
typeMap["Null"] = {Null}
typeMap["Bool"] = {Bool}
typeMap["Char"] = {Char}
typeMap["String"] = {String}
typeMap["Word"] = {Word}
typeMap["Int"] = {Int}
typeMap["Float"] = {Float}
typeMap["Block"] = {Block}
typeMap["List"] = {List}
typeMap["Seq"] = {Seq}
typeMap["Object"] = {Object}
typeMap["Item"] = {Bool, Char, String, Word, Int, Float, Object}
typeMap["Coll"] = {Block, List, Seq}
typeMap["Num"] = {Int, Float}
typeMap["Alpha"] = {Char, String, Word}
typeMap["Alphanum"] = {Char, String, Word, Int, Float}
typeMap["Wordy"] = {String, Word}
typeMap["Blocky"] = {Block, Seq}
typeMap["Listy"] = {List, Block}
typeMap["Executable"] = {Word, Block, Seq}
typeMap["Any"] = {Null, Bool, Char, String, Word, Int, Float, Object, Block, List, Seq}
 
var sugar* = @["then", "else", "do", "of"]

type
  LsFix* = enum
    Prefix, Infix, Postfix, Immediate

  LsSeq* = Deque[LsNode]

  LsNode* = ref LsObj

  LsObj* = object
    deferred*: bool
    invalid*: bool  # use for some/none
    case nodeType*: LsType
    of Char: charVal*: char
    of String: stringVal*: string
    of Word:
      wordVal*: string
      wordFix*: LsFix
      wordFunc*: char   # @ functionChars '<' get, '>' set, '!' call, '#' meta add, '%' meta expand, '?' depth, '/' clear
      wordNameSpace*: string
      wordLine*: Natural   # source line number
      wordColumn*: Natural    # source column number
      wordSource* : string
    of Int: intVal*: int64
    of Float: floatVal*: float64
    of Bool: boolVal*: bool
    of Block, List, Seq: seqVal*: LsSeq
    of Object:
      objectType*: string # was LsSeq
      objectArgs*: LsSeq
      objectVal*: LsNode
    of Null: discard


type 
  FuncObj* = ref object 
    args*: seq[string]
    cmd*: LsNode

  FuncVars* = ref object
    count*: int
    variant*: seq[FuncObj]

  FunCore* = Table[string, FuncVars]

  NameSpace* = Table[string, FunCore]

type
  Environment* = ref object
    future*: LsSeq
    current*: LsNode
    past*: seq[LsSeq]
    locals*: seq[OrderedTable[string, LsNode]]
    globals*: OrderedTable[string, LsSeq]
    nameSpace*: NameSpace
    currentNameSpace*: string
    errors*: seq[(string, LsNode, LsNode)]
    debug*, verbose*, silent*, fail*: bool

type
  CoreObj* = ref object
    args*: seq[string]
    cmd*: proc(env: var Environment)

  CoreVars* = ref object
    count*: int
    variant*: seq[CoreObj]

  Core* = Table[string, CoreVars]


when isMainModule:
  discard

## Listack 0.4.0 Types
## Copyright (c) 2023, Charles Fout
## All rights reserved.
## Language:  Nim 1.6.12, Linux formatted
## May be freely redistributed and used with attribution under GPL3.