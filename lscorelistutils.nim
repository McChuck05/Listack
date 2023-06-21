## lscoreflow
## Listack 0.0.0

import std/deques, std/tables, std/strutils
import lstypes, lstypeprint, lstypehelpers, lsconfig 
import lscorebool
# import os, std/sequtils, std/terminal, std/math, std/algorithm
# import lsparser, lscore

core["len*"] = CoreVars(count:1)    # [1 2 3] len* --> [1 2 3] 3
proc doLenKeep*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  if env.past[^1][^1].nodeType in typeMap["Coll"]:
    env.past[^1].addLast(newIntNode(len(env.past[^1][^1].seqVal)))
  elif env.past[^1][^1].nodeType == String:
    env.past[^1].addLast(newIntNode(len(env.past[^1][^1].stringVal)))
  elif env.past[^1][^1].nodeType == Null:
    env.past[^1].addLast(newIntNode(0))
  else:
    env.past[^1].addLast(newIntNode(1))
  setInvalid(env, invalid)
core["len*"].variant.add(CoreObj(args: @["Any"], cmd: doLenKeep))

core["len"] = CoreVars(count:1)    # [1 2 3] len --> 3
proc doLen*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  let this = env.past[^1].popLast()
  if this.nodeType in typeMap["Coll"]:
    env.past[^1].addLast(newIntNode(len(this.seqVal)))
  elif this.nodeType == String:
    env.past[^1].addLast(newIntNode(len(this.stringVal)))
  elif this.nodeType == Null:
    env.past[^1].addLast(newIntNode(0))
  else:
    env.past[^1].addLast(newIntNode(1))
  setInvalid(env, invalid)
core["len"].variant.add(CoreObj(args: @["Any"], cmd: doLen))

core["first*"] = CoreVars(count:1)  # [1 2 3] first* --> [2 3] 1
proc doFirstKeep*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  if len(env.past[^1][^1].seqVal) > 0:
    var thing = env.past[^1][^1].seqVal.popFirst()
    env.past[^1].addLast(thing)
    setInvalid(env, invalid)
  else:
    handleError(env, "first* cannot obtain blood from a stone", env.past[^1][^1])
    env.past[^1].addLast(newNullNode(true))
core["first*"].variant.add(CoreObj(args: @["Coll"], cmd: doFirstKeep))

proc doFirstKeepString*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  if len(env.past[^1][^1].stringVal) > 0:
    var thing = env.past[^1][^1].stringVal[0]
    if len(env.past[^1][^1].stringVal) > 1:
      env.past[^1][^1].stringVal = env.past[^1][^1].stringVal[1..^1]
    else:
      env.past[^1][^1].stringVal = ""
    env.past[^1].addLast(newCharNode(thing))
    setInvalid(env, invalid)
  else:
    handleError(env, "first* cannot obtain blood from a stone", env.past[^1][^1])
    env.past[^1].addLast(newCharNode('\0'))
    setInvalid(env, true)
core["first*"].variant.add(CoreObj(args: @["String"], cmd: doFirstKeepString))

core["first"] = CoreVars(count:1)  # [1 2 3] first --> 1
proc doFirst*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  if len(env.past[^1][^1].seqVal) > 0:
    var thing = env.past[^1].popLast().seqVal.popFirst()
    env.past[^1].addLast(thing)
    setInvalid(env, invalid)
  else:
    handleError(env, "first cannot obtain blood from a stone", env.past[^1][^1])
    env.past[^1].addLast(newNullNode(true))
core["first"].variant.add(CoreObj(args: @["Coll"], cmd: doFirst))

proc doFirstString*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  var thing = env.past[^1].popLast().stringVal
  if len(thing) > 0:
    env.past[^1].addLast(newCharNode(thing[0]))
    setInvalid(env, invalid)
  else:
    handleError(env, "first cannot obtain blood from a stone", env.past[^1][^1])
    env.past[^1].addLast(newCharNode('\0'))
    setInvalid(env, true)
core["first"].variant.add(CoreObj(args: @["String"], cmd: doFirstString))

core["last*"] = CoreVars(count:1)  # [1 2 3] last* --> [1 2] 3
proc doLastKeep*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  if len(env.past[^1][^1].seqVal) > 0:
    var thing = env.past[^1][^1].seqVal.popLast()
    env.past[^1].addLast(thing)
    setInvalid(env, invalid)
  else:
    handleError(env, "last* cannot obtain blood from a stone", env.past[^1][^1])
    env.past[^1].addLast(newNullNode(true))
core["last*"].variant.add(CoreObj(args: @["Coll"], cmd: doLastKeep))

proc doLastKeepString*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  if len(env.past[^1][^1].stringVal) > 0:
    var thing = env.past[^1][^1].stringVal[^1]
    if len(env.past[^1][^1].stringVal) > 1:
      env.past[^1][^1].stringVal = env.past[^1][^1].stringVal[0..^2]
    else:
      env.past[^1][^1].stringVal = ""
    env.past[^1].addLast(newCharNode(thing))
    setInvalid(env, invalid)
  else:
    handleError(env, "last* cannot obtain blood from a stone", env.past[^1][^1])
    env.past[^1].addLast(newNullNode(true))
core["last*"].variant.add(CoreObj(args: @["String"], cmd: doLastKeepString))

core["last"] = CoreVars(count:1)  # [1 2 3] last --> 3
proc doLast*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  var thing = env.past[^1].popLast()
  if len(thing.seqVal) > 0:
    env.past[^1].addLast(thing.seqVal.popLast())
    setInvalid(env, invalid)
  else:
    handleError(env, "last cannot obtain blood from a stone", env.past[^1][^1])
    env.past[^1].addLast(newNullNode(true))
core["last"].variant.add(CoreObj(args: @["Coll"], cmd: doLast))

proc doLastString*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  var thing = env.past[^1].popLast()
  if len(thing.stringVal) > 0:
    env.past[^1].addLast(newCharNode(thing.stringVal[^1]))
    setInvalid(env, invalid)
  else:
    handleError(env, "last cannot obtain blood from a stone", env.past[^1][^1])
    env.past[^1].addLast(newNullNode(true))
core["last"].variant.add(CoreObj(args: @["String"], cmd: doLastString))

core["but_first"] = CoreVars(count:1)  # [1 2 3] but_first --> [2 3] 
proc doButFirst*(env: var Environment) =
  if len(env.past[^1][^1].seqVal) > 0:
    env.past[^1][^1].seqVal.popFirst()
  else:
    handleError(env, "but_first cannot obtain blood from a stone", env.past[^1][^1])
core["but_first"].variant.add(CoreObj(args: @["Coll"], cmd: doButFirst))

proc doButFirstString*(env: var Environment) =
  if len(env.past[^1][^1].stringVal) > 0:
    env.past[^1][^1].stringVal = env.past[^1][^1].stringVal[1..^1]
  else:
    handleError(env, "but_first cannot obtain blood from a stone", env.past[^1][^1])
core["but_first"].variant.add(CoreObj(args: @["String"], cmd: doButFirstString))

core["but_last"] = CoreVars(count:1)  # [1 2 3] but_last --> [1 2]
proc doButLast*(env: var Environment) =
  if len(env.past[^1][^1].seqVal) > 0:
    env.past[^1][^1].seqVal.popLast()
  else:
    handleError(env, "but_last cannot obtain blood from a stone", env.past[^1][^1])
core["but_last"].variant.add(CoreObj(args: @["Coll"], cmd: doButLast))

proc doButLastString*(env: var Environment) =
  if len(env.past[^1][^1].stringVal) > 0:
    env.past[^1][^1].stringVal = env.past[^1][^1].stringVal[0..^2]
  else:
    handleError(env, "but_last cannot obtain blood from a stone", env.past[^1][^1])
core["but_last"].variant.add(CoreObj(args: @["String"], cmd: doButLastString))

core["delist"] = CoreVars(count:1)  # [1 2 3] delist --> 1 2 3 3
proc doDelist*(env: var Environment) =
  let invalid = checkInvalid(env, 1)
  let thisSeq = env.past[^1].popLast()
  let howMany = len(thisSeq.seqVal)
  if howMany > 0:
    for item in thisSeq.seqVal:
      env.past[^1].addLast(item)
      setInvalid(env, invalid)
  env.past[^1].addLast(newIntNode(howMany))
  setInvalid(env, invalid) 
core["delist"].variant.add(CoreObj(args: @["Coll"], cmd: doDelist))

core["enlist"] = CoreVars(count:1)        # 1 2 3 2 enlist --> 1 [2 3]
proc doEnlist*(env: var Environment) =  
  var invalid = checkInvalid(env, 1)  
  var howMany = env.past[^1].popLast().intVal
  var newList = newListNode()
  if howMany < 0:                         # 1 2 3 -5 enlist --> 1 2 3 []*
    handleError(env, "Can't enlist " & $howMany & " items", env.current)
    invalid = true
  elif howMany > 0:                       # 1 2 3 0 enlist --> 1 2 3 []
    if len(env.past[^1]) < howMany:     # 1 2 3 5 enlist --> [1 2 3]*
      let msg = "enlist expected " & $howMany & " items, but found only " & $len(env.past[^1])
      handleError(env, msg, env.current)
      howMany = len(env.past[^1])
      invalid = true
    for count in 0..<howMany:
      newList.seqVal.addFirst(env.past[^1].popLast())
      invalid = invalid or newList.seqVal[0].invalid
  newList.invalid = invalid
  env.past[^1].addLast(newList)
core["enlist"].variant.add(CoreObj(args: @["Int"], cmd: doEnlist))

core["enlist_all"] = CoreVars(count:0)  # 1 2 3 4 enlist_all --> [1 2 3 4]
proc doEnlistAll*(env: var Environment) =
  var invalid = false
  let howMany = len(env.past[^1])
  var newList = newListNode()
  if howMany > 0:
    for count in 0..<howMany:
      newList.seqVal.addFirst(env.past[^1].popLast())
      invalid = invalid or newList.seqVal[0].invalid
  newList.invalid = invalid
  env.past[^1].addLast(newList)
core["enlist_all"].variant.add(CoreObj(args: @[], cmd: doEnlistAll))

core["concat"] = CoreVars(count:2)      # [1 2 3] concat [4 5 6] --> [1 2 3 4 5 6]
proc doConcat*(env: var Environment) =
  var invalid = checkInvalid(env, 2)  
  let this = env.past[^1].popLast()
  for item in this.seqVal:
    env.past[^1][^1].seqVal.addLast(item)
    invalid = invalid or item.invalid
  setInvalid(env, invalid)
core["concat"].variant.add(CoreObj(args: @["Coll", "Coll"], cmd: doConcat))

proc doConcatLI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var this = env.past[^1].popLast()
  env.past[^1][^1].seqVal.addLast(this)
  setInvalid(env, invalid)
core["concat"].variant.add(CoreObj(args: @["Coll", "Item"], cmd: doConcatLI))
core["concat"].variant.add(CoreObj(args: @["Coll", "Null"], cmd: doConcatLI))

proc doConcatIL*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var thisSeq = env.past[^1].popLast()
  var thisItem = env.past[^1].popLast()
  thisSeq.seqVal.addFirst(thisItem)
  env.past[^1].addLast(thisSeq)
  setInvalid(env, invalid)
core["concat"].variant.add(CoreObj(args: @["Item", "Coll"], cmd: doConcatIL))
core["concat"].variant.add(CoreObj(args: @["Null", "Coll"], cmd: doConcatIL))

proc doConcatII*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast()
  var item1 = env.past[^1].popLast()
  var thisSeq = newListNode()
  thisSeq.addFirst(item1)   
  thisSeq.addLast(item2)   
  env.past[^1].addLast(thisSeq)
  setInvalid(env, invalid)
core["concat"].variant.add(CoreObj(args: @["Item", "Item"], cmd: doConcatII))
core["concat"].variant.add(CoreObj(args: @["Item", "Null"], cmd: doConcatII))
core["concat"].variant.add(CoreObj(args: @["Null", "Item"], cmd: doConcatII))
core["concat"].variant.add(CoreObj(args: @["Null", "Null"], cmd: doConcatII))


core["append"] = CoreVars(count:2)      # [1 2 3] append [4 5 6] --> [1 2 3 [4 5 6]]
proc doAppend*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let this = env.past[^1].popLast()
  env.past[^1][^1].seqVal.addLast(this)
  setInvalid(env, invalid)
core["append"].variant.add(CoreObj(args: @["Coll", "Coll"], cmd: doAppend))
core["append"].variant.add(CoreObj(args: @["Coll", "Item"], cmd: doAppend))
core["append"].variant.add(CoreObj(args: @["Coll", "Null"], cmd: doAppend))

proc doAppendSS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast().stringVal
  var item1 = env.past[^1].popLast().stringVal
  var this = newStringNode(item1 & item2)
  env.past[^1].addLast(this)
  setInvalid(env, invalid)
core["append"].variant.add(CoreObj(args: @["String", "String"], cmd: doAppendSS))

proc doAppendSC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast().charVal
  var item1 = env.past[^1].popLast().stringVal
  var this = newStringNode(item1 & item2)
  env.past[^1].addLast(this)
  setInvalid(env, invalid)
core["append"].variant.add(CoreObj(args: @["String", "Char"], cmd: doAppendSC))

proc doAppendCS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast().stringVal
  var item1 = env.past[^1].popLast().charVal
  var this = newStringNode(item1 & item2)
  env.past[^1].addLast(this)
  setInvalid(env, invalid)
core["append"].variant.add(CoreObj(args: @["Char", "String"], cmd: doAppendCS))

proc doAppendCC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast().charVal
  var item1 = env.past[^1].popLast().charVal
  var this = newStringNode(item1 & item2)
  env.past[^1].addLast(this)
  setInvalid(env, invalid)
core["append"].variant.add(CoreObj(args: @["Char", "Char"], cmd: doAppendCC))


core["prepend"] = CoreVars(count:2)      # [1 2 3] prepend [4 5 6] --> [[4 5 6] 1 2 3]
proc doPrepend*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let this = env.past[^1].popLast()
  env.past[^1][^1].seqVal.addFirst(this)
  setInvalid(env, invalid)
core["prepend"].variant.add(CoreObj(args: @["Coll", "Coll"], cmd: doPrepend))
core["prepend"].variant.add(CoreObj(args: @["Coll", "Item"], cmd: doPrepend))
core["prepend"].variant.add(CoreObj(args: @["Coll", "Null"], cmd: doPrepend))

proc doPrependSS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast().stringVal
  var item1 = env.past[^1].popLast().stringVal
  var this = newStringNode(item2 & item1)
  env.past[^1].addLast(this)
  setInvalid(env, invalid)
core["prepend"].variant.add(CoreObj(args: @["String", "String"], cmd: doPrependSS))

proc doPrependSC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast().charVal
  var item1 = env.past[^1].popLast().stringVal
  var this = newStringNode(item2 & item1)
  env.past[^1].addLast(this)
  setInvalid(env, invalid)
core["prepend"].variant.add(CoreObj(args: @["String", "Char"], cmd: doPrependSC))

proc doPrependCS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast().stringVal
  var item1 = env.past[^1].popLast().charVal
  var this = newStringNode(item2 & item1)
  env.past[^1].addLast(this)
  setInvalid(env, invalid)
core["prepend"].variant.add(CoreObj(args: @["Char", "String"], cmd: doPrependCS))

proc doPrependCC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var item2 = env.past[^1].popLast().charVal
  var item1 = env.past[^1].popLast().charVal
  var this = newStringNode(item2 & item1)
  env.past[^1].addLast(this)
  setInvalid(env, invalid)
core["prepend"].variant.add(CoreObj(args: @["Char", "Char"], cmd: doPrependCC))


core["insert"] = CoreVars(count:3)      # [1 2 3] insert 1 "A" --> [1 "A" 2 3]
proc doInsert*(env: var Environment) =
  var invalid = checkInvalid(env, 3)
  var what = env.past[^1].popLast()
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].seqVal  # this is a copy, not a ref
  if abs(where) > len(target):
    handleError(env, "Attempt to insert" & $what & " outside of " & $target & " at position: " & $where, env.current)
    invalid = true
    if where < 0: 
      where = 0
    else:
      where = len(target)
  if len(target) == 0:
    target.addLast(what)
  else:
    insertLeft(target, what, where)
  env.past[^1][^1].seqVal = target
  setInvalid(env, invalid)
core["insert"].variant.add(CoreObj(args: @["Coll", "Any", "Int"], cmd: doInsert))

proc doInsertSS*(env: var Environment) =
  var invalid = checkInvalid(env, 3)
  var what = env.past[^1].popLast().stringVal
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].stringVal  # this is a copy, not a ref
  if abs(where) > len(target):
    handleError(env, "Attempt to insert" & $what & " outside of " & $target & " at position: " & $where, env.current)
    invalid = true
    if where < 0: 
      where = 0
    else:
      where = len(target)
  if where < 0: 
    where = len(target) + where
  if where == len(target):
    target &= what
  elif where == 0:
    target = what & target
  else:
    target = target[0..<where] & what & target[where..^1]
  env.past[^1][^1].stringVal = target
  setInvalid(env, invalid)
core["insert"].variant.add(CoreObj(args: @["String", "String", "Int"], cmd: doInsertSS))

proc doInsertSC*(env: var Environment) =
  var invalid = checkInvalid(env, 3)
  var what = env.past[^1].popLast().charVal
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].stringVal  # this is a copy, not a ref
  if abs(where) > len(target) or where < 0:
    handleError(env, "Attempt to insert" & $what & " outside of " & $target & " at position: " & $where, env.current)
    invalid = true
    if where < 0: 
      where = 0
    else:
      where = len(target)
  if where < 0: 
    where = len(target) + where
  if where == len(target):
    target &= what
  elif where == 0:
    target = what & target
  else:
    target = target[0..<where] & what & target[where..^1]
  env.past[^1][^1].stringVal = target
  setInvalid(env, invalid)
core["insert"].variant.add(CoreObj(args: @["String", "Char", "Int"], cmd: doInsertSC))


core["delete"] = CoreVars(count:2)      # [1 2 3] delete 1 --> [1 3]
proc doDelete*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].seqVal  # this is a copy, not a ref
  if len(target) == 0:
    handleError(env, "Cannot delete anything from nothing", env.past[^1][^1])
  else:
    if where >= len(target) or where < -len(target):
      handleError(env, "Attempt to delete outside of " & $target & " at position: " & $where, env.current)
      invalid = true
      if where < 0: 
        where = 0
      else:
        where = len(target) - 1
    if where < 0:
      where = len(target) + where
    delFromLeft(target, where)
    env.past[^1][^1].seqval = target
    setInvalid(env, invalid)
core["delete"].variant.add(CoreObj(args: @["Coll", "Int"], cmd: doDelete))

proc doDeleteS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].stringVal  # this is a copy, not a ref
  if len(target) == 0:
    handleError(env, "Cannot delete anything from nothing", env.past[^1][^1])
  else:
    if where >= len(target) or where < -len(target):
      handleError(env, "Attempt to delete outside of " & $target & " at position: " & $where, env.current)
      invalid = true
      if where < 0: 
        where = 0
      else:
        where = len(target) - 1
    if where < 0:
      where = len(target) + where
    if len(target) == 1:
      target = ""
    else:
      if where == 0:
        target = target[1..^1]
      elif where == len(target)-1:
        target = target[0..^2]
      else:
        target = target[0..<where] & target[where+1..^1]
    env.past[^1][^1].stringval = target
    setInvalid(env, invalid)
core["delete"].variant.add(CoreObj(args: @["String", "Int"], cmd: doDeleteS))


core["nth*"] = CoreVars(count:2)      # [1 2 3] nth 1 --> [1 2 3] 2
proc doNthKeep*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].seqVal  # this is a copy, not a ref
  if len(target) == 0:
    handleError(env, "Cannot copy nth* item from nothing", env.past[^1][^1])
    env.past[^1].addLast(newNullNode(true))
  else:
    if abs(where) >= len(target):
      handleError(env, "nth*:  attempt to copy outside of " & $target & " at position: " & $where, env.current)
      invalid = true
      if where < 0: 
        where = 0
      else:
        where = len(target) - 1
    if where < 0:
      where = len(target) + where
    env.past[^1].addLast(target[where])
  setInvalid(env, invalid)
core["nth*"].variant.add(CoreObj(args: @["Coll", "Int"], cmd: doNthKeep))

proc doNthKeepS*(env: var Environment) =  # "ABCDE" nth* 2 --> "ABCDE" B
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].stringVal  # this is a copy, not a ref
  if len(target) == 0:
    handleError(env, "Cannot copy nth* item from nothing", env.past[^1][^1])
    env.past[^1].addLast(newNullNode(true))
  else:
    if abs(where) >= len(target):
      handleError(env, "nth*:  attempt to copy outside of " & $target & " at position: " & $where, env.current)
      invalid = true
      if where < 0: 
        where = 0
      else:
        where = len(target) - 1
    if where < 0:
      where = len(target) + where
    env.past[^1].addLast(newCharNode(target[where]))
    setInvalid(env, invalid)
core["nth*"].variant.add(CoreObj(args: @["String", "Int"], cmd: doNthKeepS))


core["nth"] = CoreVars(count:2)      # [1 2 3] nth 1 --> 2
proc doNth*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  var targetNode = env.past[^1].popLast
  var target = targetNode.seqVal
  if len(target) == 0:
    handleError(env, "Cannot copy nth item from nothing", targetNode)
    env.past[^1].addLast(newNullNode(true))
  else:
    if abs(where) >= len(target):
      handleError(env, "nth:  attempt to copy outside of " & $target & " at position: " & $where, env.current)
      invalid = true
      if where < 0: 
        where = 0
      else:
        where = len(target) - 1
    if where < 0:
      where = len(target) + where
    env.past[^1].addLast(target[where])
  setInvalid(env, invalid)
core["nth"].variant.add(CoreObj(args: @["Coll", "Int"], cmd: doNth))

proc doNthS*(env: var Environment) =  # "ABCDE" nth 1 --> B
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  var targetNode = env.past[^1].popLast()
  var target = targetNode.stringVal  
  if len(target) == 0:
    handleError(env, "Cannot copy nth item from nothing", targetNode)
    env.past[^1].addLast(newNullNode(true))
  else:
    if abs(where) >= len(target):
      handleError(env, "nth:  attempt to copy outside of " & $target & " at position: " & $where, env.current)
      invalid = true
      if where < 0: 
        where = 0
      else:
        where = len(target) - 1
    if where < 0:
      where = len(target) + where
    env.past[^1].addLast(newCharNode(target[where]))
    setInvalid(env, invalid)
core["nth"].variant.add(CoreObj(args: @["String", "Int"], cmd: doNthS))


core["extract"] = CoreVars(count:2)      # [1 2 3] extract 1 --> [1 3] 2
proc doExtract*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].seqVal  # this is a copy, not a ref
  var what: LsNode
  if len(target) == 0:
    handleError(env, "Cannot extract anything from nothing", env.past[^1][^1])
    invalid = true
    setInvalid(env, true)
    what = newNullNode(true)
  elif where >= len(target) or where < -len(target):
    handleError(env, "attempt to extract outside of [" & $target & "] at position: " & $where, env.current)
    invalid = true
    setInvalid(env, true)
    what = newNullNode(true)
  else:
    if where < 0:
      where = len(target) + where
    what = target[where]
    delFromLeft(target, where)
    env.past[^1][^1].seqval = target
    setInvalid(env, invalid)
  env.past[^1].addLast(what)
  setInvalid(env, invalid)
core["extract"].variant.add(CoreObj(args: @["Coll", "Int"], cmd: doExtract))


proc doExtractS*(env: var Environment) =    # "abcdefg" extract 2 -->  "abdefg" `c
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  var target = env.past[^1][^1].stringVal  # this is a copy, not a ref
  var what = newCharNode()
  if len(target) == 0:
    handleError(env, "Cannot extract anything from nothing", env.past[^1][^1])
    setInvalid(env, true)
    what.charVal = '\0'
    invalid = true
  elif where >= len(target) or where < -len(target):
    handleError(env, "attempt to extract outside of '" & target & "' at position: " & $where, env.current)
    setInvalid(env, true)
    what.charVal = '\0'
    invalid = true
  else:
    if where < 0:
      where = len(target) + where
    what.charVal = target[where]
    if len(env.past[^1][^1].stringval) > 1:
        if where == 0:
          env.past[^1][^1].stringval = env.past[^1][^1].stringval[1..^1]
        elif where == len(env.past[^1][^1].stringval) - 1:
          env.past[^1][^1].stringval = env.past[^1][^1].stringval[0..^2]
        else:
          env.past[^1][^1].stringval = env.past[^1][^1].stringval[0..<where] & env.past[^1][^1].stringval[where+1 .. ^1]
    else:
      env.past[^1][^1].stringval = ""
    setInvalid(env, invalid)
  env.past[^1].addLast(what)
  setInvalid(env, invalid)
core["extract"].variant.add(CoreObj(args: @["String", "Int"], cmd: doExtractS))


core["extract*"] = CoreVars(count:2)      # [1 2 3] extract* 1 --> [1 2 3] [1 3] 2
proc doExtractKeep*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  env.past[^1].addLast(deepCopy(env.past[^1][^1]))
  var target = env.past[^1][^1].seqVal  # this is a copy, not a ref
  var what: LsNode
  if len(target) == 0:
    handleError(env, "Cannot extract* anything from nothing", env.past[^1][^1])
    invalid = true
    setInvalid(env, true)
    what = newNullNode(true)
  elif where >= len(target) or where < -len(target):
    handleError(env, "attempt to extract* outside of [" & $target & "] at position: " & $where, env.current)
    invalid = true
    setInvalid(env, true)
    what = newNullNode(true)
  else:
    if where < 0:
      where = len(target) + where
    what = target[where]
    delFromLeft(target, where)
    env.past[^1][^1].seqval = target
    setInvalid(env, invalid)
  env.past[^1].addLast(what)
  setInvalid(env, invalid)
core["extract*"].variant.add(CoreObj(args: @["Coll", "Int"], cmd: doExtractKeep))

proc doExtractKeepS*(env: var Environment) =    # "abcdefg" extract* 2 -->  "abcdefg" "abdefg" `c
  var invalid = checkInvalid(env, 2)
  var where = env.past[^1].popLast().intVal
  env.past[^1].addLast(deepCopy(env.past[^1][^1]))
  var target = env.past[^1][^1].stringVal  # this is a copy, not a ref
  var what = newCharNode()
  if len(target) == 0:
    handleError(env, "Cannot extract* anything from nothing", env.past[^1][^1])
    setInvalid(env, true)
    what.charVal = '\0'
    invalid = true
  elif where >= len(target) or where < -len(target):
    handleError(env, "attempt to extract* outside of '" & target & "' at position: " & $where, env.current)
    setInvalid(env, true)
    what.charVal = '\0'
    invalid = true
  else:
    if where < 0:
      where = len(target) + where
    what.charVal = target[where]
    if len(env.past[^1][^1].stringval) > 1:
        if where == 0:
          env.past[^1][^1].stringval = env.past[^1][^1].stringval[1..^1]
        elif where == len(env.past[^1][^1].stringval) - 1:
          env.past[^1][^1].stringval = env.past[^1][^1].stringval[0..^2]
        else:
          env.past[^1][^1].stringval = env.past[^1][^1].stringval[0..<where] & env.past[^1][^1].stringval[where+1 .. ^1]
    else:
      env.past[^1][^1].stringval = ""
    setInvalid(env, invalid)
  env.past[^1].addLast(what)
  setInvalid(env, invalid)
core["extract*"].variant.add(CoreObj(args: @["String", "Int"], cmd: doExtractKeepS)) 


core[">list"] = CoreVars(count:1)      # {1 2 3} >list --> [1 2 3]
proc doToList*(env: var Environment) =
  env.past[^1][^1].nodeType = List
core[">list"].variant.add(CoreObj(args: @["Coll"], cmd: doToList))

proc doToListI*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast()
  env.past[^1].addLast(newListNode())
  env.past[^1][^1].addLast(this)
  setInvalid(env, invalid)
core[">list"].variant.add(CoreObj(args: @["Item"], cmd: doToListI))
core[">list"].variant.add(CoreObj(args: @["Null"], cmd: doToListI))


core[">block"] = CoreVars(count:1)      # [1 2 3] >block --> {1 2 3}
proc doToBlock*(env: var Environment) =
  env.past[^1][^1].nodeType = Block
core[">block"].variant.add(CoreObj(args: @["Coll"], cmd: doToBlock))

proc doToBlockI*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast()
  env.past[^1].addLast(newBlockNode())
  env.past[^1][^1].seqVal.addLast(this)
  setInvalid(env, invalid)
core[">block"].variant.add(CoreObj(args: @["Item"], cmd: doToBlockI))
core[">block"].variant.add(CoreObj(args: @["Null"], cmd: doToBlockI))

core[">seq"] = CoreVars(count:1)      # {1 2 3} >coll --> (1 2 3)
proc doToSeq*(env: var Environment) =
  env.past[^1][^1].nodeType = Seq
core[">seq"].variant.add(CoreObj(args: @["Coll"], cmd: doToSeq))

proc doToSeqI*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast()
  env.past[^1].addLast(newSeqNode())
  env.past[^1][^1].seqVal.addLast(this)
  setInvalid(env, invalid)
core[">seq"].variant.add(CoreObj(args: @["Item"], cmd: doToSeqI))
core[">seq"].variant.add(CoreObj(args: @["Null"], cmd: doToSeqI))

core[">string"] = CoreVars(count:1)      # `a >string --> "a"
proc doToString*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast()
  env.past[^1].addLast(newStringNode($this))
  setInvalid(env, invalid)
core[">string"].variant.add(CoreObj(args: @["Any"], cmd: doToString))

core[">word"] = CoreVars(count:1)      # `a >string --> "a"
proc doToWord*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast()
  if this.nodeType == Word:
    discard
  elif this.nodeType == String:
    var thisName = this.stringval
    if not wordVerify(thisName):
      handleError(env, ">word expected a string with a valid name, not: " & $this, this)
    else:
      var thisFix = Infix
      if thisName in immediates:
        thisFix = Immediate
      elif thisname[0] == '.':
        thisFix = Postfix
      elif thisName[^1] == ':':
        thisFix = Prefix
      env.past[^1].addLast(newWordNode(thisName, thisFix))
      setInvalid(env, invalid)
core[">word"].variant.add(CoreObj(args: @["String"], cmd: doToWord))
core[">word"].variant.add(CoreObj(args: @["Word"], cmd: doToWord))

core[">char"] = CoreVars(count:1)      # "a" >char --> `a
proc doToChar*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast().stringVal
  var what: char
  if len(this) == 1:
    what = this[0]
  else:
    handleError(env, ">char only woks on strings of length one, not: " & this, env.current)
    invalid = true
    if len(this) == 0:
      what = '\0'
    else: 
      what = this[0]
  env.past[^1].addLast(newCharNode(what))
  setInvalid(env, invalid)
core[">char"].variant.add(CoreObj(args: @["String"], cmd: doToChar))

proc doToCharI*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast().intVal
  var what: char
  if this < 0 or this > 127:
    handleError(env, ">char only woks on integers between 0 and 127, not: " & $this, env.current)
    invalid = true
    what = '\0'
  else:
    what = char(this)
  env.past[^1].addLast(newCharNode(what))
  setInvalid(env, invalid)
core[">char"].variant.add(CoreObj(args: @["Int"], cmd: doToCharI))


core[">num"] = CoreVars(count:1)      # "3.13" >num --> 3.14
proc doToNum*(env: var Environment) = # "42" >num --> 42
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast().stringVal
  this = this.strip()
  var good = true
  for item in this:   # make sure string looks like a number
    if item notIn digits + {'.', '_', '-'}:
      good = false
      invalid = true
  var howManyDots = this.count('.')  
  var howManyDashes = this.count('-')
  if howManyDots > 1 or howManyDashes > 1:
    good = false
  elif howManyDashes == 1 and this[0] != '-':
    good = false
  if good:
    if howManyDots == 0:
      env.past[^1].addLast(newIntNode(parseInt(this)))
    else:
      env.past[^1].addLast(newFloatNode(parseFloat(this)))
    setInvalid(env, invalid)
  else:
    handleError(env, ">num expected a string representation of a number, not: " & this, env.current)
    env.past[^1].addLast(newNullNode(true))
core[">num"].variant.add(CoreObj(args: @["String"], cmd: doToNum))

proc doToNumChar*(env: var Environment) = # `A >num --> 65
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast().charVal
  if this in digits:
    env.past[^1].addLast(newIntNode(ord(this) - ord('0')))
    setInvalid(env, invalid)
  else:
    handleError(env, ">num expected a character representation of a digit, not: " & this, env.current)
    env.past[^1].addLast(newNullNode(true))
core[">num"].variant.add(CoreObj(args: @["Char"], cmd: doToNumChar))


core["ord"] = CoreVars(count:1)      # `A --> 65
proc doOrdChar*(env: var Environment) = # `1 >num --> 1
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast().charVal
  env.past[^1].addLast(newIntNode(ord(this)))
  setInvalid(env, invalid)
core["ord"].variant.add(CoreObj(args: @["Char"], cmd: doOrdChar))


core["num_string?"] = CoreVars(count:1)      # "3.13" num_string? --> true
proc doNumStringQ*(env: var Environment) =   # "42" num_string? --> true
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast().stringVal
  this = this.strip()
  var good = true
  for item in this:   # make sure string looks like a number
    if item notIn digits + {'.', '_', '-'}:
      good = false
      invalid = true
  var howManyDots = this.count('.')  
  var howManyDashes = this.count('-')
  if howManyDots > 1 or howManyDashes > 1:
    good = false
  elif howManyDashes == 1 and this[0] != '-':
    good = false
  env.past[^1].addLast(newBoolNode(good))
  setInvalid(env, invalid)
core["num_string?"].variant.add(CoreObj(args: @["String"], cmd: doNumStringQ))

core["digit?"] = CoreVars(count:1)      # `5 digit? --> true
proc doDigitQ*(env: var Environment) = 
  var invalid = checkInvalid(env, 1)
  var this = env.past[^1].popLast().charVal
  var isDigit = this in digits
  env.past[^1].addLast(newBoolNode(isDigit))
  setInvalid(env, invalid)
core[">num"].variant.add(CoreObj(args: @["Char"], cmd: doToNumChar))

core["reverse"] = CoreVars(count: 1)
proc doReverse*(env: var Environment) =
  var revSeq = env.past[^1][^1].seqVal.reversed()
  env.past[^1][^1].seqVal = revSeq
core["reverse"].variant.add(CoreObj(args: @["Coll"], cmd: doReverse))

proc doReverseS*(env: var Environment) =
  var oldStr = env.past[^1][^1].stringVal
  var newStr = ""
  for c in oldStr:
    newStr = c & newStr
  env.past[^1][^1].stringVal = newStr
core["reverse"].variant.add(CoreObj(args: @["String"], cmd: doReverseS))

core["sort"] = CoreVars(count: 1)     # [1 5 3 4 2] sort --> [1 2 3 4 5]
proc doSort*(env: var Environment) =  
  if len(env.past[^1][^1].seqVal) > 0:
    var target = env.past[^1][^1].seqVal
    var sortedList = lsSorted(target)
    env.past[^1][^1].seqVal = sortedList
core["sort"].variant.add(CoreObj(args: @["Coll"], cmd: doSort))

core["zip"] = CoreVars(count: 2)      # [1 3 5] [2 4 6 8 10] .zip --> [[1 2][3 4][5 6]]
proc doZip*(env: var Environment) =   # drops extras from longer sequence
  var invalid = checkInvalid(env, 2)  
  var seqB = env.past[^1].popLast().seqVal
  var seqA = env.past[^1].popLast().seqVal
  let howMany = min(len(seqA), len(seqB))
  var newList = newListNode()
  var subList = newListNode()
  if howMany > 0:
    for count in 0 ..< howMany:
      sublist.addFirst(seqA[count])
      sublist.addLast(seqB[count])
      newList.addLast(sublist)
      subList = newListNode()
  env.past[^1].addLast(newList)
  setInvalid(env, invalid)
core["zip"].variant.add(CoreObj(args: @["Coll", "Coll"], cmd: doZip))

proc doZipS*(env: var Environment) =    # drops extras from longer string
  var invalid = checkInvalid(env, 2) 
  var strB = env.past[^1].popLast().stringVal
  var strA = env.past[^1].popLast().stringVal
  let howMany = min(len(strA), len(strB))
  var newStr = ""
  if howMany > 0:
    for count in 0 ..< howMany:
      newStr &= strA[count]
      newStr &= strB[count]
  env.past[^1].addLast(newStringNode(newStr))
  setInvalid(env, invalid)
core["zip"].variant.add(CoreObj(args: @["String", "String"], cmd: doZipS))

core["unzip"] = CoreVars(count: 1)      # [[1 2] [3 4] [5 6] [7 8 9] 10] unzip --> [1 3 5] [2 4 6]
proc doUnZip*(env: var Environment) =
  var invalidA, invalidB = checkInvalid(env, 1)
  var zipped = env.past[^1].popLast().seqVal
  var newListA = newListNode()
  var newListB = newListNode()
  if len(zipped)  > 0:
    for pairing in zipped:
      if pairing.nodeType in typeMap["Coll"] and len(pairing) == 2:
        newListA.addLast(pairing.seqVal[0])
        invalidA = invalidA or pairing.seqVal[0].invalid
        newListB.addLast(pairing.seqVal[1])
        invalidA = invalidB or pairing.seqVal[1].invalid
      else:
        break 
  env.past[^1].addLast(newListA)
  setInvalid(env, invalidA)
  env.past[^1].addLast(newListB)
  setInvalid(env, invalidB)
core["unzip"].variant.add(CoreObj(args: @["Coll"], cmd: doUnZip))

proc doUnZipS*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var thing = env.past[^1].popLast()
  var zipStr = thing.stringval
  var new1, new2 = ""
  if len(zipStr) mod 2 == 1:
    zipStr = zipStr[0..^2]
  var howMany = len(zipStr) div 2
  for count in 0..<howMany:
    new1 &= zipStr[2 * count]
    new2 &= zipStr[2 * count + 1]
  env.past[^1].addLast(newStringNode(new1))
  setInvalid(env, invalid)
  env.past[^1].addLast(newStringNode(new2))
  setInvalid(env, invalid)
core["unzip"].variant.add(CoreObj(args: @["String"], cmd: doUnZipS))

core["range"] = CoreVars(count: 2)      # 0 3 .range --> [0 1 2 3]
proc doRangeI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let stop = env.past[^1].popLast().intVal
  let start = env.past[^1].popLast().intVal
  var newList = newListNode()
  if stop >= start:
    for count in countup(start, stop):
      newList.addLast(newIntNode(count))
  else:
    for count in countdown(start, stop):
      newList.addLast(newIntNode(count))
  env.past[^1].addLast(newList)
  setInvalid(env, invalid)
core["range"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doRangeI))

proc doRangeC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let stop = env.past[^1].popLast().charVal
  let start = env.past[^1].popLast().charVal
  var newList = newListNode()
  if stop >= start:
    for count in countup(start, stop):
      newList.addLast(newCharNode(count))
  else:
    for count in countdown(start, stop):
      newList.addLast(newCharNode(count))
  env.past[^1].addLast(newList)
  setInvalid(env, invalid)
core["range"].variant.add(CoreObj(args: @["Char", "Char"], cmd: doRangeC))

core["range<"] = CoreVars(count: 2)      # 0 3 .range< --> [0 1 2]
proc doRangeILT*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var stop = env.past[^1].popLast().intVal
  let start = env.past[^1].popLast().intVal
  var newList = newListNode()
  if stop == start:
    discard
  elif stop > start:
    dec stop
    for count in countup(start, stop):
      newList.addLast(newIntNode(count))
  else:
    inc stop
    for count in countdown(start, stop):
      newList.addLast(newIntNode(count))
  env.past[^1].addLast(newList)
  setInvalid(env, invalid)
core["range<"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doRangeILT))

proc doRangeCLT*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var stop = env.past[^1].popLast().charVal
  let start = env.past[^1].popLast().charVal
  var newList = newListNode()
  if stop == start:
    discard
  elif stop > start:
    dec stop
    for count in countup(start, stop):
      newList.addLast(newCharNode(count))
  else:
    inc stop
    for count in countdown(start, stop):
      newList.addLast(newCharNode(count))
  env.past[^1].addLast(newList)
  setInvalid(env, invalid)
core["range<"].variant.add(CoreObj(args: @["Char", "Char"], cmd: doRangeCLT))

core["..."] = CoreVars(count: -1)      # 0 ... 3 --> [0 1 2 3]    special immediate word
proc doRangeDots*(env: var Environment) =
  env.future.insertLeft(newWordNode("range", fix = Postfix), 1)
core["..."].variant.add(CoreObj(args: @["Int"], cmd: doRangeDots))
core["..."].variant.add(CoreObj(args: @["Char"], cmd: doRangeDots))

core["..<"] = CoreVars(count: -1)      # 0 ... <3  --> [0 1 2]
proc doRangeDotsLT*(env: var Environment) =
  env.future.insertLeft(newWordNode("range<", fix = Postfix), 1)
core["..<"].variant.add(CoreObj(args: @["Int"], cmd: doRangeDotsLT))
core["..<"].variant.add(CoreObj(args: @["Char"], cmd: doRangeDotsLT))


core["in"] = CoreVars(count: 2)      # 2 in [1 2 3] --> true
proc doIn*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var target = env.past[^1].popLast()
  var what = env.past[^1].popLast()
  var found = false
  if len(target) > 0:
    for item in target.seqVal:
      env.past[^1].addLast(what)
      env.past[^1].addLast(item)
      doEqEq(env)
      if env.past[^1].popLast().boolVal:
        found = true
        break
  env.past[^1].addLast(newBoolNode(found))
  setInvalid(env, invalid)
core["in"].variant.add(CoreObj(args: @["Item", "Coll"], cmd: doIn))
core["in"].variant.add(CoreObj(args: @["Coll", "Coll"], cmd: doIn))

proc doInSC*(env: var Environment) =   # `r in "string" --> true
  var invalid = checkInvalid(env, 2)
  var target = env.past[^1].popLast()
  var what = env.past[^1].popLast()
  var found = false
  if len(target.stringVal) > 0:
    found = target.stringVal.find(what.charVal) >= 0
  env.past[^1].addLast(newBoolNode(found))
  setInvalid(env, invalid)
core["in"].variant.add(CoreObj(args: @["Char", "String"], cmd: doInSC))

proc doInSS*(env: var Environment) =   # `r in "string" --> true
  var invalid = checkInvalid(env, 2)
  var target = env.past[^1].popLast()
  var what = env.past[^1].popLast()
  var found = false
  if len(target.stringVal) > 0:
    found = target.stringVal.find(what.stringVal) >= 0
  env.past[^1].addLast(newBoolNode(found))
  setInvalid(env, invalid)
core["in"].variant.add(CoreObj(args: @["String", "String"], cmd: doInSS))


core["where"] = CoreVars(count: 2)      # 2 where [1 2 3] --> 1
proc doWhere*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  var target = env.past[^1].popLast()
  var what = env.past[^1].popLast()
  var where = -1
  if len(target) > 0:
    for count, item in target.seqVal:
      env.past[^1].addLast(what)
      env.past[^1].addLast(item)
      doEqEq(env)
      if env.past[^1].popLast().boolVal:
        where = count
  env.past[^1].addLast(newIntNode(where))
  setInvalid(env, invalid)
core["where"].variant.add(CoreObj(args: @["Item", "Coll"], cmd: doWhere))
core["where"].variant.add(CoreObj(args: @["Coll", "Coll"], cmd: doWhere))

proc doWhereCS*(env: var Environment) =   # `r where "string" --> 3
  var invalid = checkInvalid(env, 2)
  var target = env.past[^1].popLast().stringVal
  var what = env.past[^1].popLast().charVal
  var found = -1
  if len(target) > 0:
    found = target.find(what)
  env.past[^1].addLast(newIntNode(found))
  setInvalid(env, invalid)
core["where"].variant.add(CoreObj(args: @["Char", "String"], cmd: doWhereCS))

proc doWhereSS*(env: var Environment) =   # "r" where "string" --> 2
  var invalid = checkInvalid(env, 2)
  var target = env.past[^1].popLast().stringVal
  var what = env.past[^1].popLast().stringVal
  var found = -1
  if len(target) > 0:
    found = target.find(what)
  env.past[^1].addLast(newIntNode(found))
  setInvalid(env, invalid)
core["where"].variant.add(CoreObj(args: @["String", "String"], cmd: doWhereSS))


core["string>list_char"] = CoreVars(count: 1) 
proc doStringToListChar*(env: var Environment) =   # "hello" str>list --> [`h, `e, `l, `l, `o]
  var invalid = checkInvalid(env, 1)
  var what = env.past[^1].popLast().stringVal
  var target = newListNode()
  for c in what:
    target.addLast(newCharNode(c))
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["string>list_char"].variant.add(CoreObj(args: @["String"], cmd: doStringToListChar))

core["string>list_word"] = CoreVars(count: 1) 
proc doStringToListWord*(env: var Environment) =   # "hello there" str>list --> ["hello", "there""]
  var invalid = checkInvalid(env, 1)
  var what = env.past[^1].popLast().stringVal
  var target = newListNode()
  for item in what.splitwhitespace():
    target.addLast(newStringNode(item))
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["string>list_word"].variant.add(CoreObj(args: @["String"], cmd: doStringToListWord))

core["string>list_word_sep"] = CoreVars(count: 2) 
proc doStringToListWordSepChar*(env: var Environment) =   # "hello:there" `: str>list --> ["hello", "there""]
  var invalid = checkInvalid(env, 2)
  let sep = env.past[^1].popLast().charVal
  var what = env.past[^1].popLast().stringVal
  var target = newListNode()
  for item in what.split(sep):
    target.addLast(newStringNode(item))
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["string>list_word_sep"].variant.add(CoreObj(args: @["String", "Char"], cmd: doStringToListWordSepChar))

proc doStringToListWordSepString*(env: var Environment) =   # "hello there" " " str>list --> ["hello", "there""]
  var invalid = checkInvalid(env, 2)
  let sep = env.past[^1].popLast().stringVal
  var what = env.past[^1].popLast().stringVal
  var target = newListNode()
  for item in what.split(sep):
    target.addLast(newStringNode(item))
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["string>list_word_sep"].variant.add(CoreObj(args: @["String", "String"], cmd: doStringToListWordSepString))


core["list_char>string"] = CoreVars(count: 1) 
proc doListCharToString*(env: var Environment) =   # [`h, `e, `l, `l, `o] list>string --> "hello"
  var what = env.past[^1].popLast()
  var invalid = checkInvalid(what)
  var target = newStringNode()
  var good = true
  for item in what.seqVal:
    if item.nodeType == Char:
      target.stringVal &= item.charVal
    else:
      good = false
      invalid = true
      handleError(env, "list_char>string expected a list of characters, found: " & $item, what)
      break
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["list_char>string"].variant.add(CoreObj(args: @["Coll"], cmd: doListCharToString))

core["list_word>string"] = CoreVars(count: 1) 
proc doListWordToString*(env: var Environment) =   # ["hello", "there"] list_word>string --> "hellothere"
  var what = env.past[^1].popLast()
  var invalid = checkInvalid(what)
  var target = newStringNode()
  var good = true
  for item in what.seqVal:
    if item.nodeType == String:
      target.stringVal &= item.stringVal
    else:
      good = false
      invalid = true
      handleError(env, "list_word>string expected a list of strings, found: " & $item, what)
      break
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["list_word>string"].variant.add(CoreObj(args: @["Coll"], cmd: doListWordToString))

core["list_word>string_space"] = CoreVars(count: 1) 
proc doListWordToStringSpace*(env: var Environment) =   # ["hello", "there"] list_word>string --> "hello there"
  var what = env.past[^1].popLast()
  var invalid = checkInvalid(what)
  var target = newStringNode()
  var good = true
  for count, item in what.seqVal:
    if item.nodeType == String:
      target.stringVal &= item.stringVal
      if count < len(what) - 1:
        target.stringVal &= " "
    else:
      good = false
      invalid = true
      handleError(env, "list_word>string expected a list of strings, found: " & $item, what)
      break
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["list_word>string_space"].variant.add(CoreObj(args: @["Coll"], cmd: doListWordToStringSpace))

core["list_word>string_sep"] = CoreVars(count: 2) 
proc doListWordToStringSepChar*(env: var Environment) =   # ["hello", "there"] `: list_word>string --> "hello:there"
  var invalid = checkInvalid(env, 2)
  let sep = env.past[^1].popLast().charVal
  var what = env.past[^1].popLast()
  invalid = invalid or checkInvalid(what)
  var target = newStringNode()
  var good = true
  for count, item in what.seqVal:
    if item.nodeType == String:
      target.stringVal &= item.stringVal
      if count < len(what) - 1:
        target.stringVal &= sep
    else:
      good = false
      invalid = true
      handleError(env, "list_word>string expected a list of strings, found: " & $item, what)
      break
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["list_word>string_sep"].variant.add(CoreObj(args: @["Coll", "Char"], cmd: doListWordToStringSepChar))

proc doListWordToStringSepString*(env: var Environment) =   # ["hello", "there"] `: list_word>string --> "hello:there"
  var invalid = checkInvalid(env, 2)
  let sep = env.past[^1].popLast().stringVal
  var what = env.past[^1].popLast()
  invalid = invalid or checkInvalid(what)
  var target = newStringNode()
  var good = true
  for count, item in what.seqVal:
    if item.nodeType == String:
      target.stringVal &= item.stringVal
      if count < len(what) - 1:
        target.stringVal &= sep
    else:
      good = false
      invalid = true
      handleError(env, "list_word>string expected a list of strings, found: " & $item, what)
      break
  env.past[^1].addLast(target)  
  setInvalid(env, invalid)
core["list_word>string_sep"].variant.add(CoreObj(args: @["Coll", "String"], cmd: doListWordToStringSepString))


core["slice"] = CoreVars(count:3)      # [1 2 3 4 5] slice 2 3 --> [3 4]
proc doSlice*(env: var Environment) =
  var invalid = checkInvalid(env, 3)
  var stop = env.past[^1].popLast().intVal
  var start = env.past[^1].popLast().intVal
  var targetNode = env.past[^1][^1]
  var target = targetNode.seqVal
  var newSeq: LsSeq
  if len(target) == 0:
    handleError(env, "Cannot slice anything from nothing", env.past[^1][^1])
    invalid = true
  elif start >= len(target) or start < -len(target):
    handleError(env, "attempt to start slice outside of [" & $target & "] at position: " & $start, env.current)
    invalid = true
  elif stop >= len(target) or stop < -len(target):
    handleError(env, "attempt to stop slice outside of [" & $target & "] at position: " & $stop, env.current)
    invalid = true
  else:
    if start < 0:
      start = len(target) + start
    if stop < 0:
      stop = len(target) + stop
    if stop >= start:
      for i in start..stop:
        newSeq.addLast(target[i])
    else:
      for i in stop..start:
        newSeq.addFirst(target[i])  # reverses
  targetNode.seqval = newSeq
  setInvalid(env, invalid)
core["slice"].variant.add(CoreObj(args: @["Coll", "Int", "Int"], cmd: doSlice))


proc doSliceS*(env: var Environment) =    # "abcdefg" slice 2 4 -->  "cde"
  var invalid = checkInvalid(env, 3)
  var stop = env.past[^1].popLast().intVal
  var start = env.past[^1].popLast().intVal
  var targetNode = env.past[^1][^1]
  var target = targetNode.stringVal
  var newString: string = ""
  if len(target) == 0:
    handleError(env, "Cannot slice anything from nothing", env.past[^1][^1])
    invalid = true
  elif start >= len(target) or start < -len(target):
    handleError(env, "attempt to start slice outside of '" & target & "' at position: " & $start, env.current)
    invalid = true
  elif stop >= len(target) or stop < -len(target):
    handleError(env, "attempt to stop slice outside of '" & target & "' at position: " & $stop, env.current)
    invalid = true
  else:
    if start < 0:
      start = len(target) + start
    if stop < 0:
      stop = len(target) + stop
    if stop >= start:
      newString = target[start..stop]
    else:
      for c in target[stop..start]:
        newString = c & newString
  targetNode.stringVal = newString
  setInvalid(env, invalid)
core["slice"].variant.add(CoreObj(args: @["String", "Int", "Int"], cmd: doSliceS))


core["slice*"] = CoreVars(count:3)      # [1 2 3 4 5] slice* 2 3 --> [1 2 3 4 5] [3 4]
proc doSliceKeep*(env: var Environment) =
  var invalid = checkInvalid(env, 3)
  var stop = env.past[^1].popLast().intVal
  var start = env.past[^1].popLast().intVal
  env.past[^1].addLast(deepCopy(env.past[^1][^1]))
  var targetNode = env.past[^1][^1]
  var target = targetNode.seqVal
  var newSeq: LsSeq
  if len(target) == 0:
    handleError(env, "Cannot slice* anything from nothing", env.past[^1][^1])
    invalid = true
  elif start >= len(target) or start < -len(target):
    handleError(env, "attempt to start slice* outside of [" & $target & "] at position: " & $start, env.current)
    invalid = true
  elif stop >= len(target) or stop < -len(target):
    handleError(env, "attempt to stop slice* outside of [" & $target & "] at position: " & $stop, env.current)
    invalid = true
  else:
    if start < 0:
      start = len(target) + start
    if stop < 0:
      stop = len(target) + stop
    if stop >= start:
      for i in start..stop:
        newSeq.addLast(target[i])
    else:
      for i in stop..start:
        newSeq.addFirst(target[i])  # reverses list
  targetNode.seqval = newSeq
  setInvalid(env, invalid)
core["slice*"].variant.add(CoreObj(args: @["Coll", "Int", "Int"], cmd: doSliceKeep))

proc doSliceKeepS*(env: var Environment) =    # "abcdefg" slice* 2 4 -->  "abcdefg" "cde"
  var invalid = checkInvalid(env, 3)
  var stop = env.past[^1].popLast().intVal
  var start = env.past[^1].popLast().intVal
  env.past[^1].addLast(deepCopy(env.past[^1][^1]))
  var targetNode = env.past[^1][^1]
  var target = targetNode.stringVal
  var newString: string = ""
  if len(target) == 0:
    handleError(env, "Cannot slice* anything from nothing", env.past[^1][^1])
    invalid = true
  elif start >= len(target) or start < -len(target):
    handleError(env, "attempt to start slice* outside of '" & target & "' at position: " & $start, env.current)
    invalid = true
  elif stop >= len(target) or stop < -len(target):
    handleError(env, "attempt to stop slice* outside of '" & target & "' at position: " & $stop, env.current)
    invalid = true
  else:
    if start < 0:
      start = len(target) + start
    if stop < 0:
      stop = len(target) + stop
    if stop >= start:
      newString = target[start..stop]
    else:
      for c in target[stop..start]:
        newString = c & newString
  targetNode.stringVal = newString
  setInvalid(env, invalid)
core["slice*"].variant.add(CoreObj(args: @["String", "Int", "Int"], cmd: doSliceKeepS))


core["empty"] = CoreVars(count:1)      # [1 2 3 4 5] empty --> []
proc doEmpty*(env: var Environment) =
  env.past[^1][^1].seqVal = newLsSeq()
core["empty"].variant.add(CoreObj(args: @["Coll"], cmd: doEmpty))

proc doEmptyS*(env: var Environment) =
  env.past[^1][^1].stringVal = ""
core["empty"].variant.add(CoreObj(args: @["String"], cmd: doEmptyS))