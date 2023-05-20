## lscoreflow
## Listack 0.0.0

import std/deques, std/tables
import lstypes, lsconfig, lsparser
# import os, std/strutils, std/sequtils, std/terminal, std/math
# import lstypehelpers, lstypeprint
# import lscore, lscoreio, lscorebool, lscorelistutils, lscoremath, lscorebitwise

core["_begin_loop_"] = CoreVars(count: 0)
proc doBeginLoop*(env: var Environment) =
  discard
core["_begin_loop_"].variant.add(CoreObj(args: @[], cmd: doBeginLoop))

core["_end_loop_"] = CoreVars(count: 0)
proc doEndLoop*(env: var Environment) =
  discard
core["_end_loop_"].variant.add(CoreObj(args: @[], cmd: doEndLoop))

core["_end_"] = CoreVars(count: 0)
proc doEnd*(env: var Environment) =
  discard
core["_end_"].variant.add(CoreObj(args: @[], cmd: doEnd))

core["break"] = CoreVars(count: 0)
proc doBreak*(env: var Environment) =
  while not(env.current.nodeType == Word and env.current.wordVal in ["_end_loop_", "_end_"]) and len(env.future) > 0:
    env.current = env.future.popFirst()
  if len(env.future) == 0:
    let errmsg = "End of program found during break"
    handleError(env, errmsg, env.current)
core["break"].variant.add(CoreObj(args: @[""], cmd: doBreak))

core["continue"] = CoreVars(count: 0)
proc doContinue*(env: var Environment) =
  while not (env.current.nodeType == Word and env.current.wordVal in [ "_begin_loop_", "_end_loop_", "_end_"]) and len(env.future) > 0:
    env.current = env.future.popFirst()
  if len(env.future) == 0:
    let errmsg = "End of program found during continue"
    handleError(env, errmsg, env.current)
core["continue"].variant.add(CoreObj(args: @[], cmd: doContinue)) 

core["exit"] = CoreVars(count: 0)
proc doExit*(env: var Environment) =
  while (env.current.nodeType != Word or env.current.wordVal != "_end_") and len(env.future) > 0:
    env.current = env.future.popFirst()
core["exit"].variant.add(CoreObj(args: @[], cmd: doExit)) 

core["halt"] = CoreVars(count: 0)
proc doHalt*(env: var Environment) =
  env.future.clear()
core["halt"].variant.add(CoreObj(args: @[], cmd: doHalt)) 

core["fail"] = CoreVars(count: 0)
proc doFail*(env: var Environment) =
  env.future.clear()
  handleError(env, "fail: execution halted at " & $env.current.wordLine & ":" & $env.current.wordColumn, env.current)
core["fail"].variant.add(CoreObj(args: @[], cmd: doFail)) 

core["quit"] = CoreVars(count: 0)
proc doQuit*(env: var Environment) =
  quit("quit: listack aborted", 0)
core["quit"].variant.add(CoreObj(args: @[], cmd: doQuit)) 





  