## lscore
## Listack 0.4.0

import std/deques, std/tables, std/strutils 
import lstypes, lstypeprint, lstypehelpers, lsconfig
# import os, std/sequtils, std/terminal
# import lsparser

when isMainModule:
  var env = initEnvironment()

core["dup"] = CoreVars(count: -1)   # a b c dup --> a b c c
proc doDup*(env: var Environment) =
  env.past[^1].addLast(deepCopy(env.past[^1][^1]))
core["dup"].variant.add(CoreObj(args: @["Any"], cmd: doDup))

core["dup2"] = CoreVars(count: -2)   # a b c dup2 --> a b c b c
proc doDupTwo*(env: var Environment) =
  env.past[^1].addLast(deepCopy(env.past[^1][^2]))
  env.past[^1].addLast(deepCopy(env.past[^1][^2]))
core["dup2"].variant.add(CoreObj(args: @["Any", "Any"], cmd: doDupTwo))

core["drop"] = CoreVars(count: -1)  # a b c drop --> a b
proc doDrop*(env: var Environment) =
  env.past[^1].shrink(fromLast = 1)
core["drop"].variant.add(CoreObj(args: @["Any"], cmd: doDrop))

core["drop2"] = CoreVars(count: -2)  # a b c drop2 --> a
proc doDropTwo*(env: var Environment) =
  env.past[^1].shrink(fromLast = 2)
core["drop2"].variant.add(CoreObj(args: @["Any", "Any"], cmd: doDropTwo))

core["swap"] = CoreVars(count: -2)  # a b c swap --> a c b
proc doSwap*(env: var Environment) =
  let c = env.past[^1].popLast()
  let b = env.past[^1].popLast()
  env.past[^1].addLast(c)
  env.past[^1].addLast(b)
core["swap"].variant.add(CoreObj(args: @["Any", "Any"], cmd: doSwap))

core["over"] = CoreVars(count: -2)  # a b c over --> a b c b
proc doOVer*(env: var Environment) =
  env.past[^1].addLast(deepCopy(env.past[^1][^2]))
core["over"].variant.add(CoreObj(args: @["Any", "Any"], cmd: doOver))

core["over2"] = CoreVars(count: -3)  # a b c over2 --> a b c a b
proc doOVerTwo*(env: var Environment) =
  env.past[^1].addLast(deepCopy(env.past[^1][^3]))
  env.past[^1].addLast(deepCopy(env.past[^1][^3]))
core["over2"].variant.add(CoreObj(args: @["Any", "Any"], cmd: doOverTwo))

core["nip"] = CoreVars(count: -2)   # a b c nip --> a c
proc doNip*(env: var Environment) =
  let c = env.past[^1].popLast()
  env.past[^1].shrink(fromLast = 1)
  env.past[^1].addLast(c)
core["nip"].variant.add(CoreObj(args: @["Any", "Any"], cmd: doNip))

core["nip2"] = CoreVars(count: -3)   # a b c nip2 --> c
proc doNipTwo*(env: var Environment) =
  let c = env.past[^1].popLast()
  env.past[^1].shrink(fromLast = 2)
  env.past[^1].addLast(c)
core["nip2"].variant.add(CoreObj(args: @["Any", "Any", "Any"], cmd: doNipTwo))

core["tuck"] = CoreVars(count: -2)  # a b c tuck -->  a c b c
proc doTuck*(env: var Environment) =
  let c = env.past[^1].popLast()
  let b = env.past[^1].popLast()
  env.past[^1].addLast(deepCopy(c))
  env.past[^1].addLast(b)
  env.past[^1].addLast(c)
core["tuck"].variant.add(CoreObj(args: @["Any", "Any"], cmd: doTuck))

core["pick"] = CoreVars(count: -3)  # a b c pick --> a b c a
proc doPick*(env: var Environment) =
  env.past[^1].addLast(deepCopy(env.past[^1][^3]))
core["pick"].variant.add(CoreObj(args: @["Any", "Any", "Any"], cmd: doPick))

core["roll"] = CoreVars(count: -3)  # a b c roll --> b c a
proc doRoll*(env: var Environment) =
  env.past[^1].addLast(deepCopy(env.past[^1][^3]))
  delFromRight(env.past[^1], 3)
core["roll"].variant.add(CoreObj(args: @["Any", "Any", "Any"], cmd: doRoll))

core["rot_r"] = CoreVars(count: -1)
proc doRotR*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast().intVal
  rollRight(env.past[^1], a)
  setInvalid(env, invalid)
core["rot_r"].variant.add(CoreObj(args: @[""], cmd: doRotR))

core["rot_l"] = CoreVars(count: -1)
proc doRotL*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast().intVal
  rollLeft(env.past[^1], a)
  setInvalid(env, invalid)
core["rot_l"].variant.add(CoreObj(args: @[""], cmd: doRotL))

core["reverse_stack"] = CoreVars(count: 0)
proc doReverseStack*(env: var Environment) =
  var revSeq = env.past[^1].reversed()
  env.past[^1] = revSeq
core["reverse_stack"].variant.add(CoreObj(args: @[], cmd: doReverseStack))

core["clear"] = CoreVars(count: 0)
proc doClear*(env: var Environment) =
  env.past[^1].clear
core["clear"].variant.add(CoreObj(args: @[], cmd: doClear))

core["depth"] = CoreVars(count: 0)
proc doDepth*(env: var Environment) =
  env.past[^1].addLast(newIntNode(len(env.past[^1])))
core["depth"].variant.add(CoreObj(args: @[], cmd: doDepth))

core["dump"] = CoreVars(count: 0)
proc doDump*(env: var Environment) =
  prettyPrintLn(env.past[^1])
core["dump"].variant.add(CoreObj(args: @[], cmd: doDump))

core["save_stack"] = CoreVars(count: 0)
proc doSaveStack*(env: var Environment) =
  env.past.add(newLsSeq())
core["save_stack"].variant.add(CoreObj(args: @[], cmd: doSaveStack))

core["restore_stack"] = CoreVars(count: 0)
proc doRestoreStack*(env: var Environment) =
  if len(env.past) > 1:
    discard env.past.pop()
  else: 
    let errmsg = "Attempt to restore unsaved stack.  Clearing stack instead."
    handleError(env, errmsg, env.current)
    env.past[0].clear
core["restore_stack"].variant.add(CoreObj(args: @[], cmd: doRestoreStack))

core["copy_stack"] = CoreVars(count: 0)
proc doCopyStack*(env: var Environment) =
  var newStack: LsSeq = deepCopy(env.past[^1])
  env.past.add(newStack)
core["copy_stack"].variant.add(CoreObj(args: @[], cmd: doCopyStack))

core["|>"] = CoreVars(count: -1)   # n |>     removes |n| items from the previous stack
proc doOpenScope*(env: var Environment) =   # create new variable scope and a new stack
  if checkInvalid(env, 1):
    handleError(env, "Opening scope with invalid integer", env.past[^1][^1])
  let howMany = env.past[^1].popLast().intVal  
  var localStack = initOrderedTable[string, LsNode]()
  var tempStack = newLsSeq()
  let offset = max(abs(howmany) - 26, 0)
  for c in lowers:
    localStack[$c] = newNullNode(true)    # none
  for i in 0 ..< abs(howMany):        # copy |n| items to the variables a..n
    tempStack.addFirst(env.past[^1].popLast())
  for i in 0 ..< min(abs(howMany), 26):   # only 26 letters available
    localStack[$(char(ord('a') + i))] = tempStack[i + offset]   # offset in case more than 26 items copied from stack
  env.locals.add(localStack)
  env.past.add(newLsSeq())
  if howMany > 0:   # if howMany is positive, add entries to the new stack (if negative, don't copy them onto the new stack)
    for item in tempStack:
      addLast(env.past[^1], item)
core["|>"].variant.add(CoreObj(args: @["Int"], cmd: doOpenScope)) 

proc doOpenScopeB*(env: var Environment) =    # bool |>    as n |> above, but copies entire previous stack to the new stack 
  if checkInvalid(env, 1):
    handleError(env, "Opening scope with invalid boolean", env.past[^1][^1])
  let preserve = env.past[^1].popLast().boolVal     # true --> preserves previous stack
  let howMany = len(env.past[^1])                   # false --> clears previous stack
  var localStack = initOrderedTable[string, LsNode]()
  var tempStack = newLsSeq()
  let offset = max(howmany - 26, 0)
  for i in 0 ..< howMany:   
    tempStack.addLast(deepCopy(env.past[^1][i]))
  for c in lowers:    
    localStack[$c] = newNullNode(true)      # none
  if not preserve:    # clear old stack
    env.past[^1].clear()
  for i in 0 ..< min(howMany, 26):   # only 26 letters available
    localStack[$(char(ord('a') + i))] = tempStack[i + offset]
  env.locals.add(localStack)
  env.past.add(newLsSeq())
  for item in tempStack:
    addLast(env.past[^1], item)
core["|>"].variant.add(CoreObj(args: @["Bool"], cmd: doOpenScopeB))

core["<|"] = CoreVars(count: 0)     # drop the current variable scope, pop current stack, moving all items to previous stack
proc doCloseScope*(env: var Environment) =
  let howMany = len(env.past[^1])
  if len(env.past) > 1:
    for i in 1..howMany:
      env.past[^2].addLast(env.past[^1].popFirst())
    discard env.past.pop()
    discard env.locals.pop()
  else:
    let errmsg = "Attempt to close unopened scope.  Clearing stack instead."
    handleError(env, errmsg, env.current)
    env.past[0].clear()
core["<|"].variant.add(CoreObj(args: @[], cmd: doCloseScope)) 

core["eval"] = CoreVars(count: 1)
proc doEval*(env: var Environment) =
  var item = env.past[^1].popLast()
  item.deferred = false
  env.future.growLeft(item)
core["eval"].variant.add(CoreObj(args: @["Any"], cmd: doEval))

core["if"] = CoreVars(count: 3)
proc doIfBool*(env: var Environment) =  # bool if {do if true} {do if false} 
  var falsePart = env.past[^1].popLast()
  var truePart = env.past[^1].popLast()
  var invalid = checkInvalid(env, 1)
  let boolPart = env.past[^1].popLast().boolVal
  if boolPart:
    truePart.invalid = truePart.invalid or invalid
    env.future.growLeft(truepart)
  else:
    falsePart.invalid = falsePart.invalid or invalid
    env.future.growLeft(falsePart)
core["if"].variant.add(CoreObj(args: @["Bool", "Any", "Any"], cmd: doIfBool))

proc doIfBlock*(env: var Environment) =   # {condition} {do if true} {do if false} .if
  env.future.addFirst(env.current)            # .if
  env.future.addFirst(env.past[^1].popLast)   # false part
  env.future.addFirst(env.past[^1].popLast)   # true part
  env.future.growLeft(env.past[^1].popLast()) # condition block
core["if"].variant.add(CoreObj(args: @["Blocky", "Any", "Any"], cmd: doIfBlock))

proc doIfOtherwise*(env: var Environment) = # discard blocks
  discard env.past[^1].popLast()  # false part
  discard env.past[^1].popLast()  # true part
  let badpart = env.past[^1].popLast()  # unrecognized
  let errmsg = "if expected a boolean or a block that evaluated to a boolean, not: " & $badpart
  handleError(env, errmsg, env.current)
core["if"].variant.add(CoreObj(args: @["Otherwise"], cmd: doIfOtherwise))

core["if*"] = CoreVars(count: 3)    # same as 'if' because 'value' has already been preserved by the block version
proc doIfKeepBool*(env: var Environment) =
  var falsepart = env.past[^1].popLast()
  var truepart = env.past[^1].popLast()
  var invalid = checkInvalid(env, 1)
  let boolpart = env.past[^1].popLast().boolVal
  if boolpart:
    truePart.invalid = truePart.invalid or invalid
    env.future.growLeft(truepart)
  else:
    falsePart.invalid = falsePart.invalid or invalid
    env.future.growLeft(falsepart)
core["if*"].variant.add(CoreObj(args: @["Bool", "Any", "Any"], cmd: doIfKeepBool))

# value {conditional expression} {do if true} {do if false} .if* --> value conditional expression { value do if true} {do if false} .if*
proc doIfKeepBlock*(env: var Environment) =   
  env.future.addFirst(env.current)            # .if*
  env.future.addFirst(env.past[^1].popLast)   # false part
  env.future.addFirst(env.past[^1].popLast)   # true part
  if len(env.past[^1]) > 1:
    if env.future[0].nodeType in collTypes:
      env.future[0].addFirst(deepCopy(env.past[^1][^2]))
    else:
      var newFuture = newBlockNode()
      newFuture.addlast(env.future.popFirst())
      newFuture.addFirst(deepCopy(env.past[^1][^2]))
      env.future.addFirst(newFuture)
  else:
    handleError(env, "if* expected something to keep, found nothing", env.current)
  env.future.growLeft(env.past[^1].popLast()) # condition block
core["if*"].variant.add(CoreObj(args: @["Blocky", "Any", "Any"], cmd: doIfKeepBlock))

proc doIfKeepOtherwise*(env: var Environment) = # discard blocks
  discard env.past[^1].popLast()  # false part
  discard env.past[^1].popLast()  # true part
  let badpart = env.past[^1].popLast()  # unrecognized
  let errmsg = "if* expected a boolean or a block that evaluated to a boolean, not: " & $badpart
  handleError(env, errmsg, env.current)
core["if*"].variant.add(CoreObj(args: @["Otherwise"], cmd: doIfKeepOtherwise))


core["iff"] = CoreVars(count: 2)  # if and only if, AKA "when"
proc doIffBool*(env: var Environment) =   # bool {do if true} .iff
  var truepart = env.past[^1].popLast()
  var invalid = checkInvalid(env, 1)
  let boolpart = env.past[^1].popLast().boolVal
  if boolpart:
    truePart.invalid = truePart.invalid or invalid
    env.future.growLeft(truepart)
core["iff"].variant.add(CoreObj(args: @["Bool", "Any"], cmd: doIffBool))

proc doIffBlock*(env: var Environment) =
  env.future.addFirst(env.current)              # .iff
  env.future.addFirst(env.past[^1].popLast())   # true part
  env.future.growLeft(env.past[^1].popLast())   # condition block
core["iff"].variant.add(CoreObj(args: @["Blocky", "Any"], cmd: doIffBlock))

proc doIffOtherwise*(env: var Environment) =  # discard blocks
  discard env.past[^1].popLast()  # true part
  let badpart = env.past[^1].popLast()  # unrecognized
  let errmsg = "iff expected a boolean or a block that evaluated to a boolean, not: " & $badpart
  handleError(env, errmsg, env.current)
core["iff"].variant.add(CoreObj(args: @["Otherwise"], cmd: doIffOtherwise))


core["iff*"] = CoreVars(count: 2)  # if and only if, AKA "when"
proc doIffKeepBool*(env: var Environment) =
  var truepart = env.past[^1].popLast()
  var invalid = checkInvalid(env, 1)
  let boolpart = env.past[^1].popLast().boolVal
  if boolpart:
    truePart.invalid = truePart.invalid or invalid
    env.future.growLeft(truepart)
core["iff*"].variant.add(CoreObj(args: @["Bool", "Any"], cmd: doIffKeepBool))

# value {conditional expression} {do if true} .iff* --> value conditional expression { value do if true} .iff*
proc doIffKeepBlock*(env: var Environment) =
  env.future.addFirst(env.current)              # .iff
  env.future.addFirst(env.past[^1].popLast())   # true part
  if len(env.past[^1]) > 1:
    if env.future[0].nodeType in collTypes:
      env.future[0].addFirst(deepCopy(env.past[^1][^2]))
    else:
      var newFuture = newBlockNode()
      newFuture.addlast(env.future.popFirst())
      newFuture.addFirst(deepCopy(env.past[^1][^2]))
      env.future.addFirst(newFuture)
  else:
    handleError(env, "iff* expected something to keep, found nothing", env.current)
  env.future.growLeft(env.past[^1].popLast())   # condition block
core["iff*"].variant.add(CoreObj(args: @["Blocky", "Any"], cmd: doIffKeepBlock))

proc doIffKeepOtherwise*(env: var Environment) =  # discard blocks
  discard env.past[^1].popLast()  # true part
  let badpart = env.past[^1].popLast()  # unrecognized
  let errmsg = "iff* expected a boolean or a block that evaluated to a boolean, not: " & $badpart
  handleError(env, errmsg, env.current)
core["iff*"].variant.add(CoreObj(args: @["Otherwise"], cmd: doIffKeepOtherwise))


core["<=>"] = CoreVars(count: 4)  # starship operator, branches based on negative, zero, positive
proc doStarshipInt*(env: var Environment) =
  var pospart = env.past[^1].popLast()
  var zeropart = env.past[^1].popLast()
  var negpart = env.past[^1].popLast()
  var invalid = checkInvalid(env, 1)
  let numpart = env.past[^1].popLast().intVal
  if numpart < 0:
    negPart.invalid = negPart.invalid or invalid
    env.future.growLeft(negpart)
  elif numpart > 0:
    posPart.invalid = posPart.invalid or invalid
    env.future.growLeft(pospart)
  else:
    zeroPart.invalid = zeroPart.invalid or invalid
    env.future.growLeft(zeropart)
core["<=>"].variant.add(CoreObj(args: @["Int", "Any", "Any", "Any"], cmd: doStarshipInt))

proc doStarshipFloat*(env: var Environment) =
  var pospart = env.past[^1].popLast()
  var zeropart = env.past[^1].popLast()
  var negpart = env.past[^1].popLast()
  var invalid = checkInvalid(env, 1)
  let numpart = env.past[^1].popLast().floatVal
  if numpart < 0.0:
    negPart.invalid = negPart.invalid or invalid
    env.future.growLeft(negpart)
  elif numpart > 0.0:
    posPart.invalid = posPart.invalid or invalid
    env.future.growLeft(pospart)
  else:
    zeroPart.invalid = zeroPart.invalid or invalid
    env.future.growLeft(zeropart)
core["<=>"].variant.add(CoreObj(args: @["Float", "Any", "Any", "Any"], cmd: doStarshipFloat))

proc doStarshipBlock*(env: var Environment) =
  env.future.addFirst(env.current)              # <=>
  env.future.addFirst(env.past[^1].popLast())   # negPart
  env.future.growLeft(env.past[^1].popLast())   # zeroPart
  env.future.growLeft(env.past[^1].popLast())   # posPart
  env.future.growLeft(env.past[^1].popLast())   # condition block
core["<=>"].variant.add(CoreObj(args: @["Blocky", "Any", "Any", "Any"], cmd: doStarshipBlock))

proc doStarshipOtherwise*(env: var Environment) = # discard blocks
  discard env.past[^1].popLast()  # posPart
  discard env.past[^1].popLast()  # zeroPart
  discard env.past[^1].popLast()  # negPart
  let badpart = env.past[^1].popLast()
  let errmsg = "<=> expected a number or a block that evaluated to a number, not: " & $badpart
  handleError(env, errmsg, env.current)
core["<=>"].variant.add(CoreObj(args: @["Otherwise"], cmd: doStarshipOtherwise))

core["nop"] = CoreVars(count: 0)
proc doNop*(env: var Environment) =
  discard
core["nop"].variant.add(CoreObj(args: @[], cmd: doNop))

core["init"] = CoreVars(count: 2)
proc doInit*(env: var Environment) =
  var itemNameNode = env.past[^1].popLast()
  var itemValNode = env.past[^1].popLast()
  var itemName: string
  if itemNameNode.nodeType == String:
    itemName = itemNameNode.stringVal
  elif itemNameNode.nodeType == Word:
    itemName = itemNameNode.wordVal
  else: 
    let errmsg = "init error: invalid name.  Must be a string or word, not: " & $itemNameNode
    handleError(env, errmsg, env.current)
    return
  if not wordVerify(itemName):
    let errmsg = "init error: invalid name.  Must be a valid word, not: " & $itemNameNode
    handleError(env, errmsg, env.current)
  else:
    env.locals[^1][itemName] = itemValNode
core["init"].variant.add(CoreObj(args: @["Any", "Wordy"], cmd: doInit))

core["create_stack"] = CoreVars(count: 1)
proc doCreateStack*(env: var Environment) =
  var itemNameNode = env.past[^1].popLast()
  var itemName: string
  if itemNameNode.nodeType == String:
    itemName = itemNameNode.stringVal
  elif itemNameNode.nodeType == Word:
    itemName = itemNameNode.wordVal
  else: 
    let errmsg = "init error: invalid name.  Must be a string or word, not: " & $itemNameNode
    handleError(env, errmsg, env.current)
    return
  if not wordVerify(itemName):
    let errmsg = "init error: invalid name.  Must be a valid name, not: " & $itemNameNode
    handleError(env, errmsg, env.current)
  else:
    env.globals[itemName] = newLsSeq(8)
core["create_stack"].variant.add(CoreObj(args: @["Wordy"], cmd: doCreateStack))


core["def"] = CoreVars(count: 3)
proc doDef*(env: var Environment) =
  var commands = env.past[^1].popLast()
  var itemArgs = env.past[^1].popLast().seqVal
  var itemName: string
  var itemNameNode = env.past[^1].popLast()
  if itemNameNode.nodeType == String:
    itemName = itemNameNode.stringVal
  elif itemNameNode.nodeType == Word:
    itemName = itemNameNode.wordVal
  else: 
    let errmsg = "def error: invalid name.  Must be a string or word, not: " & $itemNameNode
    handleError(env, errmsg, env.current)
    return
  if not wordVerify(itemName):
    let errmsg = "def error: invalid name.  Must be a valid name, not: " & $itemNameNode
    handleError(env, errmsg, env.current)
    return
  var currentSpace = env.currentNameSpace
  var argSeq: seq[string]
  for arg in itemArgs:
    argSeq.add(arg.stringVal)
  var howMany = len(argSeq)
  if howMany == 1 and argSeq[0] == "":
    howMany = 0
  if not hasKey(env.nameSpace, currentSpace):
    var funcor: FunCore
    var funcvar: FuncVars
    var funcobj: FuncObj
    funcobj = FuncObj(args: argSeq, cmd: commands)
    funcvar = FuncVars(count: howMany)
    funcvar.variant.add(funcobj)
    funcor[itemName] = funcvar
    env.nameSpace[currentSpace] = funcor
  else:
    if not hasKey(env.nameSpace[currentSpace], itemName): 
      var funcvar: FuncVars
      var funcobj: FuncObj
      funcobj = FuncObj(args: argSeq, cmd: commands)
      funcvar = FuncVars(count: howMany)
      funcvar.variant.add(funcobj)
      env.nameSpace[currentSpace][itemName] = funcvar
    else:
      if howMany != env.nameSpace[currentSpace][itemName].count and howMany != 1 and argSeq[0].toLowerAscii() != "Otherwise":
        let errmsg = "Function argument count mismatch.  Expected: " & $env.nameSpace[currentSpace][itemName].count & ", found: " & $len(argSeq) & " in " & itemName & " : " & $argSeq
        handleError(env, errmsg, env.current)
      else:
        var funcobj: FuncObj
        funcobj = FuncObj(args: argSeq, cmd: commands)
        env.nameSpace[currentSpace][itemName].variant.add(funcobj)
core["def"].variant.add(CoreObj(args: @["Wordy", "Listy", "Block"], cmd: doDef))

core["def_sugar"] = CoreVars(count: 1)
proc doDefSugar*(env: var Environment) =
  var itemName = env.past[^1].popLast().stringVal
  sugar.add(itemName)
  var newFuture: LsSeq
  for item in env.future:
    if item.nodeType == Word and item.wordVal in sugar:
      discard
    else:
      newFuture.addLast(item)
  env.future = newFuture
core["def_sugar"].variant.add(CoreObj(args: @[], cmd: doDefSugar))

core["get"] = CoreVars(count: 1)    # \name get
proc doGet*(env: var Environment) =
  let itemNode = env.past[^1].popLast()
  var itemName: string
  var found = false
  var thing: LsNode
  if itemNode.nodeType == Char:
    itemName = $itemNode.charVal
  elif itemNode.nodeType == String:
    itemName = itemNode.stringVal
  else:
    itemName = itemNode.wordVal
  if env.globals.haskey(itemName):   # global stack
    found = true
    if len(env.globals[itemName]) > 0:
      thing = env.globals[itemName][^1]
    else:
      thing = newNullNode(true)   # none
  if not found:
    for i in countdown(len(env.locals)-1, 0):   # local variables, check from newest to oldest scope
      if env.locals[i].haskey(itemName): 
        found = true 
        thing = env.locals[i][itemName]
        break
  if not found:
    for key, val in env.nameSpace:
      if val.hasKey(itemName):    # user function
        found = true
        thing = newStringNode(itemName & ";" & key)
        break
  if not found:
    if core.hasKey(itemName):   # core fucntion
      found = true
      thing = newStringNode(itemName & ";core")
  if not found:
    thing = newNullNode()
    handleError(env, "Word: " & itemName & " not found", env.current)
  env.past[^1].addLast(thing)
core["get"].variant.add(CoreObj(args: @["String"], cmd: doGet))
core["get"].variant.add(CoreObj(args: @["Word"], cmd: doGet))
core["get"].variant.add(CoreObj(args: @["Char"], cmd: doGet))

core["set"] = CoreVars(count: 2)    # set: "name" value
proc doSet*(env: var Environment) =
  let valNode = env.past[^1].popLast()
  let itemNode = env.past[^1].popLast()
  var itemName: string
  var found = false
  if itemNode.nodeType == Char:
    itemName = $itemNode.charVal
  elif itemNode.nodeType == String:
    itemName = itemNode.stringVal
  else:
    itemName = itemNode.wordVal
  if env.globals.haskey(itemName):   # push on global stack
    found = true
    env.globals[itemName].addLast(valNode) 
  if not found:
    for i in countdown(len(env.locals)-1, 0):   # local variables, check from newest to oldest scope
      if env.locals[i].haskey(itemName): 
        found = true 
        env.locals[i][itemName] = valNode
  if not found:
    for key, val in env.nameSpace:
      if val.hasKey(itemName):    # user function
        found = true
        handleError(env, "Cannot set function: " & itemName & ";" & key, valNode)
        break
  if not found:
    if core.hasKey(itemName):   # core fucntion
      found = true
      handleError(env, "Cannot set function: " & itemName & ";core", valNode)
  if not found:
    handleError(env, "set: " & itemName & " not found", valNode)
core["set"].variant.add(CoreObj(args: @["String", "Any"], cmd: doSet))
core["set"].variant.add(CoreObj(args: @["Word", "Any"], cmd: doSet))
core["set"].variant.add(CoreObj(args: @["Char", "Any"], cmd: doSet))

core["call"] = CoreVars(count: 1)    # \name call --> name eval
proc doCall*(env: var Environment) =
  var itemNode = env.past[^1].popLast()
  itemNode.deferred = false
  var itemName: string
  var found = false
  var thing: LsNode
  if itemNode.nodeType == Char:
    itemName = $itemNode.charVal
  elif itemNode.nodeType == String:
    itemName = itemNode.stringVal
    if itemName[0] == '.':
      itemName = itemName[1..^1]
      itemNode = newWordNode(itemName, Postfix)
    elif itemName[^1] == ':':
      itemName = itemName[0..^2]
      itemNode = newWordNode(itemName, Prefix)
    else:
      itemNode = newWordNode(itemName, Infix)
  else:
    itemName = itemNode.wordVal
  if env.globals.haskey(itemName):   # global stack
    found = true
    if len(env.globals[itemName]) > 0:
      thing = env.globals[itemName][^1]
    else:
      thing = newNullNode()
    env.future.growLeft(thing)
  if not found:
    for i in countdown(len(env.locals)-1, 0):   # local variables, check from newest to oldest scope
      if env.locals[i].haskey(itemName): 
        found = true 
        thing = env.locals[i][itemName]
        env.future.growLeft(thing)
        break
  if not found:   # presume it is a function, let Listack handle executing it or throwing an error
    env.future.addFirst(itemNode)
core["call"].variant.add(CoreObj(args: @["String"], cmd: doCall))
core["call"].variant.add(CoreObj(args: @["Word"], cmd: doCall))
core["call"].variant.add(CoreObj(args: @["Char"], cmd: doCall))


core["free"] = CoreVars(count: 1)    # \name free --> removes name from environment
proc doFree*(env: var Environment) =
  var itemNode = env.past[^1].popLast()
  itemNode.deferred = false
  var itemName: string
  var found = false
  if itemNode.nodeType == Char:
    itemName = $itemNode.charVal
  elif itemNode.nodeType == String:
    itemName = itemNode.stringVal
    if itemName[0] == '.':
      itemName = itemName[1..^1]
    elif itemName[^1] == ':':
      itemName = itemName[0..^2]
  else:
    itemName = itemNode.wordVal
  if env.globals.haskey(itemName):   # global stack
    found = true
    if (len(itemName) == 1 and itemName[0] in uppers) or itemName[0] == '_':
      handleError(env, "free cannot delete built-in global variable: " & itemName & ", cleared instead", env.current)
      env.globals[itemName].clear()
    else:
      env.globals.del(itemName)
  if not found:
    for i in countdown(len(env.locals)-1, 0):   # local variables, check from newest to oldest scope
      if env.locals[i].haskey(itemName): 
        found = true 
        if len(itemName) == 1 and itemName[0] in lowers:
          handleError(env, "free cannot delete built-in local variable: " & itemName & ", cleared instead", env.current)
          env.locals[i][itemName] = newNullNode()
        else:
          env.locals[i].del(itemName)
        break
  if not found:
    for key, val in env.nameSpace:
      if val.hasKey(itemName):    # user function
        found = true
        if key == "system":
          handleError(env, "free cannot delete system function: " & itemName, env.current)
        else:
          env.nameSpace[key].del(itemName)
        break
  if not found:
    if core.hasKey(itemName):   # core fucntion
      found = true
      handleError(env, "free cannot delete core function: " & itemName, env.current)
  if not found:
    handleError(env, "free: " & itemName & " not found", env.current)
core["free"].variant.add(CoreObj(args: @["String"], cmd: doFree))
core["free"].variant.add(CoreObj(args: @["Word"], cmd: doFree))
core["free"].variant.add(CoreObj(args: @["Char"], cmd: doFree))


core["_set_namespace"] = CoreVars(count: 1)
proc doSetNameSpace*(env: var Environment) =
  var itemName = env.past[^1].popLast().stringVal
  if itemName == "core":
    let errmsg = "Cannot set NameSpace to 'core'"
    handleError(env, errmsg, env.current)
    env.currentNameSpace = "default"
  elif itemName == "":
    env.currentNameSpace = "default"
  else:
    env.currentNameSpace = itemName
  if env.currentNameSpace notin env.nameSpace:  # create new NameSpace
    var funcor: FunCore
    env.nameSpace[env.currentNameSpace] = funcor
core["_set_namespace"].variant.add(CoreObj(args: @["String"], cmd: doSetNameSpace))

core["_reset_namespace"] = CoreVars(count: 0)
proc doReSetNameSpace*(env: var Environment) =
  env.currentNameSpace = "default"
core["_reset_namespace"].variant.add(CoreObj(args: @[], cmd: doReSetNameSpace))

core[">some"] = CoreVars(count:1)   # convert any to valid some
proc doToSome*(env: var Environment) =
  env.past[^1][^1].invalid = false
core[">some"].variant.add(CoreObj(args: @["Any"], cmd: doToSome))

core[">none"] = CoreVars(count:1)  # convert to none
proc doSomeNone*(env: var Environment) =
  env.past[^1][^1].invalid = true
core[">none"].variant.add(CoreObj(args: @["Any"], cmd: doSomeNone))

core["none"] = CoreVars(count:0)  # add invalid none (takes no argument)
proc doNewNone*(env: var Environment) =
  env.past[^1].addLast(newNullNode(true))
core["none"].variant.add(CoreObj(args: @[], cmd: doNewNone))

core["type*"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doTypeKeep*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newStringNode($env.past[^1][^1].nodeType))
  setInvalid(env, invalid)
core["type*"].variant.add(CoreObj(args: @["Any"], cmd: doTypeKeep))

core["type"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doType*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newStringNode($env.past[^1].popLast().nodeType))
  setInvalid(env, invalid)
core["type"].variant.add(CoreObj(args: @["Any"], cmd: doType))

core["_meta"] = CoreVars(count: 1)  # [num_past, num_future, {command block}] _meta
proc doMeta*(env: var Environment) =  # parses the command block, swapping @#a..z for past nodes, @#A..Z for future nodes, expanding @% a..zA..Z nodes
  var metaRecord = env.past[^1].popLast() # not really needed since the addition of custom stacks
  var pastSeq, futureSeq: LsSeq
  
  proc doMetaReplace(env: var Environment, metaSeq: LsSeq): LsSeq =
    var newBlock: LsSeq
    var counter: int
    for item in metaSeq:
      if item.nodeType in collTypes:
        item.seqVal = doMetaReplace(env, item.seqVal)
        newBlock.addLast(item)
      elif item.nodeType == Word and len(item.wordVal) == 1 and item.wordFunc == '#' and char(item.wordVal[0]) in lowers:   # past standard meta
        counter = ord(char(item.wordVal[0])) - ord('a')
        newBlock.addLast(pastSeq[counter])
      elif item.nodeType == Word and len(item.wordVal) == 1 and item.wordFunc == '#' and char(item.wordVal[0]) in uppers:   # future standard meta
        counter = ord(char(item.wordVal[0])) - ord('A')
        newBlock.addLast(futureSeq[counter])
      elif item.nodeType == Word and len(item.wordVal) == 1 and item.wordFunc == '%' and char(item.wordVal[0]) in lowers:   # past extend meta
        counter = ord(char(item.wordVal[0])) - ord('a')
        newBlock.growRight(pastSeq[counter])
      elif item.nodeType == Word and len(item.wordVal) == 1 and item.wordFunc == '%' and char(item.wordVal[0]) in uppers:   # future extend meta
        counter = ord(char(item.wordVal[0])) - ord('A')
        newBlock.growRight(futureSeq[counter])
      elif item.nodeType == Word and item.wordFunc in {'#', '%'}:
        let errmsg = "Meta error: " & item.wordVal & " is not a valid meta variable"
        handleError(env, errmsg, env.current)
      else:
        newBlock.addLast(item)
    return newBlock

  if metaRecord.nodeType notIn listy or len(metaRecord.seqVal) != 3:
    let errmsg = "Meta record must contain exactly 3 items:  intPast, intFuture, metaBlock, not: " & $metaRecord
    handleError(env, errmsg, env.current)
  else:
    let numPastNode = metaRecord.seqVal[0]
    let numFutureNode = metaRecord.seqVal[1]
    let metaBlockNode = metaRecord.seqVal[2]
    if numPastNode.nodeType != Int or numFutureNode.nodeType != Int or metaBlockNode.nodeType != Block:
      let errmsg = "Meta record must contain exactly 3 items:  intPast, intFuture, metaBlock, not " & $metaRecord
      handleError(env, errmsg, env.current)
    else:
      let numPast = numPastNode.intVal
      let numFuture = numFutureNode.intVal
      var metaBlock = metaBlockNode.seqVal
      if numPast > len(env.past[^1]):
        let errmsg = "Meta error:  insufficient stack depth"
        handleError(env, errmsg, env.current)
      elif numFuture > len(env.future):
        let errmsg = "Meta error:  insufficient command queue depth"
        handleError(env, errmsg, env.current)
      else:
        for i in 1..numPast:
          pastSeq.addFirst(env.past[^1].popLast())
        for i in 1..numFuture:
          futureSeq.addLast(env.future.popFirst())
        var newBlock = doMetaReplace(env, metaBlock)
        expandLeft(env.future, newBlock)
core["_meta"].variant.add(CoreObj(args: @["Listy"], cmd: doMeta))

core["obj"] = CoreVars(count:1)    # reads object value, preserving object
proc doReadObj*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var item = deepCopy(env.past[^1][^1].objectVal)
  env.past[^1].addLast(item)
  setInvalid(env, invalid)
core["obj"].variant.add(CoreObj(args: @["Object"], cmd: doReadObj))

core["<obj"] = CoreVars(count:1)    # reads object value, deleting object
proc doGetObj*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var item = env.past[^1].popLast().objectVal
  env.past[^1].addLast(item)
  setInvalid(env, invalid)
core["<obj"].variant.add(CoreObj(args: @["Object"], cmd: doGetObj))

core["obj_type"] = CoreVars(count:1)    # reads object type, deleting object
proc doTypeObj*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var kind = env.past[^1].popLast().objectType
  env.past[^1].addLast(newBlockNode(kind))
  setInvalid(env, invalid)
core["obj_type"].variant.add(CoreObj(args: @["Object"], cmd: doTypeObj))

core["obj_type*"] = CoreVars(count:1)    # reads object type, preserving object
proc doKeepTypeObj*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var kind = deepCopy(env.past[^1][^1].objectType)
  env.past[^1].addLast(newBlockNode(kind))
  setInvalid(env, invalid)
core["obj_type*"].variant.add(CoreObj(args: @["Object"], cmd: doKeepTypeObj))

core["?obj"] = CoreVars(count:1)    # evaluates object type on object
proc doCheckObj*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var kind = deepCopy(env.past[^1][^1].objectType)
  env.future.expandLeft(kind, invalid)
core["?obj"].variant.add(CoreObj(args: @["Object"], cmd: doCheckObj))

core[">obj"] = CoreVars(count:2)    # sets object value and then type checks it
proc doSetObj*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var newVal = env.past[^1].popLast()
  env.past[^1][^1].objectVal = newVal
  setInvalid(env, invalid)
  doCheckObj(env)
core[">obj"].variant.add(CoreObj(args: @["Object", "Any"], cmd: doSetObj))

core["!obj"] = CoreVars(count:1)    # eval object value, deleting object
proc doDoObj*(env: var Environment) =
  var kind = env.past[^1].popLast().objectVal
  env.future.growLeft(kind)
core["!obj"].variant.add(CoreObj(args: @["Object"], cmd: doDoObj))

core["!obj*"] = CoreVars(count:1)    # eval object value, deleting object
proc doKeepDoObj*(env: var Environment) =
  var kind = deepCopy(env.past[^1][^1].objectVal)
  env.future.growLeft(kind)
core["!obj*"].variant.add(CoreObj(args: @["Object"], cmd: doKeepDoObj))

core["obj_args"] = CoreVars(count:1)    # reads object value, preserving object
proc doReadObjArgs*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var item = deepCopy(env.past[^1][^1].objectArgs)
  env.past[^1].addLast(newListNode(item))
  setInvalid(env, invalid)
core["obj_args"].variant.add(CoreObj(args: @["Object"], cmd: doReadObjArgs))

core["<obj_args"] = CoreVars(count:1)    # reads object value, deleting object
proc doGetObjArgs*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var item = env.past[^1].popLast().objectArgs
  env.past[^1].addLast(newListNode(item))
  setInvalid(env, invalid)
core["<obj_args"].variant.add(CoreObj(args: @["Object"], cmd: doGetObjArgs))

core[">obj_args"] = CoreVars(count:2)    # sets object value and then type checks it
proc doSetObjArgs*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var newVal = env.past[^1].popLast()
  env.past[^1][^1].objectArgs = newVal.seqVal
  setInvalid(env, invalid)
  doCheckObj(env)
core[">obj_args"].variant.add(CoreObj(args: @["Object", "Coll"], cmd: doSetObjArgs))

core["make_obj"] = CoreVars(count:1)    # sets object value and then type checks it
proc doMakeObj*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var objList = env.past[^1].popLast()
  if len(objList.seqVal) != 3:
    handleError(env, "make_obj expected [{type} [args] value], not: " & $objList, objList)
  elif (objList.seqVal[0].nodeType notin collTypes) or (objList.seqVal[1].nodeType notin collTypes):
    handleError(env, "make_obj expected [{type} [args] value], not: " & $objList, objList)
  else:
    var objTyp = objList.seqVal[0].seqVal
    var objArg = objList.seqVal[1].seqVal
    var objVal = objList.seqVal[2]
    env.past[^1].addLast(newObjectNode(objTyp, objArg, objVal))
    setInvalid(env, invalid)
    doCheckObj(env)
core["make_obj"].variant.add(CoreObj(args: @["Coll"], cmd: doMakeObj))

when isMainModule:
  stdOut.write("Core at the end of lscore: ")
  for item in core.keys:
    stdOut.write(item, " ")
  stdOut.writeLine("")

  