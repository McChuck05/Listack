## lscorebitwise
## Listack 0.4.0

import std/deques, std/tables, std/bitops
import lstypes,  lstypehelpers, lsconfig
# import os, std/strutils, std/sequtils, std/terminal, std/math
# import lstypeprint, lsparser

core["bit_and"] = CoreVars(count: 2)
proc doBitAnd*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast().intVal
  let a = env.past[^1].popLast().intVal
  try:
    env.past[^1].addLast(newIntNode(a and b))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_and error: " & $getCurrentException().name, env.current)
core["bit_and"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doBitAnd))

proc doBitAndOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_and error, illegal type combination: " & $a & $b
  handleError(env, errmsg, env.current)
core["bit_and"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitAndOther))


core["bit_or"] = CoreVars(count: 2)
proc doBitOr*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast().intVal
  let a = env.past[^1].popLast().intVal
  try:
    env.past[^1].addLast(newIntNode(a or b))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_or error: " & $getCurrentException().name, env.current)
core["bit_or"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doBitOr))

proc doBitOrOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_or error, illegal type combination: " & $a & $b
  handleError(env, errmsg, env.current)
core["bit_or"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitOrOther))


core["bit_xor"] = CoreVars(count: 2)
proc doBitXOr*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast().intVal
  let a = env.past[^1].popLast().intVal
  try:
    env.past[^1].addLast(newIntNode(a xor b))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_xor error: " & $getCurrentException().name, env.current)
core["bit_xor"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doBitXOr))

proc doBitXOrOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_xor error, illegal type combination: " & $a & $b
  handleError(env, errmsg, env.current)
core["bit_xor"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitXOrOther))


core["bit_nand"] = CoreVars(count: 2)
proc doBitNAnd*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast().intVal
  let a = env.past[^1].popLast().intVal
  try:
    env.past[^1].addLast(newIntNode(not(a and b)))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_nand error: " & $getCurrentException().name, env.current)
core["bit_nand"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doBitNAnd))

proc doBitNAndOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_nand error, illegal type combination: " & $a & $b
  handleError(env, errmsg, env.current)
core["bit_nand"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitNAndOther))


core["bit_nor"] = CoreVars(count: 2)
proc doBitNor*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast().intVal
  let a = env.past[^1].popLast().intVal
  try:
    env.past[^1].addLast(newIntNode(not(a or b)))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_nor error: " & $getCurrentException().name, env.current)
core["bit_nor"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doBitNor))

proc doBitNOrOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_nor error, illegal type combination: " & $a & $b
  handleError(env, errmsg, env.current)
core["bit_nor"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitNorOther))


core["bit_not"] = CoreVars(count: 1)
proc doBitNot*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast().intVal
  try:
    env.past[^1].addLast(newIntNode(not a))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_not error: " & $getCurrentException().name, env.current)
core["bit_not"].variant.add(CoreObj(args: @["Int"], cmd: doBitNot))

proc doBitNotOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_not error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["bit_not"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitNotOther))


core["bit_<<"] = CoreVars(count: 2)   # shift a left b bits
proc doBitLeft*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b= env.past[^1].popLast().intVal
  let a = env.past[^1].popLast().intVal
  try:
    env.past[^1].addLast(newIntNode(a.shl(b)))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_<< error: " & $getCurrentException().name, env.current)
core["bit_<<"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doBitLeft))

proc doBitLeftOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_<< error, illegal type combination: " & $a & $b
  handleError(env, errmsg, env.current)
core["bit_<<"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitLeftOther))


core["bit_>>"] = CoreVars(count: 2)   # shift a right b bits
proc doBitRight*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b= env.past[^1].popLast().intVal
  let a = env.past[^1].popLast().intVal
  try:
    env.past[^1].addLast(newIntNode(a.shr(b)))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_>> error: " & $getCurrentException().name, env.current)
core["bit_>>"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doBitRight))

proc doBitRightOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_>> error, illegal type combination: " & $a & $b
  handleError(env, errmsg, env.current)
core["bit_>>"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitRightOther))


core["bit_rev"] = CoreVars(count: 1)
proc doBitRev*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast().intVal
  try:
    var b = int64(reverseBits(uint64(a)))
    env.past[^1].addLast(newIntNode(b))
    setInvalid(env, invalid)
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "bit_rev error: " & $getCurrentException().name, env.current)
core["bit_rev"].variant.add(CoreObj(args: @["Int"], cmd: doBitRev))

proc doBitRevOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "bit_rev error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["bit_rev"].variant.add(CoreObj(args: @["Otherwise"], cmd: doBitRevOther))
