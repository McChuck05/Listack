## lscoremath
## Listack 0.4.0

import std/deques, std/tables, std/strutils, std/math
import lstypes,  lstypehelpers, lsconfig
# import os, std/sequtils, std/terminal
# import lsparser, lstypeprint

when isMainModule:
  var env = initEnvironment()

# ArithmeticDefect* = object of Defect
    # Raised if any kind of arithmetic error occurred.
# DivByZeroDefect* = object of ArithmeticDefect 
    # Raised for runtime integer divide-by-zero errors.
# OverflowDefect* = object of ArithmeticDefect
    # Raised for runtime integer overflows.
    
# FloatingPointDefect* = object of Defect 
    # Base class for floating point exceptions.
# FloatInvalidOpDefect* = object of FloatingPointDefect 
    # Raised by invalid operations according to IEEE.
    # Raised by `0.0/0.0`, for example.
# FloatDivByZeroDefect* = object of FloatingPointDefect 
    # Raised by division by zero.
    # Divisor is zero and dividend is a finite nonzero number.
# FloatOverflowDefect* = object of FloatingPointDefect 
    # Raised for overflows.
    # The operation produced a result that exceeds the range of the exponent.
# FloatUnderflowDefect* = object of FloatingPointDefect 
    # Raised for underflows.
    # The operation produced a result that is too small to be represented as a
    # normal number.
# FloatInexactDefect* = object of FloatingPointDefect 
    # Raised for inexact results.
    # The operation produced a result that cannot be represented with infinite
    # precision -- for example: `2.0 / 3.0, log(1.1)`
    # **Note**: Nim currently does not detect these!

const highInt* = high(int64)
const lowInt* = low(int64)
const highFloat* = 1.7976931348623157E+308
const lowFloat* = -1.7976931348623157E+308
const minPosFloat* = MinFloatNormal   # 2.225073858507201e-308
const minNegFloat* = -MinFloatNormal  # -2.225073858507201e-308


core["+"] = CoreVars(count: 2)
proc doAddI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.intVal
  try:
    env.past[^1].addLast(newIntNode(av + bv))
    setInvalid(env, invalid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "+ error: " & $getCurrentException().name, env.current)
core["+"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doAddI))

proc doAddF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: float
  var bv: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  if b.nodeType == Int:
    bv = float(b.intVal)
  else:
    bv = b.floatVal
  try:
    env.past[^1].addLast(newFloatNode(av + bv))
    invalid = invalid or not floatVerify(env, a) or not floatVerify(env, b) or not floatVerify(env, env.past[^1][^1])
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "+ error: " & $getCurrentException().name, env.current)
core["+"].variant.add(CoreObj(args: @["Float", "Float"], cmd: doAddF))
core["+"].variant.add(CoreObj(args: @["Int", "Float"], cmd: doAddF))
core["+"].variant.add(CoreObj(args: @["Float", "Int"], cmd: doAddF))

proc doAddS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: string
  var bv: string
  if a.nodeType == Char:
    av = $a.charVal
  else:
    av = a.stringVal
  if b.nodeType == Char:
    bv = $b.charVal
  else:
    bv = b.stringVal
  env.past[^1].addLast(newStringNode(av & bv))
  setInvalid(env, invalid)
core["+"].variant.add(CoreObj(args: @["String", "String"], cmd: doAddS))
core["+"].variant.add(CoreObj(args: @["String", "Char"], cmd: doAddS))
core["+"].variant.add(CoreObj(args: @["Char", "String"], cmd: doAddS))
core["+"].variant.add(CoreObj(args: @["Char", "Char"], cmd: doAddS))

proc doAddCI*(env: var Environment) =   # char + int = char (0-255)
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.charVal
  let bv = b.intVal
  var c = char(max(ord(av) + bv, 255))    # extended ASCII, has to fit in one byte
  env.past[^1].addLast(newCharNode(c))
  setInvalid(env, invalid)
core["+"].variant.add(CoreObj(args: @["Char", "Int"], cmd: doAddCI))

proc doAddIC*(env: var Environment) =   # int + char = int
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.charVal
  var c = (av + ord(bv))
  env.past[^1].addLast(newIntNode(c))
  setInvalid(env, invalid)
core["+"].variant.add(CoreObj(args: @["Int", "Char"], cmd: doAddIC))

proc doAddOther*(env: var Environment) =   
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "+ error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["+"].variant.add(CoreObj(args: @["Otherwise"], cmd: doAddOther))


core["-"] = CoreVars(count: 2)
proc doMinusI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.intVal
  try:
    env.past[^1].addLast(newIntNode(av - bv))
    setInvalid(env, invalid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "- error: " & $getCurrentException().name, env.current)
core["-"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doMinusI))

proc doMinusF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: float
  var bv: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  if b.nodeType == Int:
    bv = float(b.intVal)
  else:
    bv = b.floatVal
  try:
    env.past[^1].addLast(newFloatNode(av - bv))
    invalid = invalid or not floatVerify(env, a) or not floatVerify(env, b) or not floatVerify(env, env.past[^1][^1])
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "- error: " & $getCurrentException().name, env.current)
core["-"].variant.add(CoreObj(args: @["Float", "Float"], cmd: doMinusF))
core["-"].variant.add(CoreObj(args: @["Int", "Float"], cmd: doMinusF))
core["-"].variant.add(CoreObj(args: @["Float", "Int"], cmd: doMinusF))

proc doMinusCI*(env: var Environment) =   # char - int = char (0-255)
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av = a.charVal
  var bv = b.intVal
  if bv > ord(av):
    invalid = true
    handleError(env, "- error:  attempt to subtract " & $bv & "f from " & av, env.current)
    bv = ord(av)
  var c = char(ord(av) - bv)    # extended ASCII, has to fit in one unsigned byte
  env.past[^1].addLast(newCharNode(c))
  setInvalid(env, invalid)
core["-"].variant.add(CoreObj(args: @["Char", "Int"], cmd: doMinusCI))

proc doMinusIC*(env: var Environment) =   # int - char = int
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.charVal
  var c = (av - ord(bv))
  env.past[^1].addLast(newIntNode(c))
  setInvalid(env, invalid)
core["-"].variant.add(CoreObj(args: @["Int", "Char"], cmd: doMinusIC))

proc doMinusCC*(env: var Environment) =   # int - char = int
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.charVal
  let bv = b.charVal
  var c = (ord(av) - ord(bv))
  env.past[^1].addLast(newIntNode(c))
  setInvalid(env, invalid)
core["-"].variant.add(CoreObj(args: @["Char", "Char"], cmd: doMinusCC))

proc doMinusOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "- error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["-"].variant.add(CoreObj(args: @["Otherwise"], cmd: doMinusOther))


core["*"] = CoreVars(count: 2)
proc doTimesI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.intVal
  try:
    env.past[^1].addLast(newIntNode(av * bv))
    setInvalid(env, invalid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "* error: " & $getCurrentException().name, env.current)
core["*"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doTimesI))

proc doTimesF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: float
  var bv: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  if b.nodeType == Int:
    bv = float(b.intVal)
  else:
    bv = b.floatVal
  try:
    env.past[^1].addLast(newFloatNode(av * bv))
    invalid = invalid or not floatVerify(env, a) or not floatVerify(env, b) or not floatVerify(env, env.past[^1][^1])
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "* error: " & $getCurrentException().name, env.current)
core["*"].variant.add(CoreObj(args: @["Float", "Float"], cmd: doTimesF))
core["*"].variant.add(CoreObj(args: @["Int", "Float"], cmd: doTimesF))
core["*"].variant.add(CoreObj(args: @["Float", "Int"], cmd: doTimesF))

proc doTimesCI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.charVal
  let bv = b.intVal
  if bv > 0:
    var c: string = av.repeat(bv)
    env.past[^1].addLast(newStringNode(c))
    setInvalid(env, invalid)
  elif bv == 0:
    env.past[^1].addLast(newStringNode(""))
    setInvalid(env, invalid)
  else:
    env.past[^1].addLast(newStringNode(""))
    setInvalid(env, true)
    handleError(env, "* cannot create a string of `" & av & " with length " & $bv, env.current)
core["*"].variant.add(CoreObj(args: @["Char", "Int"], cmd: doTimesCI))

proc doTimesSI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.stringVal
  let bv = b.intVal
  if bv > 0:
    var c: string = av.repeat(bv)
    env.past[^1].addLast(newStringNode(c))
    setInvalid(env, invalid)
  elif bv == 0:
    env.past[^1].addLast(newStringNode(""))
    setInvalid(env, invalid)
  else:
    env.past[^1].addLast(newStringNode(""))
    setInvalid(env, true)
    handleError(env, "* cannot create a string of '" & av & "' with length " & $bv, env.current)
core["*"].variant.add(CoreObj(args: @["String", "Int"], cmd: doTimesSI))

proc doTimesOther*(env: var Environment) =   
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "* error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["*"].variant.add(CoreObj(args: @["Otherwise"], cmd: doTimesOther))


core["/"] = CoreVars(count: 2)
proc doDivide*(env: var Environment) =    # / always results in a float
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: float
  var bv: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  if b.nodeType == Int:
    bv = float(b.intVal)
  else:
    bv = b.floatVal
  try:
    if bv != 0:
      env.past[^1].addLast(newFloatNode(av / bv))  
      invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av) or not floatVerify(env, bv)
      setInvalid(env, invalid)
    else:
      env.past[^1].addLast(newNullNode(true))
      let errmsg = "/ by 0 error"
      handleError(env, errmsg, env.current)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "/ error: " & $getCurrentException().name, env.current)
core["/"].variant.add(CoreObj(args: @["Num", "Num"], cmd: doDivide))

proc doDivideOther*(env: var Environment) = 
  let a = env.past[^1].popLast().nodeType
  let b = env.past[^1].popLast().nodeType
  let errmsg = "/ error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["/"].variant.add(CoreObj(args: @["Otherwise"], cmd: doDivideOther))

core["//"] = CoreVars(count: 2)     # integer division
proc doDiv*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: int64
  var bv: int64
  if a.nodeType == Int:
    av = a.intVal
  else:
    av = int64(a.floatVal)
  if b.nodeType == Int:
    bv = b.intVal
  else:
    bv = int64(b.floatVal)
  try:
    if bv != 0:
      env.past[^1].addLast(newIntNode(av div bv))
      setInvalid(env, invalid)
    else:
      env.past[^1].addLast(newNullNode(true))
      let errmsg = "// by 0 error"
      handleError(env, errmsg, env.current)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "// error: " & $getCurrentException().name, env.current)
core["//"].variant.add(CoreObj(args: @["Num", "Num"], cmd: doDiv))

proc doDivOther*(env: var Environment) =   
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "// error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["//"].variant.add(CoreObj(args: @["Otherwise"], cmd: doDivOther))


core["%"] = CoreVars(count: 2)     # integer modulus
proc doMod*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: int64
  var bv: int64
  if a.nodeType == Int:
    av = a.intVal
  else:
    av = int64(a.floatVal)
  if b.nodeType == Int:
    bv = b.intVal
  else:
    bv = int64(b.floatVal)
  try:
    if bv != 0:
      env.past[^1].addLast(newIntNode(av mod bv))
      setInvalid(env, invalid)
    else:
      env.past[^1].addLast(newNullNode(true))
      let errmsg = "% by 0 error"
      handleError(env, errmsg, env.current)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "% error: " & $getCurrentException().name, env.current)
core["%"].variant.add(CoreObj(args: @["Num", "Num"], cmd: doMod))

proc doModOther*(env: var Environment) =   
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "% error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["%"].variant.add(CoreObj(args: @["Otherwise"], cmd: doModOther))


core["/%"] = CoreVars(count: 2)     # integer division & modulus
proc doDivMod*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: int64
  var bv: int64
  if a.nodeType == Int:
    av = a.intVal
  else:
    av = int64(a.floatVal)
  if b.nodeType == Int:
    bv = b.intVal
  else:
    bv = int64(b.floatVal)
  try:
    if bv != 0:
      env.past[^1].addLast(newIntNode(av div bv))
      setInvalid(env, invalid)
      env.past[^1].addLast(newIntNode(av mod bv))
      setInvalid(env, invalid)
    else:
      env.past[^1].addLast(newNullNode(true))
      let errmsg = "/% by 0 error"
      handleError(env, errmsg, env.current)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "/% error: " & $getCurrentException().name, env.current)
core["/%"].variant.add(CoreObj(args: @["Num", "Num"], cmd: doDivMod))

proc doDivModOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "/% error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["/%"].variant.add(CoreObj(args: @["Otherwise"], cmd: doDivModOther))


core["pow"] = CoreVars(count: 2)    # pow always returns a float
proc doPow*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: float
  var bv: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  if b.nodeType == Int:
    bv = float(b.intVal)
  else:
    bv = b.floatVal
  try:
    env.past[^1].addLast(newFloatNode(pow(av,  bv)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av) or not floatVerify(env, bv)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "pow error: " & $getCurrentException().name, env.current)
core["pow"].variant.add(CoreObj(args: @["Num", "Num"], cmd: doPow))

proc doPowOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "pow error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["pow"].variant.add(CoreObj(args: @["Otherwise"], cmd: doPowOther))


core["^"] = CoreVars(count: 2)    # ^ returns an int
proc doIntPowII*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: int64
  var bv: int64
  if a.nodeType == Int:
    av = a.intVal
  else:
    av = int64(a.floatVal)
  if b.nodeType == Int:
    bv = b.intVal
  else:
    bv = int64(b.floatVal)
  try:
    env.past[^1].addLast(newIntNode(av ^ bv))
    setInvalid(env, invalid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "^ error: " & $getCurrentException().name, env.current)
core["^"].variant.add(CoreObj(args: @["Num", "Num"], cmd: doIntPowII))

proc doIntPowOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "^ error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["^"].variant.add(CoreObj(args: @["Otherwise"], cmd: doIntPowOther))


core["root"] = CoreVars(count: 2)   # root always returns a float
proc doRoot*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: float
  var bv: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  if b.nodeType == Int:
    bv = float(b.intVal)
  else:
    bv = b.floatVal
  try:
    if bv == 0.0:
      env.past[^1].addLast(newNullNode(true))
      let errmsg = "Cannot take the 0th root of a number"
      handleError(env, errmsg, env.current)
    else:
      env.past[^1].addLast(newFloatNode(pow(av,  1.0/bv)))
      invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av) or not floatVerify(env, bv)
      setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "root error: " & $getCurrentException().name, env.current)
core["root"].variant.add(CoreObj(args: @["Num", "Num"], cmd: doRoot))

proc doRootOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "root error, illegal type combination: " & $a & ", " & $b
  handleError(env, errmsg, env.current)
core["root"].variant.add(CoreObj(args: @["Otherwise"], cmd: doRootOther))


core["log"] = CoreVars(count: 2)   # log a of base b
proc doLog*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  var av: float
  var bv: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  if b.nodeType == Int:
    bv = float(b.intVal)
  else:
    bv = b.floatVal
  try:
    env.past[^1].addLast(newFloatNode(log(av, bv)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av) or not floatVerify(env, bv)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "log error: " & $getCurrentException().name, env.current)
core["log"].variant.add(CoreObj(args: @["Num", "Num"], cmd: doLog))

proc doLogOther*(env: var Environment) =  
  let b = env.past[^1].popLast().nodeType
  let a = env.past[^1].popLast().nodeType
  let errmsg = "log error, illegal type combination: " & $a & $b
  handleError(env, errmsg, env.current)
core["log"].variant.add(CoreObj(args: @["Otherwise"], cmd: doLogOther))


proc doMathBinary*(env: var Environment) =
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  env.future.addFirst(env.current)
  env.future.growLeft(b)
  env.future.growLeft(a)
core["+"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["+"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["+"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["-"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["-"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["-"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["*"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["*"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["*"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["/"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["/"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["/"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["//"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["//"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["//"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["%"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["%"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["%"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["/%"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["/%"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["/%"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["^"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["^"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["^"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["pow"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["pow"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["pow"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["root"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["root"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["root"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))
core["log"].variant.add(CoreObj(args: @["Num", "Blocky"], cmd: doMathBinary))
core["log"].variant.add(CoreObj(args: @["Blocky", "Num"], cmd: doMathBinary))
core["log"].variant.add(CoreObj(args: @["Blocky", "Blocky"], cmd: doMathBinary))


core["abs"] = CoreVars(count: 1) 
proc doAbsI*(env: var Environment) =
  try:
    env.past[^1][^1].intVal = abs(env.past[^1][^1].intVal)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "abs error: " & $getCurrentException().name, env.current)
core["abs"].variant.add(CoreObj(args: @["Int"], cmd: doAbsI))

proc doAbsF*(env: var Environment) =
  try:
    env.past[^1][^1].floatVal = abs(env.past[^1][^1].floatVal)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "abs error: " & $getCurrentException().name, env.current)
core["abs"].variant.add(CoreObj(args: @["Float"], cmd: doAbsF))

proc doAbsOther*(env: var Environment) =   
  let a = env.past[^1].popLast().nodeType
  let errmsg = "abs error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["abs"].variant.add(CoreObj(args: @["Otherwise"], cmd: doAbsOther))


core["round"] = CoreVars(count: 1)  
proc doRoundF*(env: var Environment) =
  try:
    env.past[^1][^1].floatVal = round(env.past[^1][^1].floatVal)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "round error: " & $getCurrentException().name, env.current)
core["round"].variant.add(CoreObj(args: @["Float"], cmd: doRoundF))


proc doRoundOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "round error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["round"].variant.add(CoreObj(args: @["Otherwise"], cmd: doRoundOther))


core["ceiling"] = CoreVars(count: 1)  
proc doCeilingF*(env: var Environment) =
  try:
    env.past[^1][^1].floatVal = ceil(env.past[^1][^1].floatVal)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "ceiling error: " & $getCurrentException().name, env.current)
core["ceiling"].variant.add(CoreObj(args: @["Float"], cmd: doCeilingF))

proc doCeilingOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "ceiling error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["ceiling"].variant.add(CoreObj(args: @["Otherwise"], cmd: doCeilingOther))


core["floor"] = CoreVars(count: 1)  
proc doFloorF*(env: var Environment) =
  try:
    env.past[^1][^1].floatVal = floor(env.past[^1][^1].floatVal)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "floor error: " & $getCurrentException().name, env.current)
core["floor"].variant.add(CoreObj(args: @["Float"], cmd: doFloorF))

proc doFloorOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "floor error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["floor"].variant.add(CoreObj(args: @["Otherwise"], cmd: doFloorOther))


core["trunc"] = CoreVars(count: 1)  
proc doTruncF*(env: var Environment) =
  try:
    env.past[^1][^1].floatVal = trunc(env.past[^1][^1].floatVal)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "trunc error: " & $getCurrentException().name, env.current)
core["trunc"].variant.add(CoreObj(args: @["Float"], cmd: doTruncF))

proc doTruncOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "trunc error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["trunc"].variant.add(CoreObj(args: @["Otherwise"], cmd: doTruncOther))


core[">int"] = CoreVars(count: 1)  
proc doToInt*(env: var Environment) =
  var valid = checkInvalid(env, 1)
  try:
    env.past[^1].addLast(newIntNode(int(env.past[^1].popLast().floatVal)))
    setInvalid(env, valid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">int error: " & $getCurrentException().name, env.current)
core[">int"].variant.add(CoreObj(args: @["Float"], cmd: doToInt))

proc doToIntOther*(env: var Environment) =   
  let a = env.past[^1].popLast().nodeType
  let errmsg = ">int error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core[">int"].variant.add(CoreObj(args: @["Otherwise"], cmd: doToIntOther))


core[">float"] = CoreVars(count: 1)  
proc doToFloat*(env: var Environment) =
  var valid = checkInvalid(env, 1)
  try:
    env.past[^1].addLast(newFloatNode(float(env.past[^1].popLast().intVal)))
    setInvalid(env, valid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">float error: " & $getCurrentException().name, env.current)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">float error: " & $getCurrentException().name, env.current)
core[">float"].variant.add(CoreObj(args: @["Int"], cmd: doToFloat))

proc doToFloatOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = ">float error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core[">float"].variant.add(CoreObj(args: @["Otherwise"], cmd: doToFloatOther))


core[">round"] = CoreVars(count: 1)  
proc doToRoundI*(env: var Environment) =
  var valid = checkInvalid(env, 1)
  try:
    env.past[^1].addLast(newIntNode(int(round(env.past[^1].popLast().floatVal))))
    setInvalid(env, valid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">round error: " & $getCurrentException().name, env.current)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">round error: " & $getCurrentException().name, env.current)
core[">round"].variant.add(CoreObj(args: @["Float"], cmd: doToRoundI))

proc doToRoundOther*(env: var Environment) = 
  let a = env.past[^1].popLast().nodeType
  let errmsg = ">round error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core[">round"].variant.add(CoreObj(args: @["Otherwise"], cmd: doToRoundOther))


core[">ceiling"] = CoreVars(count: 1)  
proc doToCeilingI*(env: var Environment) =
  var valid = checkInvalid(env, 1)
  try:
    env.past[^1].addLast(newIntNode(int(ceil(env.past[^1].popLast().floatVal))))
    setInvalid(env, valid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">ceiling error: " & $getCurrentException().name, env.current)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">ceiling error: " & $getCurrentException().name, env.current)
core[">ceiling"].variant.add(CoreObj(args: @["Float"], cmd: doToCeilingI))

proc doToCeilingOther*(env: var Environment) =   
  let a = env.past[^1].popLast().nodeType
  let errmsg = ">ceiling error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core[">ceiling"].variant.add(CoreObj(args: @["Otherwise"], cmd: doToCeilingOther))


core[">floor"] = CoreVars(count: 1)  
proc doToFloorI*(env: var Environment) =
  var valid = checkInvalid(env, 1)
  try:
    env.past[^1].addLast(newIntNode(int(floor(env.past[^1].popLast().floatVal))))
    setInvalid(env, valid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">floor error: " & $getCurrentException().name, env.current)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">floor error: " & $getCurrentException().name, env.current)
core[">floor"].variant.add(CoreObj(args: @["Float"], cmd: doToFloorI))

proc doToFloorOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = ">floor error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core[">floor"].variant.add(CoreObj(args: @["Otherwise"], cmd: doToFloorOther))


core[">trunc"] = CoreVars(count: 1)  
proc doToTruncI*(env: var Environment) =
  var valid = checkInvalid(env, 1)
  try:
    env.past[^1].addLast(newIntNode(int(trunc(env.past[^1].popLast().floatVal))))
    setInvalid(env, valid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">trunc error: " & $getCurrentException().name, env.current)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">trunc error: " & $getCurrentException().name, env.current)
core[">trunc"].variant.add(CoreObj(args: @["Float"], cmd: doToTruncI))

proc doToTruncOther*(env: var Environment) = 
  let a = env.past[^1].popLast().nodeType
  let errmsg = ">trunc error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core[">trunc"].variant.add(CoreObj(args: @["Otherwise"], cmd: doToTruncOther))


proc doSingleIntOnly*(env: var Environment) = 
  discard
core["round"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core["ceiling"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core["floor"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core["trunc"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core[">round"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core[">ceiling"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core[">floor"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core[">trunc"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core[">int"].variant.add(CoreObj(args: @["Int"], cmd: doSingleIntOnly))
core[">float"].variant.add(CoreObj(args: @["Float"], cmd: doSingleIntOnly))

core["negate"] = CoreVars(count: 1)   # convert radians to degrees
proc doNegateI*(env: var Environment) =
  try:
    env.past[^1][^1].intVal = -env.past[^1][^1].intVal
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "negate error: " & $getCurrentException().name, env.current)
core["negate"].variant.add(CoreObj(args: @["Int"], cmd: doNegateI))

proc doNegateF*(env: var Environment) =
  try:
    env.past[^1][^1].floatVal = -env.past[^1][^1].floatVal
  except CatchableError:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "negate error: " & $getCurrentException().name, env.current)
core["negate"].variant.add(CoreObj(args: @["Float"], cmd: doNegateF))

proc doNegateOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "negate error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["negate"].variant.add(CoreObj(args: @["Otherwise"], cmd: doNegateOther))


core["sqrt"] = CoreVars(count: 1)   # square root of a
proc doSquareRoot*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(sqrt(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "sqrt error: " & $getCurrentException().name, env.current)
core["sqrt"].variant.add(CoreObj(args: @["Num"], cmd: doSquareRoot))

proc doSquareRootOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "sqrt error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["sqrt"].variant.add(CoreObj(args: @["Otherwise"], cmd: doSquareRootOther))


core["sqr"] = CoreVars(count: 1)   # square of a
proc doSquareI*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av = a.intVal
  try:
    env.past[^1].addLast(newIntNode(av * av))
    setInvalid(env, invalid)
  except ArithmeticDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "sqr error: " & $getCurrentException().name, env.current)
core["sqr"].variant.add(CoreObj(args: @["Int"], cmd: doSquareI))

proc doSquareF*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(av * av))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "sqr error: " & $getCurrentException().name, env.current)
core["sqr"].variant.add(CoreObj(args: @["Float"], cmd: doSquareF))

proc doSquareOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "sqr error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["sqr"].variant.add(CoreObj(args: @["Otherwise"], cmd: doSquareRootOther))


core["cbrt"] = CoreVars(count: 1)   # cube root of a
proc doCubeRoot*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(cbrt(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "cbrt error: " & $getCurrentException().name, env.current)
core["cbrt"].variant.add(CoreObj(args: @["Num"], cmd: doCubeRoot))

proc doCubeRootOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "cbrt error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["cbrt"].variant.add(CoreObj(args: @["Otherwise"], cmd: doCubeRootOther))


core["ln"] = CoreVars(count: 1)   # natural log of a
proc doLn*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(ln(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "ln error: " & $getCurrentException().name, env.current)
core["ln"].variant.add(CoreObj(args: @["Num"], cmd: doLn))

proc doLnOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "ln error, illegal type: " & $a 
  handleError(env, errmsg, env.current)
core["ln"].variant.add(CoreObj(args: @["Otherwise"], cmd: doLnOther))


core["exp"] = CoreVars(count: 1)   # e to power of a, opposite of ln a
proc doExp*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(exp(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "exp error: " & $getCurrentException().name, env.current)
core["exp"].variant.add(CoreObj(args: @["Num"], cmd: doExp))

proc doExpOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "exp error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["exp"].variant.add(CoreObj(args: @["Otherwise"], cmd: doExpOther))


core["sin"] = CoreVars(count: 1)   
proc doSin*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(sin(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "sin error: " & $getCurrentException().name, env.current)
core["sin"].variant.add(CoreObj(args: @["Num"], cmd: doSin))

proc doSinOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "sin error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["sin"].variant.add(CoreObj(args: @["Otherwise"], cmd: doSinOther))


core["cos"] = CoreVars(count: 1)   
proc doCos*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(cos(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "cos error: " & $getCurrentException().name, env.current)
core["cos"].variant.add(CoreObj(args: @["Num"], cmd: doCos))

proc doCosOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "cos error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["cos"].variant.add(CoreObj(args: @["Otherwise"], cmd: doCosOther))


core["tan"] = CoreVars(count: 1)   
proc doTan*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(tan(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "tan error: " & $getCurrentException().name, env.current)
core["tan"].variant.add(CoreObj(args: @["Num"], cmd: doTan))

proc doTanOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "tan error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["tan"].variant.add(CoreObj(args: @["Otherwise"], cmd: doTanOther))


core["sec"] = CoreVars(count: 1)    # secant
proc doSec*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(sec(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "sec error: " & $getCurrentException().name, env.current)
core["sec"].variant.add(CoreObj(args: @["Num"], cmd: doSec))

proc doSecOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "sec error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["sec"].variant.add(CoreObj(args: @["Otherwise"], cmd: doSecOther))


core["csc"] = CoreVars(count: 1)   # cosecant
proc doCSC*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(csc(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "csc error: " & $getCurrentException().name, env.current)
core["csc"].variant.add(CoreObj(args: @["Num"], cmd: doCSC))

proc doCSCOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "csc error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["csc"].variant.add(CoreObj(args: @["Otherwise"], cmd: doCSCOther))


core["asin"] = CoreVars(count: 1)   
proc doASin*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arcsin(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "asin error: " & $getCurrentException().name, env.current)
core["asin"].variant.add(CoreObj(args: @["Num"], cmd: doASin))

proc doASinOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "asin error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["asin"].variant.add(CoreObj(args: @["Otherwise"], cmd: doASinOther))


core["acos"] = CoreVars(count: 1)   
proc doACos*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arccos(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "acos error: " & $getCurrentException().name, env.current)
core["acos"].variant.add(CoreObj(args: @["Num"], cmd: doACos))

proc doACosOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "acos error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["acos"].variant.add(CoreObj(args: @["Otherwise"], cmd: doACosOther))


core["atan"] = CoreVars(count: 1)   
proc doATan*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arctan(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "atan error: " & $getCurrentException().name, env.current)
core["atan"].variant.add(CoreObj(args: @["Num"], cmd: doATan))

proc doATanOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "atan error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["atan"].variant.add(CoreObj(args: @["Otherwise"], cmd: doATanOther))


core["asec"] = CoreVars(count: 1)    # arcsecant
proc doASec*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arcsec(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "asec error: " & $getCurrentException().name, env.current)
core["asec"].variant.add(CoreObj(args: @["Num"], cmd: doASec))

proc doASecOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "asec error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["asec"].variant.add(CoreObj(args: @["Otherwise"], cmd: doASecOther))


core["acsc"] = CoreVars(count: 1)   # arccosecant
proc doACSC*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arccsc(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "acsc error: " & $getCurrentException().name, env.current)
core["acsc"].variant.add(CoreObj(args: @["Num"], cmd: doACSC))

proc doACSCOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "acsc error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["acsc"].variant.add(CoreObj(args: @["Otherwise"], cmd: doCSCOther))


core[">deg"] = CoreVars(count: 1)   # convert radians to degrees
proc doToDegrees*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(radToDeg(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">deg error: " & $getCurrentException().name, env.current)
core[">deg"].variant.add(CoreObj(args: @["Num"], cmd: doToDegrees))

proc doToDegreesOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = ">deg error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core[">deg"].variant.add(CoreObj(args: @["Otherwise"], cmd: doToDegreesOther))


core[">rad"] = CoreVars(count: 1)   # convert radians to degrees
proc doToRadians*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(degToRad(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, ">rad error: " & $getCurrentException().name, env.current)
core[">rad"].variant.add(CoreObj(args: @["Num"], cmd: doToRadians))

proc doToRadiansOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = ">rad error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core[">rad"].variant.add(CoreObj(args: @["Otherwise"], cmd: doToRadiansOther))

core["Euler"] = CoreVars(count: 0) 
core["euler"] = CoreVars(count: 0)   
proc doEuler*(env: var Environment) =
  env.past[^1].addLast(newFloatNode(E))
core["euler"].variant.add(CoreObj(args: @[], cmd: doEuler))
core["Euler"].variant.add(CoreObj(args: @[], cmd: doEuler))

core["pi"] = CoreVars(count: 0)   
proc doPi*(env: var Environment) =
  env.past[^1].addLast(newFloatNode(Pi))
core["pi"].variant.add(CoreObj(args: @[], cmd: doPi))

core["half_pi"] = CoreVars(count: 0)   
proc doHalfPi*(env: var Environment) =
  env.past[^1].addLast(newFloatNode(Pi/2.0))
core["half_pi"].variant.add(CoreObj(args: @[], cmd: doHalfPi))

core["tau"] = CoreVars(count: 0)   # twice pi
proc doTau*(env: var Environment) =
  env.past[^1].addLast(newFloatNode(Tau))
core["tau"].variant.add(CoreObj(args: @[], cmd: doTau))

core["phi"] = CoreVars(count: 0)   # golden ratio
proc doPhi*(env: var Environment) =
  env.past[^1].addLast(newFloatNode(1.6180339887498948482))
core["phi"].variant.add(CoreObj(args: @[], cmd: doPhi))

core["sqrt2"] = CoreVars(count: 0) 
proc doSqrtTwo*(env: var Environment) =
  env.past[^1].addLast(newFloatNode(sqrt(2.0)))
core["sqrt2"].variant.add(CoreObj(args: @[], cmd: doSqrtTwo))

core["half_sqrt2"] = CoreVars(count: 0) 
proc doHalfSqrtTwo*(env: var Environment) =
  env.past[^1].addLast(newFloatNode(sqrt(2.0)/2.0))
core["half_sqrt2"].variant.add(CoreObj(args: @[], cmd: doHalfSqrtTwo))

core["sinh"] = CoreVars(count: 1)   
proc doSinh*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(sinh(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "sinh error: " & $getCurrentException().name, env.current)
core["sinh"].variant.add(CoreObj(args: @["Num"], cmd: doSinh))

proc doSinhOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "sinh error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["sinh"].variant.add(CoreObj(args: @["Otherwise"], cmd: doSinhOther))


core["cosh"] = CoreVars(count: 1)   
proc doCosh*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(cosh(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "cosh error: " & $getCurrentException().name, env.current)
core["cosh"].variant.add(CoreObj(args: @["Num"], cmd: doCosh))

proc doCoshOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "cosh error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["cosh"].variant.add(CoreObj(args: @["Otherwise"], cmd: doCoshOther))


core["tanh"] = CoreVars(count: 1)   
proc doTanh*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(tanh(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "tanh error: " & $getCurrentException().name, env.current)
core["tanh"].variant.add(CoreObj(args: @["Num"], cmd: doTanh))

proc doTanhOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "tanh error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["tanh"].variant.add(CoreObj(args: @["Otherwise"], cmd: doTanhOther))


core["sech"] = CoreVars(count: 1)    # secant
proc doSech*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(sech(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "sech error: " & $getCurrentException().name, env.current)
core["sech"].variant.add(CoreObj(args: @["Num"], cmd: doSech))

proc doSechOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "sech error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["sech"].variant.add(CoreObj(args: @["Otherwise"], cmd: doSechOther))


core["csch"] = CoreVars(count: 1)   # cosecant
proc doCSCh*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(csch(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "csch error: " & $getCurrentException().name, env.current)
core["csch"].variant.add(CoreObj(args: @["Num"], cmd: doCSCh))

proc doCSChOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "csch error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["csch"].variant.add(CoreObj(args: @["Otherwise"], cmd: doCSChOther))


core["asinh"] = CoreVars(count: 1)   
proc doASinh*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arcsinh(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "asinh error: " & $getCurrentException().name, env.current)
core["asinh"].variant.add(CoreObj(args: @["Num"], cmd: doASinh))

proc doASinhOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "asinh error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["asinh"].variant.add(CoreObj(args: @["Otherwise"], cmd: doASinhOther))


core["acosh"] = CoreVars(count: 1)   
proc doACosh*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arccosh(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "acosh error: " & $getCurrentException().name, env.current)
core["acosh"].variant.add(CoreObj(args: @["Num"], cmd: doACosh))

proc doACoshOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "acosh error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["acosh"].variant.add(CoreObj(args: @["Otherwise"], cmd: doACoshOther))


core["atanh"] = CoreVars(count: 1)   
proc doATanh*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arctanh(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "atanh error: " & $getCurrentException().name, env.current)
core["atanh"].variant.add(CoreObj(args: @["Num"], cmd: doATanh))

proc doATanhOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "atanh error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["atanh"].variant.add(CoreObj(args: @["Otherwise"], cmd: doATanhOther))


core["asech"] = CoreVars(count: 1)    # arcsecant
proc doASech*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arcsech(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "asech error: " & $getCurrentException().name, env.current)
core["asech"].variant.add(CoreObj(args: @["Num"], cmd: doASech))

proc doASechOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "asech error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["asech"].variant.add(CoreObj(args: @["Otherwise"], cmd: doASechOther))


core["acsch"] = CoreVars(count: 1)   # arccosecant
proc doACSCh*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  let a = env.past[^1].popLast()
  var av: float
  if a.nodeType == Int:
    av = float(a.intVal)
  else:
    av = a.floatVal
  try:
    env.past[^1].addLast(newFloatNode(arccsch(av)))
    invalid = invalid or not floatVerify(env, env.past[^1][^1]) or not floatVerify(env, av)
    setInvalid(env, invalid)
  except FloatingPointDefect:
    env.past[^1].addLast(newNullNode(true))
    handleError(env, "acsch error: " & $getCurrentException().name, env.current)
core["acsch"].variant.add(CoreObj(args: @["Num"], cmd: doACSCh))

proc doACSChOther*(env: var Environment) =  
  let a = env.past[^1].popLast().nodeType
  let errmsg = "acsch error, illegal type: " & $a
  handleError(env, errmsg, env.current)
core["acsch"].variant.add(CoreObj(args: @["Otherwise"], cmd: doCSChOther))


proc doMathSingle*(env: var Environment) =
  let a = env.past[^1].popLast()
  env.future.addFirst(env.current)
  env.future.growLeft(a)
core["abs"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["round"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["ceiling"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["floor"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["trunc"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core[">int"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core[">float"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core[">round"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core[">ceiling"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core[">floor"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core[">trunc"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["negate"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["sqrt"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["sqr"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["cbrt"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["ln"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["exp"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core[">deg"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core[">rad"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["sin"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["cos"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["tan"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["sec"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["csc"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["asin"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["acos"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["atan"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["asec"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["acsc"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["sinh"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["cosh"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["tanh"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["sech"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["csch"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["asinh"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["acosh"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["atanh"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["asech"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))
core["acsch"].variant.add(CoreObj(args: @["Blocky"], cmd: doMathSingle))







