import std/deques, std/terminal
import lstypes


proc `$`*(thisNode: LsNode): string =  
  var nodeString = ""
  if thisNode.invalid:
    nodeString.add("none(")
    nodeString.add($thisNode.nodeType)
    nodeString.add(")")
  else:
    if thisNode.deferred:
      nodeString.add("\\")
    case thisNode.nodeType
    of Char:
      let c = thisNode.charVal
      nodeString.add(c)
    of String: 
      nodeString.add(thisNode.stringVal)
    of Word: 
      if thisNode.wordFunc != '\0':
        nodeString.add("@" & thisNode.wordFunc)
      if thisNode.wordFix == Postfix:
        nodeString.add '.'
      nodeString.add(thisNode.wordVal)
      if thisNode.wordFix == PreFix:
        nodeString.add ':'
      if thisNode.wordNameSpace != "":
        nodeString.add(";" & thisNode.wordNameSpace)
    of Int: nodeString.addQuoted(thisNode.intVal)
    of Float: nodeString.addQuoted(thisNode.floatVal)
    of Bool: nodeString.addQuoted(thisNode.boolVal)
    of Block:
      nodeString.add "{"
      let thisSeq = thisnode.seqVal
      for item in thisSeq:
        nodeString.add $item
        nodeString.add " "
      if len(thisSeq) > 0:
        nodeString = nodeString[0..^2]  # remove trailing " "
      nodeString.add "}"
    of List:
      nodeString.add "["
      let thisSeq = thisNode.seqVal
      for item in thisSeq:
        nodeString.add $item
        nodeString.add ", "
      if len(thisSeq) > 0:
        nodeString = nodeString[0..^3]  # remove trailing ", "
      nodeString.add "]"
    of Seq:
      nodeString.add "("
      let thisSeq = thisNode.seqVal
      for item in thisSeq:
        nodeString.add $item
        nodeString.add " "
      if len(thisSeq) > 0:
        nodeString = nodeString[0..^2]  # remove trailing " "
      nodeString.add ")"
    of Object:
      nodeString.add($thisNode.objectVal)
    of Null:
      nodeString.add "nil"
  return nodeString

proc `$`*(thisDeq: LsSeq): string = 
  var deqString: string
  for item in thisDeq:
    deqString.add $item
    deqString.add " "
  return deqString

proc `$`*(thisSeq: seq[LsSeq]): string = 
  var seqString: string
  for item in thisSeq:
    seqString.add "[ "
    seqString.add $item
    seqString.add "]\n"
  return seqString

proc prettyPrint*(thisNode: LsNode) =  
  if thisNode.invalid:
    stdout.styledWrite(fgRed, styleBright, "none(")
    stdout.styledWrite(fgBlue, $thisNode.nodeType)
    stdout.styledWrite(fgRed, ")")
  else:
    if thisNode.deferred:
      stdout.styledWrite(fgYellow, styleBright, "\\")
    case thisNode.nodeType
    of Char:
      var nodeString = ""
      stdout.styledWrite(fgBlue, styleDim, "`")
      let c = thisNode.charVal
      if c in {'\32'..'\126'} or c > 127.char:
        nodeString.add(c)
      else:
        nodeString.addEscapedChar(c)
      stdout.styledWrite(fgBlue, nodeString)
    of String: 
      var nodeString = ""
      stdout.styledWrite(fgCyan, styleDim, "\"")
      for c in thisNode.stringVal:
        if c in {'\32'..'\126'} or c > 127.char:
          nodeString.add(c)
        else:
          nodeString.addEscapedChar(c)
      stdout.styledWrite(fgCyan, nodeString)
      stdout.styledWrite(fgCyan, styleDim, "\"")
    of Word:
      if thisNode.wordFunc != '\0':
        stdout.styledWrite(fgRed, styleItalic, "@", styleBright, $thisNode.wordFunc)
      if thisNode.wordVal == "|>" or thisNode.wordVal == "<|":
        stdout.styledWrite(fgRed, styleBright, thisNode.wordVal)
      else:
        if thisNode.wordFix == Postfix:
          stdout.styledWrite(fgGreen, ".", thisNode.wordVal)
        elif thisNode.wordFix == Prefix:
          stdout.styledWrite(fgYellow, thisNode.wordVal)
        elif thisNode.wordFix == Immediate:
          stdout.styledWrite(fgRed, thisNode.wordVal)
        else:
          stdout.styledWrite(fgMagenta, thisNode.wordVal)
        if thisNode.wordFix == PreFix:
          stdout.styledWrite(fgYellow, ":")
        if thisNode.wordNameSpace != "":
          stdout.styledWrite(fgBlue, styleItalic, ";", thisNode.wordNameSpace)
    of Int: 
      stdout.styledWrite($thisNode.intVal)
    of Float: 
      stdout.styledWrite($thisNode.floatVal)
    of Bool: 
      stdout.styledWrite(fgGreen, $thisNode.boolVal)
    of Block:
      stdout.styledWrite(fgYellow, styleBright, "{ ")
      let thisBlock = thisnode.seqVal
      for count, item in thisBlock:
        prettyPrint(item)
        stdout.styledWrite(" ")
      stdout.styledWrite(fgYellow, styleBright, "}")
    of List:
      stdout.styledWrite(fgGreen, styleBright, "[ ")
      let thisList = thisnode.seqVal
      for count, item in thisList:
        prettyPrint(item)
        if count < len(thisList)-1:
          stdout.styledWrite(fgGreen, ", ")
      if len(thisList) > 0: stdout.styledWrite(" ")
      stdout.styledWrite(fgGreen, styleBright, "]")
    of Seq:
      stdout.styledWrite(fgMagenta, styleBright, "( ")
      let thisList = thisnode.seqVal
      for item in thisList:
        prettyPrint(item)
        stdout.styledWrite(fgMagenta, " ")
      stdout.styledWrite(fgMagenta, styleBright, ")")
    of Object:
      stdout.styledWrite(fgBlue,"($ ")
      var this = thisnode.objectType
      stdout.styledWrite(fgBlue, "{ ")
      for item in this:
        prettyPrint(item)
        stdout.styledWrite(" ")
      stdout.styledWrite(fgBlue, "} [")
      this = thisnode.objectArgs
      for count, item in this:
        prettyPrint(item)
        if count < len(this)-1:
          stdout.styledWrite(fgBlue, ", ")
      stdout.styledWrite(fgBlue, "] ")
      prettyPrint(thisNode.objectVal)
      stdout.styledWrite(fgBlue, " $)")
    of Null:
      stdout.styledWrite(fgRed, styleBright, "nil")

proc prettyPrint*(thisDeq: LsSeq)= 
  if len(thisDeq) > 0:
    for item in thisDeq:
      prettyPrint(item)
      stdout.styledWrite(" ")

proc prettyPrint*(thisSeq: seq[LsSeq])=
  if len(thisSeq) > 0:
    for item in thisSeq:
      stdout.styledWrite("[ ")
      prettyPrint(item)
      stdout.styledWrite("]")

proc prettyPrintLn*(this: LsNode)= 
  prettyPrint(this)
  stdout.styledWriteLine("")

proc prettyPrintLn*(thisDeq: LsSeq)= 
  prettyPrint(thisDeq)
  stdout.styledWriteLine("")

proc prettyPrintLn*(thisSeq: seq[LsSeq])=
  prettyPrint(thisSeq)
  stdout.styledWriteLine("")


when isMainModule:
  discard
## lstypeprint
## Listack 0.4.0
## Language:  Nim 1.6.12, Linux formatted
## Copyright (c) 2023, Charles Fout
## All rights reserved.
## May be freely redistributed and used with attribution under GPL3.