## Listack 0.4.0 Parser
## Copyright (c) 2023, Charles Fout
## All rights reserved.
## Language:  Nim 1.6.12, Linux formatted

import lstypes, lstypehelpers, lstypeprint, lsconfig
import std/strutils, std/deques, std/terminal, std/tables

proc parseCommands*(originalText: string, source: string = "default", debug: bool = false, verbose: bool = false): LsSeq = 
  var 
    parsed: LsSeq
    text: string = originalText & "   "   # fixes a lot of problems that would occur with looking ahead while parsing
    thisChar: char
    current = 0
    node: LsNode
    line = 1
    column = 1
    scopeDepth = 0
    doDefer = false
    wasComment = false
    parseTypeStack = newSeq[LsType]()
    parseStack = newSeq[LsSeq]()
    deferStack = newSeq[bool]()
    callStack = newSeq[bool]()    # word(a b c) --> (a b c .word)
    callFlag1 = false

  let textLen = len(text)-1
  let textLines = text.splitLines()
  parseStack.add(newLsSeq())
    
  proc doFail(message, detail: string) =
    echo ""
    stdout.styledWrite(fgWhite, bgRed, "Parsing error:")
    stdout.styledWriteLine("  ", fgRed, message)
    echo textLines[max(line-1, 0)]
    let spaces = repeat(' ', column-1)
    stdout.styledWriteLine(spaces, fgRed, "^")
    stdout.styledWriteLine("Line:", fgGreen, $line, resetStyle, " Column:", fgGreen, $column, resetStyle, " :: ", fgYellow, detail)
    stdout.styledWrite("Last good element: ")
    if len(parseStack[^1]) > 0:
      prettyPrint(parsestack[^1][^1])
    echo ""
    if debug or verbose: prettyPrint(parseStack[^1])
    raise newException(LsTypeError, "Parsing halted due to error\n")

  proc getThis(): char =
    if current > textLen: 
      doFail("Attempt to read past end of file", "getNext fatal error")
    result = text[current]
    if result == '\n':
      inc line
      column = 0
      
  proc getNext(): char =
    inc current
    if current > textLen: 
      doFail("Attempt to read past end of file", "getNext fatal error")
    result = text[current]
    if result == '\n':
      inc line
      column = 0
    else:
      inc column

  proc peekNext(): char = 
    if current + 1 >= textLen: 
      doFail("Attempt to read past end of file", "peekNext fatal error")
    result = text[current+1]

  proc peek2(): char = 
    if current + 2 >= textLen: 
      doFail("Attempt to read past end of file", "peekNext fatal error")
    result = text[current+2]

  proc peekPrev(): char = 
    if current == 0: 
      doFail("Attempt to read before beginning of file", "peekPrev fatal error")
    result = text[current-1]

  proc advance() =
    inc current
    inc column

  proc getNextToken() # advance declaration

  proc skipWhite() =
    while thisChar in whiteComma and current < textLen:
      thischar = getNext()

  proc ignoreComment() =
    if peekNext() == ':':
      while current < textLen-1 and not (thischar == '.' and  peekNext() == '#'):
        thisChar = getNext()
      advance()
      if current < textLen:
        thisChar = getNext()
    else:
      while thischar != '\n' and current < textLen-1:
        thisChar = getNext()

  proc doEscapeChar(): char =
    thisChar = getNext()
    if debug: stdout.styledWrite(fgGreen, $thisChar)
    case thisChar:
    of '\\': result = '\\'
    of '"': result =  '"'
    of '\'': result = '\''
    of 'n': result =  '\n'
    of 'l': result =  '\l'
    of 'r': result =  '\r'
    of 'c': result =  '\c'
    of 'f': result =  '\f'
    of 't': result =  '\t'
    of 'v': result =  '\v'
    of 'a': result =  '\a'
    of 'b': result =  '\b'
    of 'e': result =  '\e'
    else: 
      if thischar in digits:
        var charNum: string = $thisChar
        if peekNext() in digits:
          charNum.add(getNext())
          if peekNext() in digits:
            charNum.add(getNext())
        var thisNum = parseInt(charNum)
        if thisNum > 255:
          doFail("escaped character number must be in 0..255", "\\" & charNum)
        else:
          result = char(thisNum)
      else:
        doFail("Unrecognized escape character", ("\\" & $thisChar))
    return result

  proc addString(isDouble: bool) =   # "string"
    var target = ""
    if debug: stdout.write(text[current])
    while current < textLen:  # don't check for closing quote here because it may be escaped
      thisChar = getNext()  # skips over initial quote mark
      if debug: stdout.write($thisChar)
      if thisChar == '"' and isDouble:
        break
      elif thisChar == '\'' and not isDouble:
        break
      elif thisChar == '\\': 
        target.add(doEscapeChar())
        if verbose: stdout.styledWrite(fgRed, $target[^1])
      else:
        target.add thisChar
    if debug: stdout.writeline(" >> ", target)
    node = newStringNode(target)
    if thisChar notin ['"', '\'']:
      stdout.styledWrite(fgRed,"Parse warning:  final quote not closed")
    if current < textLen:
      thischar = getNext()    # get next char ready for next token parse

  proc addChar() =
    thisChar = getNext()  # the character is just past the marking '`'
    if thisChar == '\l':
      inc line
      column = 0
    if thisChar == '\\':
      thisChar = doEscapeChar()
    node = newCharNode(thisChar)
    if current < textLen:
      thischar = getNext()    # get next char ready for next token parse

  proc lsParseInt(): string = 
    var intString: string = ""
    while (isDigit(thisChar) or thisChar == '_') and current < textLen:   # depends on the space added at the end
      intString.add(thisChar)
      thisChar = getNext()
    return intString

  proc lsParseFloat(startString: string = "") =   # starts right after the .
    var numString: string = startString
    if thischar in digits:
      numstring.add(lsParseInt())
      if thisChar == 'e' or thisChar == 'E':
        numString.add(thisChar)
        thisChar = getNext()
        if thisChar == '-':
          numString.add(thisChar)
          thisChar = getNext()
        numString.add(lsParseInt())
        if numString[^1] in {'e', 'E', '-'}:
          numString.add('0')
    else:
      numString.add('0')
    var num = parseFloat(numString)
    node = newFloatNode(num)

  proc lsParseNum(startString: string = "") = 
    var numString: string = startString
    numString.add(lsParseInt())
    if thischar == '.' and peekNext() in digits + whiteComma:
      numString.add(thisChar)
      thischar = getNext()
      lsParseFloat(numString)
    else:
      var num = parseInt(numString)
      node = newIntNode(num)

  proc initSeq(kind: LsType, deferred: bool, called: bool = false) = 
    var seqNode = newLsSeq()
    parseTypeStack.add(kind)
    parseStack.add(seqNode)
    deferStack.add(deferred)
    callStack.add(called)
    thisChar = getNext()
    
  proc finishSeq(kind: LsType) =
    if scopeDepth != 0:
      let msg = "Can't close: " & $kind
      doFail("Nesting error: unclosed scope", msg)
    if len(parseTypeStack) == 0:
      let kindString = $kind
      doFail("Attempt to close unopened sequence", kindString)
    let topType = parseTypeStack.pop()
    if topType != kind:
      let detailMsg = "Expected " & ($topType) & ", found " & ($kind)
      doFail("Sequence closing mismatch", detailMsg)
    case topType:
    of List: node = newListNode(parseStack.pop())
    of Block: node = newBlockNode(parseStack.pop())
    of Seq: node = newSeqNode(parseStack.pop())
    of Object: 
      let this: LsSeq = parseStack.pop()
      if len(this) != 3:
        dofail("Object closing error.  Objects must have format: ($ type [arguments] contents $).", $this)
      elif this[1].nodeType notIn typeMap["Coll"]:
        dofail("Object closing error.  Object args (" & $this[1] & ") must be a collection", $this)
      if this[0].nodeType == String:
        node = newObjectNode(this[0].stringVal, this[1].seqVal, this[2])
      elif this[0].nodeType == Word:
        node = newObjectNode(this[0].wordVal, this[1].seqVal, this[2])
      else:
        dofail("Object closing error.  Object type (" & $this[0] & " ) must be a collection", $this)
    else:
      let msg = $topType
      doFail("Sequence closing error, not a sequence type", msg[2..^1])
    node.deferred = deferStack.pop()
    if callStack.pop():
      if topType == Seq:
        var callingWord = parseStack[^1].popLast()
        if callingword.nodeType == Word:
          callingword.wordFix = Postfix
          node.addLast(callingWord)
          if callingWord.deferred:
            callingWord.deferred = false
            node.deferred = true
        else:
          doFail("Call error, calling word not found", $callingWord & "  " & $node)
      else:
        doFail("Call error, sequence not found", $node)
    thisChar = getNext() # move past the closing marker

  proc handleWord() =
    var buildWord, checkEnd = ""
    var doneBuilding = false
    var isSymbol = thisChar in (symbols - {'_'})
    while thisChar in symbols - {'_'} and isSymbol:    # symbols only
      checkEnd = thisChar & peekNext()
      if checkEnd in wordEndings: 
        doneBuilding = true
        break
      buildWord.add thisChar
      thisChar = getNext()
      if thisChar in alphas + {'_'}:
        isSymbol = false
    if (not doneBuilding) and (not isSymbol):
      while thisChar in wordAllowed :
        checkEnd = thisChar & peekNext()
        if checkEnd in wordEndings: break
        buildWord.add thisChar
        thisChar = getNext()
    if buildword.toLowerAscii() == "false":
      buildword = "false"
      node = newBoolNode(false)
    elif buildword.toLowerAscii() == "true":
      buildword = "true"
      node = newBoolNode(true)
    elif wordVerify(buildWord):
      node = newWordNode(buildWord, Infix, '\0', line, column)
      if debug and verbose: echo "buildWord = ", buildWord
      if thischar == ':':
        node.wordFix = Prefix
        thisChar = getNext()
      if buildWord in sugar:
        node = newNullNode()
      elif buildword in immediates:
        if debug and verbose: echo buildWord, " is Immediate"
        node.wordFix = Immediate
    else:
      doFail("Syntax error parsing word, improperly formatted", buildWord)
    if thisChar == ';':   # NameSpace indicator, comes after word
      var buildNameSpace = ""
      thisChar = getNext()    # NameSpace is a letter followed by letters, digits, or '_'
      if thisChar in alphas:
        buildNameSpace.add(thisChar)
        thisChar = getNext()
        while thisChar in alphaNums:
          buildNameSpace.add(thisChar)
          thisChar = getNext()
        node.wordNameSpace = buildNameSpace
      else:
        doFail("NameSpace error, must begin with a letter", $thisChar)
    if node.nodeType == Word and typeMap.hasKey(node.wordVal):
    # if node.nodeType == Word and node.wordVal in PseudoTypes: # convert pseudotype to string so it works with type checker
      node = newStringNode(node.wordVal)

  proc handlePrefixedWord() =
    var 
      functionChar = '\0'
      doDefer = false
      fixMarker: LsFix = Infix
      done = false
    if thisChar == '\\':  # defer next word
      doDefer = true
      thisChar = getNext()
      skipWhite()     # '\' doesn't have to adjoin the word it is deferring
    if thisChar == '@':   # interact with name
      functionChar = getNext()
      if functionChar notin functionChars:
        let msg = "Expected one of " & $functionChars & " found: " & functionChar
        doFail("Prefix error, unrecognized character.", msg)
      thisChar = getNext()
    elif thisChar == '.': # postfix marker
      fixMarker = Postfix
      thisChar = getNext()
    elif thisChar notin wordstart:
      if functionChar != '\0':
        doFail("Syntax error, @" & $functionChar & " only applies to variables", $thisChar)
      doFail("Prefix error, invalid word", $thisChar)
    if not done:
      handleWord()
      if node.nodeType != Null: # account for sugar words being ignored
        if node.nodeType != Word:
          doFail("Prefix error, word not found", $node)
        if functionChar != '\0':
          if node.wordFix != Infix or fixMarker == Postfix:
            doFail("Syntax error, @" & $node.wordFunc & " only applies to variables", $node)
          node.wordfunc = functionChar
          node.wordFix = Immediate
        elif fixMarker == Postfix and node.wordFix == Prefix:
            doFail("Word prefix error, '.' cannot be used with ':'", $node)
        elif node.wordFix != Immediate:
          node.wordFix = Postfix
      if node.nodeType == Word and node.wordFunc != '\0' and node.wordNameSpace != "":
        doFail("Variables don't have a namespace", $node)

  proc openScope() =
    inc scopeDepth
    node = newWordNode("|>", Immediate, '\0', line, column)
    advance()
    thisChar = getNext()

  proc closeScope() =
    if scopeDepth <= 0:
      doFail("Parsing error: attempt to close unopened scope", "Parsing halted")
    dec scopeDepth
    node = newWordNode("<|", Immediate, '\0', line, column)
    advance()
    thisChar = getNext()

  proc getNextToken() =
    var callFlag2 = callFlag1
    callFlag1 = false
    if debug and verbose: echo ">", thisChar, "<"
    if verbose: echo line, ":", column, " > ", $parseStack
    if thisChar == '\\':
      doDefer = true
      thisChar = getNext()
      skipWhite()
    if thisChar == '#':
      ignoreComment()
      skipWhite()
      wasComment = true
    if isDigit(thisChar):    # number
      lsParseNum("")
    elif thisChar == '-' and peekNext() in digits and peekPrev() in digits:   # minus between numbers with no spaces
      node = newWordNode("-", Infix, '\0', line, column)
      thischar = getNext()
    elif thisChar == '-' and isDigit(peekNext()):   # negative number
      thisChar = getNext()
      lsParseNum("-")
    elif thisChar == '.' and isDigit(peekNext()):   # no leading 0
      thischar = getNext()
      lsParseFloat("0.")
    elif thisChar == '-' and peekNext() == '.' and isDigit(text[current+2]):   # negative no leading 0
      advance()
      thisChar = getNext()
      lsParseFloat("-0.")
    elif thisChar == '[':
      initSeq(List, doDefer)
    elif thisChar == ']':
      finishSeq(List)
    elif thisChar == '{':
      initSeq(Block, doDefer)
    elif thisChar == '}':
      finishSeq(Block)
    elif thisChar == '(' and peekNext() != '$':
      initSeq(Seq, doDefer, callFlag2)
    elif thisChar == ')':
      finishSeq(Seq)
    elif thisChar == '(' and peekNext() == '$':
      advance()
      initSeq(Object, doDefer)
    elif thisChar == '$' and peekNext() == ')':
      advance()
      finishSeq(Object)  
    elif thisChar == '|' and peekNext() == '>':
      openScope() # cannot defer
    elif thisChar == '<' and peekNext() == '|':
      closeScope()  # cannot defer
    elif thisChar == '"':
      addString(isDouble = true)
    elif thisChar == '\'':
      addString(isDouble = false)
    elif thisChar == '`':
      addChar()
    elif thisChar == '.' and peekNext() == '.' and peek2() == '.':    # special ... range syntax
      node = newWordNode("...", Immediate, '\0', line, column)
      advance()
      advance()
      thischar = getNext()
    elif thisChar == '.' and peekNext() == '.' and peek2() == '<':    # special ..< range syntax
      node = newWordNode("..<", Immediate, '\0', line, column)
      advance()
      advance()
      thischar = getNext()
    elif thisChar in wordPrefixes:
      handlePrefixedWord()
    elif thischar in wordstart:
      handleWord()
    elif thisChar == ';':
      doFail("Syntax error", "NameSpace marker ';' must appear between word and NameSpace with no spaces between")
    elif current >= textLen:
      discard
    elif not wasComment:
      doFail("Syntax error", ">" & $thisChar & "<")
    if doDefer and not wasComment:
      node.deferred = true
      doDefer = false
    if wasComment:
      wasComment = false
    if node.nodeType == Word and node.wordFix notIn [Postfix, Immediate] and thisChar == '(':
      callFlag1 = true

  # begin parsing loop
  try:
    thisChar = getThis()  # loop always begins with 'current' & 'thisChar' set to the first character to evaluate
    skipWhite()
    while current < textLen:    # Works because of added space
      node = newNullNode()
      getNextToken()    # leaves 'node' set to the next node to add
      if node.nodeType != Null:
        if node.nodeType == Word and node.wordVal == "nil":
          let deferred = node.deferred
          node = newNullNode()
          node.deferred = deferred
        if node.nodeType == Word:
          node.wordSource = source
        parseStack[^1].addLast(node)  # uses stack to deal with nested sequence items
      if verbose: echo "line: ", line, " current: ", current, " column ", column, " node: ", node
      if debug and verbose: echo parsed
      skipWhite()
    if len(parseStack) == 1:  # no unclosed sequences
      if verbose: echo "Parsing succeeded!"
      parsed = parseStack[0]
      return parsed
    else:
      doFail("Parsing error: unclosed sequence(s)", $parseTypeStack)
  except LsTypeError:
    echo getCurrentExceptionMsg()
    raise


when isMainModule:
  echo "\n\n"
  let test1 = "1 -4, 6.8\n.2_3,-.78,\n,[2(%4:8{6 ($2:Float:8.0, 23.19$)}|$ nameis, : string, :'Indigo Montoya'$| 2%)4 6]8 0\n(* Int : 5 7_9_ *) 867_5309 \"867\" '5309' \"don't\" 'can\\'t' \"should\nn\\\"t\"`Q `\' `\n ``"
  var seq1 = parseCommands(test1)
  echo "test1"
  echo seq1
  prettyPrintLn(seq1)
  let test2 = " 123 -321 3.14159\n-2.718281828 [.123 (% 3 : .321\n{5678 910}4713154%)] .456-5-.767 |$TestObject: INT: 42 $| #987654321 \n867.530_9"
  var seq2 = parseCommands(test2)
  echo "\n test2"
  echo seq2
  prettyPrintLn(seq2)
  let test3 = "word1 word2 [.word3 {word4:} ]\\word5 \\ word6 \\.word7 \\word8 123word9.word10.1234.word11@!name1\\@<name2 \\ @>name3@!name4 do &^% .then .+= else: *:"
  let seq3 = parseCommands(test3)
  echo "\n test3"
  echo seq3
  prettyPrintLn(seq3)
  echo ""
  let test4 = """word1(word2 word3)1|>scope1 scope2<|2 @#a @%A @#metaWord (! word4 word5 !) 
  (a|>b c<|d)[]{}()|><| |>e<|(%:f,g h%)
  ($:object:|$name:String:'This is my name'$|$)
  (*Char:`a*)"""
  let seq4 = parseCommands(test4)
  echo "\n test4"
  echo seq4
  prettyPrintLn(seq4)
  let test5 = """ |$ListName:List:[1 2 |> a b <| {`c "d"} 'e' |$AnyObjectName:any:[ |$InnerObjectName:any:2.718281828 $| "should work" |> 123 abc <| (!!)] $| 456 ] $|"""
  echo "\ntest5"
  let seq5 = parseCommands(test5)
  echo seq5
  prettyPrintLn(seq5)
  let test6 = "|* int: 357 *| |*seq:(abc 123 456.0 'def')*| |*Custom: |*STRING:'this should work' *| *| true False TRUE fAlSe (!1+2!) +_2"
  echo "\ntest6: custom"
  let seq6 = parseCommands(test6)
  echo seq6
  prettyPrintLn(seq6)
  let test7 = "word1;NameSpace_A word2:;nameSpace_2.word3;namespace3@%A anyword;b1_ this;works? nil <thing1> _<thing2> <_thing3> thing4> query?"
  echo "\ntest7: namespace"
  let seq7 = parseCommands(test7)
  echo seq7
  prettyPrintLn(seq7)
  echo "\n\n"

