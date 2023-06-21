## listack
## Listack 0.4.0

import std/deques, std/tables, std/strutils, std/algorithm, std/terminal
import os
import lstypes, lstypeprint, lstypehelpers, lsconfig, lsparser
import lscore, lscoremath, lscoreio, lscorebool, lscorelistutils
import lscoreflow, lscorebitwise
# import std/sequtils

const version = "Listack 0.4.0"
const systemText = staticRead("system.ls")    # system namespace file, written in Listack

proc processCore(env: var Environment):bool =
  let current = env.current
  let thisWord = current.wordVal
  var argList: seq[LsNode]  # chenged for new type structure
  # var argList: seq[LsType]
  var expectedList: seq[string]
  var found = false
  var wordToDo: proc(env: var Environment)
  var typeCheck = true
  var errMsg = ""
  if not core.hasKey(thisWord):   # not a core word
    return false
  if env.debug and env.verbose: echo thisWord, " found"
  if current.wordFunc != '\0':
    errMsg = "@ functions don't apply to core words"
    handleError(env, errMsg, current) # check, log?, ignore @ functions
  if current.wordFix in {Immediate, PostFix} or core[thisWord].count <= 0 or (core[thisWord].count == 1 and current.wordFix == Infix):  # eval, don't relocate
    if len(env.past[^1]) >= abs(core[thisWord].count):  # stack is deep enough
      argList = @[]
      if core[thisWord].count == 0: # don't check for variants where none can exist
        found = true
        wordToDo = core[thisword].variant[^1].cmd
      else:
        for i in 1..abs(core[thisWord].count):
          argList.add(env.past[^1][^i])
          # argList.add(env.past[^1][^i].nodeType)
        argList.reverse()
        for choice in core[thisWord].variant:
          if env.debug and env.verbose: echo "comparing: ", choice.args, " <?> ", argList
          typeCheck = true
          for icount, item in choice.args:
            typecheck = typeCheck and mappedTypeCheck(env, item, argList[icount])
            # typecheck = typeCheck and lsTypeCheck(item, argList[icount])
          if typeCheck:
            found = true
            wordToDo = choice.cmd
            break
          else:
            expectedList = choice.args
      if found:
        if env.verbose: echo "found: ", current, " >>> ", current.wordFix, " :: ", core[thisWord].count
        wordtoDo(env) 
      else:
        for choice in core[thisWord].variant:
          if choice.args[0] == "Otherwise":
            found = true
            wordToDo = choice.cmd
            break 
        if found:
          wordToDo(env)
        else:
          if env.debug: echo "argument mismatch!"
          errMsg = thisWord & " Core argument mismatch.  " & $argList & " found when expecting: " & $expectedList
          handleError(env, errMsg, current)
    else:
      errMsg = thisWord & " insufficient arguments on stack."
      handleError(env, errMsg, current)
  elif current.wordFix == Prefix:
    if env.verbose: echo "Moving prefix word"
    current.wordFix = Postfix
    if core[thisWord].count > len(env.future):
      if env.verbose: echo "attempt to move past end of future thwarted!"
      env.future.addLast(current)
    else:
      insertLeft(env.future, current, core[thisWord].count)
  elif current.wordFix == Infix:  # Infix command must always appear after the first argument
    if env.verbose: echo "Moving infix word"
    current.wordFix = Postfix
    if core[thisWord].count > len(env.future):
      if env.verbose: echo "Attempt to move past end of future thwarted!"
      env.future.addLast(current)
    else:
      insertLeft(env.future, current, core[thisWord].count-1)
  else:
    echo "Fix error: ", current, current.wordFix, core[thisWord].count
    errMsg = "Fix error: " & $current
    handleError(env, errMsg, current)
  return true

proc processFuncs(env: var Environment):bool =
  var current = env.current
  var thisWord = current.wordVal
  var nameSpc = current.wordNameSpace
  var foundWord: FuncVars
  var argList: seq[LsNode]  # changed for new type system
  # var argList: seq[LsType]
  var expectedList: seq[string]
  var wordFound = false
  var varFound = false
  var wordToDo: LsNode
  var typeCheck = true
  var errMsg = ""
  if nameSpc == "core":
    return false
  if nameSpc != "":   # named nameSpace
    if not env.nameSpace.hasKey(nameSpc):
      if env.verbose:
        echo nameSpc, " not found in name spaces"
      errMsg = thisWord & ";" & nameSpc & ": not a valid namespace"
      handleError(env, errMsg, current)
      nameSpc = ""
    elif not env.nameSpace[nameSpc].hasKey(thisWord):
      errMsg = thisWord & " not found in: " & nameSpc
      if env.verbose:
        echo errMsg
      handleError(env, errMsg, current)
      nameSpc = ""
  if nameSpc == "": # search for a nameSpace with the word in it
    for key1, val1 in env.nameSpace:
      if env.verbose: echo "Checking nameSpace: ", key1
      if val1.hasKey(thisWord):
        nameSpc = key1
        wordFound = true
        if env.verbose: echo key1, " contains ", thisWord
    if not wordFound:
      if env.verbose: echo thisWord, ": not found in user functions"
      return false
  foundWord = env.nameSpace[nameSpc][thisWord]
  if env.verbose: echo "found: ", thisWord, ";", nameSpc
  if current.wordFunc != '\0':
    errMsg = "@ functions don't apply to functions"
    handleError(env, errMsg, current)
  if current.wordFix in {Immediate, PostFix} or foundWord.count <= 0 or (foundWord.count == 1 and current.wordFix == Infix):  # don't relocate, check variants
    if len(env.past[^1]) >= abs(foundWord.count): # if stack is deep enough
      argList = @[]
      if foundWord.count == 0: # don't check for variants where none can exist
        varFound = true
        wordToDo = foundWord.variant[^1].cmd
      else:
        for i in 1..abs(foundWord.count): # build type list
          argList.add(env.past[^1][^i]) # changed for new type system
          # argList.add(env.past[^1][^i].nodeType)
        argList.reverse()
        for choice in foundWord.variant:
          if env.debug and env.verbose: echo "comparing: ", choice.args, " <?> ", argList
          typeCheck = true
          for icount, item in choice.args:
            typecheck = typeCheck and mappedTypeCheck(env, item, argList[icount])
            # typecheck = typeCheck and lsTypeCheck(item, argList[icount])
          if typeCheck:
            varFound = true
            wordtoDo = choice.cmd
            break
          else:
            expectedList = choice.args
      if varFound:
        if env.debug and env.verbose: echo "found: ", current, " >>> ", current.wordFix, " :: ", env.nameSpace[nameSpc][thisWord].count
        growLeft(env.future, wordtoDo)  # eval
      elif not core.hasKey(thisWord): # don't check 'otherwise' if this is a core word
        for choice in foundWord.variant:
          if choice.args[0] == "Otherwise":
            varFound = true
            wordToDo = choice.cmd
            break 
        if varFound:
          growLeft(env.future, wordtoDo)  # eval otherwise
        else: # word exists, but arg mismatch
          errMsg = thisWord & " argument mismatch.  " & $argList & " found when expecting: " & $expectedList
          if env.debug: echo errMsg
          handleError(env, errmsg, current)
          varFound = true # don't continue to core, because it's not there
    else:
      errMsg = thisWord & " insufficient arguments on stack."
      if env.debug: echo errMsg
      handleError(env, errMsg, current)
      varFound = true
  elif current.wordFix == Prefix:
    varFound = true
    if env.verbose: echo "Moving prefix word"
    current.wordFix = Postfix
    if env.nameSpace[nameSpc][thisWord].count > len(env.future):
      if env.verbose: echo "attempt to move past end of future thwarted!"
      env.future.addLast(current)
    else:
      insertLeft(env.future, current, env.nameSpace[nameSpc][thisWord].count)
  elif current.wordFix == Infix:  # Infix command must always appear after the first argument
    varFound = true
    if env.verbose: echo "Moving infix word"
    current.wordFix = Postfix
    if env.nameSpace[nameSpc][thisWord].count > len(env.future):
      if env.verbose: echo "attempt to move past end of future thwarted!"
      env.future.addLast(current)
    else:
      insertLeft(env.future, current, env.nameSpace[nameSpc][thisWord].count-1)
  else:
    echo "Fix error: ", current, current.wordFix, env.nameSpace[nameSpc][thisWord].count  # how did you get here?
    errMsg = "Fix error: " & $current
    handleError(env, errMsg, current)
  return varFound

proc processLocals(env: var Environment):bool =
  let current = env.current
  let thisWord = current.wordVal
  var found = false
  for i in countdown(len(env.locals)-1, 0):   # local variables, check from newest to oldest scope
    if env.locals[i].haskey(thisWord): 
      found = true 
      if current.wordFunc in {'\0', '<', '*'}:   # no function = copy to stack, get, show
        addLast(env.past[^1], env.locals[i][thisWord])    
      elif current.wordFunc == '>':         # set
        if len(env.past[^1]) > 0:
          env.locals[i][thisWord] = env.past[^1].popLast()
        else:
          let errmsg = "Attempt to set local variable " & thisWord & " with nonexistent value"
          handleError(env, errmsg, current)
          env.locals[i][thisWord] = newNullNode()   # is this a good idea?
      elif current.wordFunc == '!':   # call
        growLeft(env.future, env.locals[i][thisWord])
      elif current.wordFunc == '#':           # check this when decide how to do meta function
        let errmsg = "Cannot use meta notation # outside meta block"
        handleError(env, errmsg, current)
      elif current.wordFunc == '%':           # check this when decide how to do meta function
        let errmsg = "Cannot use meta notation % outside meta block"
        handleError(env, errmsg, current)
      elif current.wordFunc == '?':   # depth
        if env.locals[i][thisWord].nodeType == Null and env.locals[i][thisWord].invalid == true:
          growRight(env.past[i], newIntNode(0))
        else:
          growRight(env.past[i], newIntNode(1))
      elif current.wordFunc == '/':   # clear
        env.locals[i][thisWord] = newNullNode()
      else:
        let errmsg = "Unrecognized @ function character: " & current.wordFunc
        handleError(env, errmsg, current)
      break
  return found

proc processGlobals(env: var Environment):bool =
  let current = env.current
  let thisWord = current.wordVal
  var found = false
  if env.globals.haskey(thisWord):  # global stacks
    found = true
    if current.wordFunc == '\0':   # default behavior
      if len(env.globals[thisWord]) > 0:
        addLast(env.past[^1], deepCopy(env.globals[thisWord][^1]))   # copy top entry to stack
      else:
        let errmsg = "Attempt to copy data from empty global stack: " & $thisWord
        handleError(env, errmsg, current)
        addLast(env.past[^1], newNullNode())                # is this a good idea???
    elif current.wordFunc == '*':   # copy entire global stack as a list to TOS
      env.past[^1].addLast(newListNode(env.globals[thisWord]))
    elif current.wordFunc == '<':   # get/pop
      if len(env.globals[thisWord]) > 0:
        addLast(env.past[^1], popLast(env.globals[thisWord]))   # copy top entry to stack
      else:
        let errmsg = "Attempt to copy data from empty global stack: " & $thisWord
        handleError(env, errmsg, current)
        addLast(env.past[^1], newNullNode())                # is this a good idea???
    elif current.wordFunc == '>':   # set/push
      if len(env.past[^1]) > 0:
        addLast(env.globals[thisWord], popLast(env.past[^1])) 
      else:
        let errmsg = "Attempt to copy data from empty stack to global: " & $thisWord
        handleError(env, errmsg, current)
        addLast(env.globals[thisWord], newNullNode())       # is this a good idea???
    elif current.wordFunc == '!':   # call
      if len(env.globals[thisWord]) > 0:
        growLeft(env.future, env.globals[thisWord][^1]) 
      else:
        let errmsg = "Attempt to call command from empty global stack: " & $thisWord
        handleError(env, errmsg, current)
        addFirst(env.future, newNullNode())                # is this a good idea???
    elif current.wordFunc == '?':   # depth
      addLast(env.past[^1], newIntNode(len(env.globals[thisWord])))   # how many entries in this global stack
    elif current.wordFunc == '/':   # clear
      env.globals[thisWord].clear()
    elif current.wordFunc == '#':
      let errmsg = "Cannot use meta notation # outside meta block"
      handleError(env, errmsg, current)
    elif current.wordFunc == '%':
      let errmsg = "Cannot use meta notation % outside meta block"
      handleError(env, errmsg, current)
    else:
      let errmsg = "Unrecognized @ function character: " & current.wordFunc
      handleError(env, errmsg, current)
    found = true
    return found

proc processCommand(env: var Environment)=
  let current = env.current
  var thisWord: string
  var found = false
  var errDepth = len(env.errors)
  if env.debug:
    stdout.write("  ")
    prettyPrint(current)
    stdout.write("  ")
  if env.verbose: 
    stdOut.write "\n>"
    prettyPrintLn(env.past)
  if current.deferred:
    if env.verbose: echo "Deferring"
    current.deferred = false
    env.past[^1].addLast(current)
  elif current.nodeType notin {Word, Seq}:
    env.past[^1].addLast(current)
  elif current.nodeType == Seq:
    expandLeft(env.future, current.seqVal)
    if env.debug: echo ""
  else: # Word
    if env.verbose: echo "processing ", current
    thisWord = current.wordVal
    if env.debug and env.verbose: echo "Searching for: >", thisWord, "<"
    if thisWord in sugar:
      found = true
    if not found:
      found = processLocals(env)
    if not found:
      found = processGlobals(env)
    if not found:
      found = processFuncs(env)
    if not found: 
      found = processCore(env)
    if not found:
      if typeMap.hasKey(thisWord):
        found = true
        env.past[^1].addLast(newStringNode(thisWord)) # convert type word to string
    if not found:                                    
      if env.debug: echo "Key not found: ", thisWord
      let errmsg = thisWord & " not found."   
      handleError(env, errmsg, current)
  if len(env.errors) > errDepth:
    let howMany = len(env.errors) - errDepth
    if howMany > 1:
      stdout.styledWrite("\n", $howMany, " ", bgRed, "errors")
    else:
      stdout.styledWrite("\n1 ", bgRed, "err")
  if env.verbose: 
    stdOut.write ">>>"
    prettyPrintLn(env.past)


proc listack(env: var Environment, repl: bool) =
  if env.debug or env.verbose:
    prettyPrintLn(env.future)
    prettyPrintLn(env.past)
    echo ""
  if env.verbose:
    echo(env.locals)
    echo(env.globals)
    echo ""
  if not repl:
    while len(env.future) > 0:
      if env.debug: prettyPrintLn(env.future)
      env.current = env.future.popFirst()
      processCommand(env)
      if env.debug: echo "\nErrors: ", env.errors
  else:                                             # repl begins here
    var text: string
    echo version, "  REPL\nEnter blank line to quit."
    stdOut.write(">>> ")
    text = stdIn.readLine()
    while text != "":
      text = "   " & text & "   "
      if env.verbose: echo text
      try:
        env.future = parseCommands(text, env.currentNameSpace)
        prettyPrintLn(env.future)
        echo ""
        while len(env.future) > 0:
          env.current = env.future.popFirst()
          if env.debug: # and env.verbose: 
            stdout.write("\nFuture: ")
            prettyPrintLn(env.future)
            stdout.write("Current: ")
            prettyPrintLn(env.current)
            stdout.write("Past: ")
            prettyPrintLn(env.past[^1])
          processCommand(env)
          if env.verbose: echo "\nErrors: ", env.errors
        stdOut.write("\nstack: ")
        prettyPrintLn(env.past[^1])
      except LsTypeError:
        echo "Unparsable line ignored"
      echo ""
      stdOut.write(">>> ")
      text = stdIn.readLine()

when isMainModule:
  var
    debug, verbose, silent, repl: bool = false
    text: string = ""
  let paramList = commandLineParams()
  if "-debug" in paramList: debug = true
  if "-verbose" in paramList: verbose = true
  if "-silent" in paramList:    # not used yet
    debug = false
    verbose = false
    silent = true
  let numParams: int = paramCount()
  if "-help" in paramList or "help" in paramList:
    echo version
    echo "Use by entering:  listack filename [-debug] [-verbose] "
    echo "If no filename is specified, Listack will run interactively."
    quit("\nListack aborted", 0)
  var env = initEnvironment(debug, verbose, silent)
  env.currentNameSpace = "system"
  env.future = parseCommands(systemText, "system")    # process the system namespace
  while len(env.future) > 0:
    env.current = env.future.popFirst()
    processCommand(env)
  env.currentNameSpace = "default"
  if numParams > 0:
    let filename = paramList[0]
    if fileExists(filename):
      text = readFile(filename)
      text = strip(text)
      var shortname = filename
      if fileName.endsWith(".ls"):
        shortName = fileName[0..^4]
      env.currentNameSpace = shortName
      text = "  _set_namespace: '" & shortName & "' \n" & text & "\n _reset_namespace _end_   \n"
      env.future = parseCommands(text, shortName, debug, verbose)
  else:
    repl = true
  if verbose:
    stdOut.write("Core: ")
    for item in core.keys:
      stdOut.write(item, " ")
    stdOut.writeLine("")
  try:
    listack(env, repl)              # do the thing!
  except CatchableError:
    let errMsg = getCurrentException().name
    echo errMsg
    if len(env.errors) > 0:
      echo "\nErrors encountered during execution:"
      for item in env.errors:
        echo item
      echo ""
    stdout.write("Final Stack: ")
    prettyPrintLn(env.past)
    stdout.write("Current: ")
    prettyPrintLn(env.current)
    stdout.write("Future: ")
    prettyPrintLn(env.future)
  echo ""
  if repl or debug:
    stdout.write("Final Stack: ")
    prettyPrintLn(env.past)
  if env.debug and env.verbose:
    for nameVal, nameCont in env.nameSpace.pairs():
      echo "NameSpace: ", nameVal
      for wordVal, wordCont in nameCont.pairs():
        echo "  Word: ", wordVal
        for variants in wordCont.variant:
          echo "    ", variants.args, " : ", variants.cmd
  if len(env.errors) > 0:
    echo "\nErrors encountered during execution:"
    for item in env.errors:
      echo item
    echo ""
  else:
    echo "\n", version, " completed successfully\n"


## listack
## Listack 0.4.0
## Language:  Nim 1.6.12, Linux formatted
## Copyright (c) 2023, Charles Fout
## All rights reserved.
## May be freely redistributed and used with attribution under GPL3.
