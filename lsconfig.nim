## lsconfig
## Listack 0.4.0
import std/deques, std/tables, std/strutils, std/terminal, std/math
import lstypes, lstypehelpers, lstypeprint

const 
  uppers* = {'A'..'Z'}
  lowers* = {'a'..'z'}
  alphas* = uppers + lowers
  digits* = {'0'..'9'}
  alphaNums* = alphas + digits + {'_'}
  symbols* = { '!', '~', '$', '%', '^', '&', '*', '-', '_', '+', '=', '<', '>', '?', '/'}
  delim* = {',', '"', '\'', '`', '[', ']', '{', '}', '(', ')', '|', '\\', '#', ';', '.', ':'}
  whiteComma* = Whitespace + {','}
  wordSuffixes* = {':', ';'}                            # prefix, namespace
  wordPrefixes* = {'\\', '@', '.'}                      # defer, function, postfix
  functionChars* = {'<', '>', '!', '*', '?', '/', '#', '%'}  # @ get(pop), set(push), call, show, depth, clear, meta-standard, meta-expand
  wordStart* = lowers + uppers + symbols
  wordAllowed* = wordstart + digits
  wordEndings* = ["<|", "$)"]

var
  immediates* = @["pick", "roll",
    "dup", "drop", "swap", "over", "nip", "tuck",  
    "rot_r", "rot_l", "reverse", "clear",
    "depth", "dump", "defer", "save_stack", "restore_stack", "copy_stack",
    "false", "true", "|>", "<|", "_begin_loop_", "_end_loop_", "_end_", "nop", "break", "continue", "exit", "halt", "fail", 
    "enlist_all", "get_line", "get_char", "get_char_silent", "nil", "_reset_namespace", 
    "Null", "Bool", "Char", "String", "Word", "Int", "Float", "Block", "List", "Seq", "Object", 
    "...", "..<", "\\"]

proc wordVerify*(candidate: string): bool = 
  if len(candidate) == 0:
    return false
  var thing = candidate & "  "
  var buildWord, checkEnd = ""
  var doneBuilding = false
  var here = 0
  var thisChar = thing[here]
  var isSymbol = thisChar in (symbols - {'_'})
  while isSymbol and thisChar in symbols - {'_'}:    # symbols only
    checkEnd = thisChar & thing[here+1]
    if checkEnd in wordEndings: 
      doneBuilding = true
      break
    buildWord.add thisChar
    inc here
    thisChar = thing[here]
    if thisChar in alphas + {'_'}:
      isSymbol = false
  if (not doneBuilding) and (not isSymbol):
    while thisChar in wordAllowed :
      checkEnd = thisChar & thing[here+1]
      if checkEnd in wordEndings: 
        doneBuilding = true
        break
      else:
        buildWord.add thisChar
        inc here
        thisChar = thing[here]
  if buildWord != candidate:
    echo("\nwordVerify fail: ", buildword, " is not ", candidate)
  return buildWord == candidate

proc initEnvironment*(isdebug: bool = false, isverbose: bool = false, isSilent: bool = false): Environment =
  var localStack = initOrderedTable[string, LsNode]()
  for c in lowers:
    localStack[$c] = newNullNode(true)    # none
  var globalStack = initOrderedTable[string, LsSeq]()
  for c in uppers:
    globalStack[$c] = newLsSeq(8)
  var pastStack:seq[LsSeq] = @[newLsSeq()]
  var futureStack = newLsSeq()
  var namespc: NameSpace
  var funcor: FunCore
  var funcvar: FuncVars
  var funcobj: FuncObj
  funcobj = FuncObj(args: @[], cmd: newNullNode())
  funcvar = FuncVars(count: 0)
  funcvar.variant.add(funcobj)
  funcor["nil"] = funcvar
  namespc["default"] = funcor
  var environ = Environment(future: futureStack, current: newNullNode(), past: pastStack, locals: @[localStack], globals: globalStack, currentNameSpace: "default", nameSpace: namespc, debug: isdebug, verbose: isverbose, silent: isSilent)
  return environ

var core*: Core

proc handleError*(env: var Environment,  message: string, thing: LsNode)=
  env.errors.add((message, env.current, thing))
  if env.debug or env.verbose:
    stdout.styledWrite("\n", bgRed, "err")
    echo ": ", message, "  "
    prettyPrint(thing)
    stdout.writeLine("")
    prettyPrint(env.current)
    echo " in '", env.current.wordSource, "' at line ", env.current.wordLine, ", column ", env.current.wordColumn

proc mappedTypeCheck*(env: var Environment, passedFormal: string, passedActual: LsNode): bool =
  if typeMap.hasKey(passedFormal):
    return passedActual.nodeType in typeMap[passedFormal]
  else:
    if passedFormal != "Otherwise":
      handleError(env, "Type not found: " & passedFormal, passedActual)
    return false

proc floatVerify*(env: var Environment, thing: LsNode): bool =
  result = true
  if thing.nodeType == Float:
    if (thing.floatVal.isNaN()) or (thing.floatVal == Inf) or (thing.floatVal == NegInf):
      let msg = "Improper float value, out of range: " &  $thing.floatVal
      handleError(env, msg, thing)
      result = false
  else:
    let msg = "Error: not a float: " &  $thing
    handleError(env, msg, thing)
    result = false
  return result

proc floatVerify*(env: var Environment, thing: float): bool =
  result = true
  if (thing.isNaN()) or (thing == Inf) or (thing == NegInf):
    let msg = "Improper float value, out of range: " &  $thing
    handleError(env, msg, env.current)
    result = false
  return result

proc checkInvalid*(this: LsNode): bool =
  result = this.invalid
  if this.nodeType in typeMap["Coll"]:
    if len(this.seqVal) > 0:
      for item in this.seqVal:
        result = result or checkInvalid(item)
  elif this.nodeType == Object:
    result = result or checkInvalid(this.objectVal)
  return result

proc checkInvalid*(env: var Environment, howMany: int): bool =
  result = false
  if howMany > 0:
    if howMany <= len(env.past[^1]):
      for count in 1..howMany:
        result = result or checkInvalid(env.past[^1][^count])
    else:
      result = true
      handleError(env, "Attempted to verify " & $howMany & " items, but found only " &  $len(env.past[^1]) & " on the stack", env.current)
  return result

proc setInvalid*(env: var Environment, invalid: bool = false) = 
  if len(env.past[^1]) > 0:
    env.past[^1][^1].invalid = env.past[^1][^1].invalid or invalid
  else:
    handleError(env, "Cannot set validity of nothing", env.current)

when isMainModule:
  let env = initEnvironment()
  echo env.currentNameSpace

## lsconfig
## Listack 0.4.0
## Language:  Nim 1.6.12, Linux formatted
## Copyright (c) 2023, Charles Fout
## All rights reserved.
## May be freely redistributed and used with attribution under GPL3.