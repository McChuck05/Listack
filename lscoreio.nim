## lscoreio
## Listack 0.4.0

import std/deques, std/tables, std/strutils, std/terminal, std/monotimes, std/times
import os
import lstypes, lstypeprint, lstypehelpers, lsconfig, lsparser
# import std/sequtils

when isMainModule:
  var env = initEnvironment()

core["print"] = CoreVars(count: 1)
proc doPrint*(env: var Environment) =
  var item = env.past[^1].popLast()
  stdout.write(item)
core["print"].variant.add(CoreObj(args: @["Any"], cmd: doPrint))

core["println"] = CoreVars(count: 1)
proc doPrintLn*(env: var Environment) =
  var item = env.past[^1].popLast()
  stdout.writeLine(item)
core["println"].variant.add(CoreObj(args: @["Any"], cmd: doPrintLn))

core["pprint"] = CoreVars(count: 1)
proc doPPrint*(env: var Environment) =
  var item = env.past[^1].popLast()
  prettyPrint(item)
core["pprint"].variant.add(CoreObj(args: @["Any"], cmd: doPPrint))

core["pprintln"] = CoreVars(count: 1)
proc doPPrintLn*(env: var Environment) =
  var item = env.past[^1].popLast()
  prettyPrintLn(item)
core["pprintln"].variant.add(CoreObj(args: @["Any"], cmd: doPPrintLn))

core["emit"] = CoreVars(count: 1)
proc doEmit*(env: var Environment) =
  var item = env.past[^1].popLast().intVal
  stdout.write($(char(item)))
core["emit"].variant.add(CoreObj(args: @["Int"], cmd: doEmit))

proc doEmitChar*(env: var Environment) = 
  var item = env.past[^1].popLast().charVal
  stdout.write($(item))
core["emit"].variant.add(CoreObj(args: @["Char"], cmd: doEmitChar))


core["get_line"] = CoreVars(count: 0)
proc doGetLine*(env: var Environment) =
  var item: string = stdin.readline()
  env.past[^1].addLast(newStringNode(item))
core["get_line"].variant.add(CoreObj(args: @[], cmd: doGetLine))

core["get_char"] = CoreVars(count: 0)
proc doGetChar*(env: var Environment) =
  #var item: char = stdin.readChar()
  var item = getch()
  stdout.write($item)
  env.past[^1].addLast(newCharNode(item))
core["get_char"].variant.add(CoreObj(args: @[], cmd: doGetChar))

core["get_password"] = CoreVars(count: 0)
proc doGetPassword*(env: var Environment) =
  var item: string = readPasswordFromStdin()
  env.past[^1].addLast(newStringNode(item))
core["get_password"].variant.add(CoreObj(args: @[], cmd: doGetPassword))

core["get_char_silent"] = CoreVars(count: 0)
proc doGetCharSilent*(env: var Environment) =
  var item: char = getch()
  env.past[^1].addLast(newCharNode(item))
core["get_char_silent"].variant.add(CoreObj(args: @[], cmd: doGetCharSilent))

core["set_err"] = CoreVars(count: 1)
proc doSetErrMsg*(env: var Environment) =
  var item = env.past[^1].popLast().stringVal
  let errmsg = item
  handleError(env, errmsg, env.current)
core["set_err"].variant.add(CoreObj(args: @["String"], cmd: doSetErrMsg))

core["get_err"] = CoreVars(count: 0)
proc doGetErrMsg*(env: var Environment) =
  if len(env.errors) > 0:
    env.past[^1].addLast(newStringNode(env.errors.pop()[0]))
  else:
    env.past[^1].addLast(newStringNode("none"))
core["get_err"].variant.add(CoreObj(args: @[], cmd: doGetErrMsg))

core["copy_err"] = CoreVars(count: 0)
proc doCopyErrMsg*(env: var Environment) =
  if len(env.errors) > 0:
    env.past[^1].addLast(newStringNode(env.errors[^1][0]))
  else:
    env.past[^1].addLast(newStringNode("none"))
core["copy_err"].variant.add(CoreObj(args: @[], cmd: doCopyErrMsg))

core["print_err"] = CoreVars(count: 0)
proc doPrintErrMsg*(env: var Environment) =
  if len(env.errors) > 0:
    stdout.write(env.errors[^1][0], "  ")
    stdout.writeLine(env.errors[^1][1], "  @ line: ", env.errors[^1][1].wordLine , " column: ", env.errors[^1][1].wordColumn)
    if env.debug or env.verbose:
      stdout.writeLine("Offending item: ", env.errors[^1][2])
  else:
    echo "none"
core["print_err"].variant.add(CoreObj(args: @[], cmd: doPrintErrMsg))

core["print_err_all"] = CoreVars(count: 0)
proc doPrintErrAll*(env: var Environment) =
  if len(env.errors) > 0:
    for error in env.errors:
      stdout.write(error[0], "  ")
      stdout.writeLine(error[1], "  @ line: ", error[1].wordLine , " column: ", error[1].wordColumn)
      if env.debug or env.verbose:
        stdout.writeLine("Offending item: ", env.errors[^1][2])
  else:
    echo "none"
core["print_err_all"].variant.add(CoreObj(args: @[], cmd: doPrintErrAll))

core["clear_err"] = CoreVars(count: 0)
proc doClearErrMsg*(env: var Environment) =
  if len(env.errors) > 0:
    discard env.errors.pop()
core["clear_err"].variant.add(CoreObj(args: @[], cmd: doClearErrMsg))

core["clear_err_all"] = CoreVars(count: 0)
proc doClearErrAll*(env: var Environment) =
  while len(env.errors) > 0:
    discard env.errors.pop()
core["clear_err_all"].variant.add(CoreObj(args: @[], cmd: doClearErrAll))

core["how_many_err"] = CoreVars(count: 0)
proc doHowManyErr*(env: var Environment) =
  env.past[^1].addLast(newIntNode(len(env.errors)))
core["how_many_err"].variant.add(CoreObj(args: @[], cmd: doHowManyErr))

core["import"] = CoreVars(count: 1)
proc doImport*(env: var Environment) =
  var fileName = env.past[^1].popLast.stringVal
  if not filename.endsWith(".ls"):
    filename &= ".ls"
  if fileExists(filename):
    var text = readFile(filename)
    text = strip(text)
    text = "  '" & filename[0..^4] & "'  _set_namespace \n " & text & " \n _reset_namespace _end_   \n"
    var newCommands = parseCommands(text)
    expandLeft(env.future, newCommands)
  else:
    let errmsg = "file: " & fileName & " not found"
    handleError(env, errmsg, env.current)
core["import"].variant.add(CoreObj(args: @["String"], cmd: doImport))

core["sp"] = CoreVars(count: 0)
proc doSpace*(env: var Environment) =
  stdout.write(" ")
core["sp"].variant.add(CoreObj(args: @[], cmd: doSpace))

core["cr"] = CoreVars(count: 0)
proc doNewLine*(env: var Environment) =
  stdout.writeline("")
core["cr"].variant.add(CoreObj(args: @[], cmd: doNewLine))

var timer: MonoTime 

core["timer_start"] = CoreVars(count: 0)
proc doStartTimer*(env: var Environment) =
  timer = getMonoTime()
core["timer_start"].variant.add(CoreObj(args: @[], cmd: doStartTimer))

core["timer_check"] = CoreVars(count: 0)  # timer_check --> elapsed time since timer_start in nanoseconds
proc doCheckTimer*(env: var Environment) =
  var elapsed = getMonoTime() - timer
  env.past[^1].addLast(newIntNode(inNanoSeconds(elapsed)))
core["timer_check"].variant.add(CoreObj(args: @[], cmd: doCheckTimer))