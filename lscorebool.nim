## lscoreio
## Listack 0.4.0

import std/deques, std/tables, std/math
import lstypes, lstypehelpers, lsconfig
# import os, std/strutils, std/sequtils, std/terminal
# import lsparser, lstypeprint

when isMainModule:
  var env = initEnvironment()

core["="] = CoreVars(count: 2)    # approximate equality
proc doEq*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let at = a.nodeType
  let bt = b.nodeType
  var truthy: bool
  if at == Int and bt == Float:
    env.past[^1].addLast(newBoolNode(almostEqual(float(a.intVal), b.floatVal)))
  elif at == Float and bt == Int:
    env.past[^1].addLast(newBoolNode(almostEqual(a.floatVal, float(b.intVal))))
  elif at == String and bt == Char and len(a.stringVal) == 1:
    env.past[^1].addLast(newBoolNode(a.stringVal[0] == b.charVal))
  elif bt == String and at == Char and len(b.stringVal) == 1:
    env.past[^1].addLast(newBoolNode(b.stringVal[0] == a.charVal))
  elif at == String and bt == Word:
    env.past[^1].addLast(newBoolNode(a.stringVal == b.wordVal))
  elif bt == String and at == Word:
    env.past[^1].addLast(newBoolNode(b.stringVal == a.wordVal))
  elif at == bt:
    case at:
    of Int: env.past[^1].addLast(newBoolNode(a.intVal == b.intVal))
    of Float: env.past[^1].addLast(newBoolNode(a.floatVal == b.floatVal))
    of Bool: env.past[^1].addLast(newBoolNode(a.boolVal == b.boolVal))
    of Char: env.past[^1].addLast(newBoolNode(a.charVal == b.charVal))
    of String: env.past[^1].addLast(newBoolNode(a.stringVal == b.stringVal))
    of Word: env.past[^1].addLast(newBoolNode(a.wordVal == b.wordVal))
    of Block, List, Seq: 
      truthy = len(a.seqVal) == len(b.seqVal)
      if truthy and len(a.seqVal) > 0:
        for count in 0..<len(a.seqVal):
          env.past[^1].addLast(a.seqVal[count])
          env.past[^1].addLast(b.seqVal[count])
          doEq(env)
          truthy = env.past[^1].popLast().boolVal and truthy
      env.past[^1].addLast(newBoolNode(truthy))
    of Object: 
      var truthy = a.objectType == b.objectType
      if truthy:
        env.past[^1].addLast(newListNode(a.objectArgs))
        env.past[^1].addLast(newListNode(b.objectArgs))
        doEq(env)
        truthy = env.past[^1].popLast().boolVal and truthy
        if truthy:
          env.past[^1].addLast(a.objectVal)
          env.past[^1].addLast(b.objectVal)
          doEq(env)
          truthy = env.past[^1].popLast().boolVal and truthy
      env.past[^1].addLast(newBoolNode(truthy))
    of Null: env.past[^1].addLast(newBoolNode(true))
  else:
    env.past[^1].addLast(newBoolNode(false))
  setInvalid(env, invalid)
core["="].variant.add(CoreObj(args: @["Any", "Any"], cmd: doEq))

core["=="] = CoreVars(count: 2)  # strict equality
proc doEqEq*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let at = a.nodeType
  let bt = b.nodeType
  var truthy: bool
  if at == bt:
    case at:
    of Int: env.past[^1].addLast(newBoolNode(a.intVal == b.intVal))
    of Float: env.past[^1].addLast(newBoolNode(a.floatVal == b.floatVal))
    of Bool: env.past[^1].addLast(newBoolNode(a.boolVal == b.boolVal))
    of Char: env.past[^1].addLast(newBoolNode(a.charVal == b.charVal))
    of String: env.past[^1].addLast(newBoolNode(a.stringVal == b.stringVal))
    of Word: env.past[^1].addLast(newBoolNode(a.wordVal == b.wordVal))
    of Block, List, Seq: 
      truthy = len(a.seqVal) == len(b.seqVal)
      if truthy and len(a.seqVal) > 0:
        for count in 0..<len(a.seqVal):
          env.past[^1].addLast(a.seqVal[count])
          env.past[^1].addLast(b.seqVal[count])
          doEqEq(env)
          truthy = env.past[^1].popLast().boolVal and truthy
      env.past[^1].addLast(newBoolNode(truthy))
    of Object: 
      var truthy = a.objectType == b.objectType
      if truthy:
        env.past[^1].addLast(newListNode(a.objectArgs))
        env.past[^1].addLast(newListNode(b.objectArgs))
        doEqEq(env)
        truthy = env.past[^1].popLast().boolVal and truthy
        if truthy:
          env.past[^1].addLast(a.objectVal)
          env.past[^1].addLast(b.objectVal)
          doEqEq(env)
          truthy = env.past[^1].popLast().boolVal and truthy
      env.past[^1].addLast(newBoolNode(truthy))
    of Null: env.past[^1].addLast(newBoolNode(true))
  else:
    env.past[^1].addLast(newBoolNode(false))
  setInvalid(env, invalid)
core["=="].variant.add(CoreObj(args: @["Any", "Any"], cmd: doEqEq))

core["!="] = CoreVars(count: 2)   # approximate inequality
proc doNotEq*(env: var Environment) =
  doEq(env)
  env.past[^1][^1].boolVal = not env.past[^1][^1].boolVal
core["!="].variant.add(CoreObj(args: @["Any", "Any"], cmd: doNotEq))

core["!=="] = CoreVars(count: 2)  # strict inequality
proc doNotEqEq*(env: var Environment) =
  doEqEq(env)
  env.past[^1][^1].boolVal = not env.past[^1][^1].boolVal
core["!=="].variant.add(CoreObj(args: @["Any", "Any"], cmd: doNotEqEq))


core["~="] = CoreVars(count: 2)
proc doAboutEqFF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.floatVal
  var about = abs(av - bv) < 1e-12
  env.past[^1].addLast(newBoolNode(about))
  inValid = invalid or not floatVerify(env, av) or not floatVerify(env, bv)
  setInvalid(env, invalid)
core["~="].variant.add(CoreObj(args: @["Float", "Float"], cmd: doAboutEqFF))

proc doAboutEqIF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = float(a.intVal)
  let bv = b.floatVal
  var about = abs(av - bv) < 1e-6
  env.past[^1].addLast(newBoolNode(about))
  setInvalid(env, invalid)
core["~="].variant.add(CoreObj(args: @["Int", "Float"], cmd: doAboutEqIF))

proc doAboutEqFI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = float(b.intVal)
  var about = abs(av - bv) < 1e-6
  env.past[^1].addLast(newBoolNode(about))
  setInvalid(env, invalid)
core["~="].variant.add(CoreObj(args: @["Float", "Int"], cmd: doAboutEqFI))

proc doAboutEqOther*(env: var Environment) =
  env.current.wordVal = "="
  env.future.addFirst(env.current)
core["~="].variant.add(CoreObj(args: @["Otherwise"], cmd: doAboutEqOther))


core["<"] = CoreVars(count: 2)
proc doLTII*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.intVal
  env.past[^1].addLast(newBoolNode(av < bv))
  setInvalid(env, invalid)
core["<"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doLTII))

proc doLTFF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.floatVal
  env.past[^1].addLast(newBoolNode(av < bv))
  invalid = invalid or not floatVerify(env, av) or not floatVerify(env, bv)
  setInvalid(env, invalid)
core["<"].variant.add(CoreObj(args: @["Float", "Float"], cmd: doLTFF))

proc doLTIF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.floatVal
  env.past[^1].addLast(newBoolNode(float(av) < bv))
  invalid = invalid or not floatVerify(env, bv)
  setInvalid(env, invalid)
core["<"].variant.add(CoreObj(args: @["Int", "Float"], cmd: doLTIF))

proc doLTFI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.intVal
  env.past[^1].addLast(newBoolNode(av < float(bv)))
  invalid = invalid or not floatVerify(env, av)
  setInvalid(env, invalid)
core["<"].variant.add(CoreObj(args: @["Float", "Int"], cmd: doLTFI))

proc doLTSS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.stringVal
  let bv = b.stringVal
  env.past[^1].addLast(newBoolNode(av < bv))
  setInvalid(env, invalid)
core["<"].variant.add(CoreObj(args: @["String", "String"], cmd: doLTSS))

proc doLTCC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.charVal
  let bv = b.charVal
  env.past[^1].addLast(newBoolNode(av < bv))
  setInvalid(env, invalid)
core["<"].variant.add(CoreObj(args: @["Char", "Char"], cmd: doLTCC))


core[">"] = CoreVars(count: 2) 
proc doGTII*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.intVal
  env.past[^1].addLast(newBoolNode(av > bv))
  setInvalid(env, invalid)
core[">"].variant.add(CoreObj(args: @["Int", "Int"], cmd: doGTII))

proc doGTFF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.floatVal
  env.past[^1].addLast(newBoolNode(av > bv))
  invalid = invalid or not floatVerify(env, av) or not floatVerify(env, bv)
  setInvalid(env, invalid)
core[">"].variant.add(CoreObj(args: @["Float", "Float"], cmd: doGTFF))

proc doGTIF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.floatVal
  env.past[^1].addLast(newBoolNode(float(av) > bv))
  invalid = invalid or not floatVerify(env, bv)
  setInvalid(env, invalid)
core[">"].variant.add(CoreObj(args: @["Int", "Float"], cmd: doGTIF))

proc doGTFI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.intVal
  env.past[^1].addLast(newBoolNode(av > float(bv)))
  invalid = invalid or not floatVerify(env, av)
  setInvalid(env, invalid)
core[">"].variant.add(CoreObj(args: @["Float", "Int"], cmd: doGTFI))

proc doGTSS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.stringVal
  let bv = b.stringVal
  env.past[^1].addLast(newBoolNode(av > bv))
  setInvalid(env, invalid)
core[">"].variant.add(CoreObj(args: @["String", "String"], cmd: doGTSS))

proc doGTCC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.charVal
  let bv = b.charVal
  env.past[^1].addLast(newBoolNode(av > bv))
  setInvalid(env, invalid)
core[">"].variant.add(CoreObj(args: @["Char", "Char"], cmd: doGTCC))


core["<="] = CoreVars(count: 2) 
proc doLEII*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.intVal
  env.past[^1].addLast(newBoolNode(av <= bv))
  setInvalid(env, invalid)
core["<="].variant.add(CoreObj(args: @["Int", "Int"], cmd: doLEII))

proc doLEFF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.floatVal
  env.past[^1].addLast(newBoolNode(av <= bv))
  invalid = invalid or not floatVerify(env, av) or not floatVerify(env, bv)
  setInvalid(env, invalid)
core["<="].variant.add(CoreObj(args: @["Float", "Float"], cmd: doLEFF))

proc doLEIF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.floatVal
  env.past[^1].addLast(newBoolNode(float(av) <= bv))
  invalid = invalid or not floatVerify(env, bv)
  setInvalid(env, invalid)
core["<="].variant.add(CoreObj(args: @["Int", "Float"], cmd: doLEIF))

proc doLEFI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.intVal
  env.past[^1].addLast(newBoolNode(av <= float(bv)))
  invalid = invalid or not floatVerify(env, av)
  setInvalid(env, invalid)
core["<="].variant.add(CoreObj(args: @["Float", "Int"], cmd: doLEFI))

proc doLESS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.stringVal
  let bv = b.stringVal
  env.past[^1].addLast(newBoolNode(av <= bv))
  setInvalid(env, invalid)
core["<="].variant.add(CoreObj(args: @["String", "String"], cmd: doLESS))

proc doLECC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.charVal
  let bv = b.charVal
  env.past[^1].addLast(newBoolNode(av <= bv))
  setInvalid(env, invalid)
core["<="].variant.add(CoreObj(args: @["Char", "Char"], cmd: doLECC))


core[">="] = CoreVars(count: 2)
proc doGEII*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.intVal
  env.past[^1].addLast(newBoolNode(av >= bv))
  setInvalid(env, invalid)
core[">="].variant.add(CoreObj(args: @["Int", "Int"], cmd: doGEII))

proc doGEFF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.floatVal
  env.past[^1].addLast(newBoolNode(av >= bv))
  invalid = invalid or not floatVerify(env, av) or not floatVerify(env, bv)
  setInvalid(env, invalid)
core[">="].variant.add(CoreObj(args: @["Float", "Float"], cmd: doGEFF))

proc doGEIF*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.intVal
  let bv = b.floatVal
  env.past[^1].addLast(newBoolNode(float(av) >= bv))
  invalid = invalid or not floatVerify(env, bv)
  setInvalid(env, invalid)
core[">="].variant.add(CoreObj(args: @["Int", "Float"], cmd: doGEIF))

proc doGEFI*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.floatVal
  let bv = b.intVal
  env.past[^1].addLast(newBoolNode(av >= float(bv)))
  invalid = invalid or not floatVerify(env, av)
  setInvalid(env, invalid)
core[">="].variant.add(CoreObj(args: @["Float", "Int"], cmd: doGEFI))

proc doGESS*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.stringVal
  let bv = b.stringVal
  env.past[^1].addLast(newBoolNode(av >= bv))
  setInvalid(env, invalid)
core[">="].variant.add(CoreObj(args: @["String", "String"], cmd: doGESS))

proc doGECC*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let b = env.past[^1].popLast()
  let a = env.past[^1].popLast()
  let av = a.charVal
  let bv = b.charVal
  env.past[^1].addLast(newBoolNode(av >= bv))
  setInvalid(env, invalid)
core[">="].variant.add(CoreObj(args: @["Char", "Char"], cmd: doGECC))


core["not"] = CoreVars(count: 1)
proc doNot*(env: var Environment) =
  env.past[^1][^1].boolVal = not env.past[^1][^1].boolVal
core["not"].variant.add(CoreObj(args: @["Bool"], cmd: doNot))

core["and"] = CoreVars(count: 2)
proc doAnd*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let a = env.past[^1].popLast()
  let av = a.boolVal
  env.past[^1][^1].boolVal = env.past[^1][^1].boolVal and av
  setInvalid(env, invalid)
core["and"].variant.add(CoreObj(args: @["Bool", "Bool"], cmd: doAnd))

core["or"] = CoreVars(count: 2)
proc doOr*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let a = env.past[^1].popLast()
  let av = a.boolVal
  env.past[^1][^1].boolVal = env.past[^1][^1].boolVal or av
  setInvalid(env, invalid)
core["or"].variant.add(CoreObj(args: @["Bool", "Bool"], cmd: doOr))

core["xor"] = CoreVars(count: 2)
proc doXor*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let a = env.past[^1].popLast()
  let av = a.boolVal
  env.past[^1][^1].boolVal = env.past[^1][^1].boolVal xor av
  setInvalid(env, invalid)
core["xor"].variant.add(CoreObj(args: @["Bool", "Bool"], cmd: doXor))

core["nand"] = CoreVars(count: 2)
proc doNand*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let a = env.past[^1].popLast()
  let av = a.boolVal
  env.past[^1][^1].boolVal = not(env.past[^1][^1].boolVal and av)
  setInvalid(env, invalid)
core["nand"].variant.add(CoreObj(args: @["Bool", "Bool"], cmd: doNand))

core["nor"] = CoreVars(count: 2)
proc doNor*(env: var Environment) =
  var invalid = checkInvalid(env, 2)
  let a = env.past[^1].popLast()
  let av = a.boolVal
  env.past[^1][^1].boolVal = not(env.past[^1][^1].boolVal or av)
  setInvalid(env, invalid)
core["nor"].variant.add(CoreObj(args: @["Bool", "Bool"], cmd: doNor))

core[">bool"] = CoreVars(count: 1)
proc doMakeBool*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  proc checkTruth(env: var Environment, a: LsNode): bool =    # can use this recursively
    let at = a.nodeType
    var truthy: bool
    case at
    of Null:
      truthy = false
    of Bool:
      truthy = a.boolVal
    of Int:
      truthy = a.intVal != 0
    of Float:
      truthy = a.floatVal != 0.0 and floatVerify(env, a)
    of String:
      truthy = a.stringVal != ""
    of Char:
      truthy = a.charVal != '\0'
    of Block, List, Seq:
      truthy = len(a.seqVal) != 0
    of Object:
      truthy = checkTruth(env, a.objectVal)
    else:
      truthy = false   # how did you get here?
    truthy = truthy and not a.invalid
    return truthy
  let b = env.past[^1].popLast()
  env.past[^1].addLast(newBoolNode(checkTruth(env, b)))
  setInvalid(env, invalid)
core[">bool"].variant.add(CoreObj(args: @["Any"], cmd: doMakeBool))

core["bad?"] = CoreVars(count:1)   # checks the validity and preserves the former TOS
proc doBadQ*(env: var Environment) =
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].invalid))
core["bad?"].variant.add(CoreObj(args: @["Any"], cmd: doBadQ))

core["good?"] = CoreVars(count:1)   # checks the validity and preserves the former TOS
proc doGoodQ*(env: var Environment) =
  env.past[^1].addLast(newBoolNode(not(env.past[^1][^1].invalid)))
core["good?"].variant.add(CoreObj(args: @["Any"], cmd: doGoodQ))

core["none?"] = CoreVars(count:1)   # checks the validity and preserves the former TOS
proc doNoneQ*(env: var Environment) =
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Null and env.past[^1][^1].invalid))
core["none?"].variant.add(CoreObj(args: @["Any"], cmd: doNoneQ))

core["Null?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doNullQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Null))
  setInvalid(env, invalid)
core["Null?"].variant.add(CoreObj(args: @["Any"], cmd: doNullQ))

core["Bool?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doBoolQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Bool))
  setInvalid(env, invalid)
core["Bool?"].variant.add(CoreObj(args: @["Any"], cmd: doBoolQ))

core["Char?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doCharQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Char))
  setInvalid(env, invalid)
core["Char?"].variant.add(CoreObj(args: @["Any"], cmd: doCharQ))

core["String?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doStringQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == String))
  setInvalid(env, invalid)
core["String?"].variant.add(CoreObj(args: @["Any"], cmd: doStringQ))

core["Word?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doWordQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Word))
  setInvalid(env, invalid)
core["Word?"].variant.add(CoreObj(args: @["Any"], cmd: doWordQ))

core["Int?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doIntQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Int))
  setInvalid(env, invalid)
core["Int?"].variant.add(CoreObj(args: @["Any"], cmd: doIntQ))

core["Float?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doFloatQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Float))
  setInvalid(env, invalid)
core["Float?"].variant.add(CoreObj(args: @["Any"], cmd: doFloatQ))

core["Block?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doBlockQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Block))
  setInvalid(env, invalid)
core["Block?"].variant.add(CoreObj(args: @["Any"], cmd: doBlockQ))

core["List?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doListQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == List))
  setInvalid(env, invalid)
core["List?"].variant.add(CoreObj(args: @["Any"], cmd: doListQ))

core["Seq?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doSeqQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Seq))
  setInvalid(env, invalid)
core["Seq?"].variant.add(CoreObj(args: @["Any"], cmd: doSeqQ))

core["Object?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doObjectQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType == Object))
  setInvalid(env, invalid)
core["Object?"].variant.add(CoreObj(args: @["Any"], cmd: doObjectQ))

core["Coll?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doCollQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Coll"]))
  setInvalid(env, invalid)
core["Coll?"].variant.add(CoreObj(args: @["Any"], cmd: doCollQ))

core["Item?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doItemQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Item"]))
  setInvalid(env, invalid)
core["Item?"].variant.add(CoreObj(args: @["Any"], cmd: doItemQ))

core["Num?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doNumQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Num"]))
  setInvalid(env, invalid)
core["Num?"].variant.add(CoreObj(args: @["Any"], cmd: doNumQ))

core["Alpha?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doAlphaQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Alpha"]))
  setInvalid(env, invalid)
core["Alpha?"].variant.add(CoreObj(args: @["Any"], cmd: doAlphaQ))

core["Alphanum?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doAlphaNumQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Alphanum"]))
  setInvalid(env, invalid)
core["Alphanum?"].variant.add(CoreObj(args: @["Any"], cmd: doAlphaNumQ))

core["Wordy?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doWordyQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Wordy"]))
  setInvalid(env, invalid)
core["Wordy?"].variant.add(CoreObj(args: @["Any"], cmd: doWordyQ))

core["Blocky?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doBlockyQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Blocky"]))
  setInvalid(env, invalid)
core["Blocky?"].variant.add(CoreObj(args: @["Any"], cmd: doBlockyQ))

core["Listy?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doListyQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Listy"]))
  setInvalid(env, invalid)
core["Listy?"].variant.add(CoreObj(args: @["Any"], cmd: doListyQ))

core["Executable?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doExecutableQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  env.past[^1].addLast(newBoolNode(env.past[^1][^1].nodeType in typeMap["Executable"]))
  setInvalid(env, invalid)
core["Executable?"].variant.add(CoreObj(args: @["Any"], cmd: doExecutableQ))

core["local?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doLocalQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var thisNode = env.past[^1][^1]
  var found = false
  if thisNode.nodeType == Word:
    let thisWord = thisNode.wordVal
    for i in countdown(len(env.locals)-1, 0):   # local variables, check from newest to oldest scope
      if env.locals[i].haskey(thisWord): 
        found = true 
        break
  env.past[^1].addLast(newBoolNode(found))
  setInvalid(env, invalid)
core["local?"].variant.add(CoreObj(args: @["Any"], cmd: doLocalQ))

core["global?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doGlobalQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var thisNode = env.past[^1][^1]
  var found = false
  if thisNode.nodeType == Word:
    let thisWord = thisNode.wordVal
    found = env.globals.haskey(thisWord)
  env.past[^1].addLast(newBoolNode(found))
  setInvalid(env, invalid)
core["global?"].variant.add(CoreObj(args: @["Any"], cmd: doGlobalQ))

core["deferred?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doDeferredQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var thisNode = env.past[^1][^1]
  env.past[^1].addLast(newBoolNode(thisNode.deferred))
  setInvalid(env, invalid)
core["deferred?"].variant.add(CoreObj(args: @["Any"], cmd: doDeferredQ))

core["empty?"] = CoreVars(count:1)    # checks the type and preserves the former TOS
proc doEmptyQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var thisNode = env.past[^1][^1]
  env.past[^1].addLast(newBoolNode(len(thisNode.seqVal) == 0))
  setInvalid(env, invalid)
core["empty?"].variant.add(CoreObj(args: @["Coll"], cmd: doEmptyQ))

proc doEmptySQ*(env: var Environment) =
  var invalid = checkInvalid(env, 1)
  var thisNode = env.past[^1][^1]
  env.past[^1].addLast(newBoolNode(len(thisNode.stringVal) == 0))
  setInvalid(env, invalid)
core["empty?"].variant.add(CoreObj(args: @["String"], cmd: doEmptySQ))

proc doEmptyOtherQ*(env: var Environment) =
  env.past[^1].addLast(newBoolNode(false))
  setInvalid(env, true)
core["empty?"].variant.add(CoreObj(args: @["Otherwise"], cmd: doEmptyOtherQ))