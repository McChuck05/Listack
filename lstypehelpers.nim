import std/deques, std/math, std/algorithm, std/tables
import lstypes, lstypeprint

proc newLsSeq*(size = 4): LsSeq =
  return initDeque[LsNode](size)

proc newNullNode*(isInvalid: bool = false): LsNode =
  return LsNode(nodeType: Null, deferred: false, invalid: isInvalid)

proc newCharNode*(val: char = '\0'): LsNode =
  return LsNode(nodeType: Char, charVal: val, deferred: false, invalid: false)

proc newStringNode*(val: string = ""): LsNode =
  return LsNode(nodeType: String, stringVal: val, deferred: false, invalid: false)

proc newWordNode*(val: string = "", fix: LsFix = PostFix, wFunc: char = '\0', line: Natural = 0, column: Natural = 0, source: string = "default"): LsNode =
  return LsNode(nodeType: Word, wordVal: val, wordFix: fix, wordFunc: wFunc, wordLine: line, wordColumn: column, deferred: false, invalid: false, wordSource: source)

proc newIntNode*(val: int64 = 0): LsNode =
  return LsNode(nodeType: Int, intVal: val, deferred: false, invalid: false)
  
proc newFloatNode*(val: float64 = 0.0): LsNode =
  return LsNode(nodeType: Float, floatVal: val, deferred: false, invalid: false)

proc newBoolNode*(val: bool = false): LsNode =
  return LsNode(nodeType: Bool, boolVal: val, deferred: false, invalid: false)

proc newBlockNode*(val: LsSeq = newLsSeq()): LsNode =
  return LsNode(nodeType: Block, seqVal: val, deferred: false, invalid: false)

proc newListNode*(val: LsSeq = newLsSeq()): LsNode =
  return LsNode(nodeType: List, seqVal: val, deferred: false, invalid: false)
  
proc newSeqNode*(val: LsSeq = newLsSeq()): LsNode =
  return LsNode(nodeType: Seq, seqVal: val, deferred: false, invalid: false)

proc newObjectNode*(kind: string = "none?", args: LsSeq = newLsSeq(), val: LsNode = newNullNode()): LsNode =
   return LsNode(nodeType: Object, objectType: kind, objectArgs: args, objectVal: val, deferred: false, invalid: false)

proc copyNode*(node: LsNode): LsNode = 
  var newNode: LsNode
  deepCopy(newNode, node)
  return newNode

proc reversed*(startSeq: LsSeq):LsSeq =
  var finalSeq:LsSeq
  for item in startSeq:
    if item.nodeType == Word and item.wordVal in sugar:
      discard
    else:
      addFirst(finalSeq, item)
  return finalSeq

proc expandLeft*(targetSeq: var LsSeq, bySeq: LsSeq, invalid: bool = false)=
  var byThis: LsSeq = deepcopy(bySeq)
  for i in 0..<len(bySeq):
    if bySeq[^1].nodeType == Word and bySeq[^1].wordVal in sugar:
      discard
    else:
      targetseq.addFirst(popLast(byThis))
      targetSeq[0].invalid = targetSeq[0].invalid or invalid

proc growLeft*(targetSeq: var LsSeq, what: LsNode)= 
  if  what.nodeType in typeMap["Blocky"]:
    expandLeft(targetSeq, what.seqVal, what.invalid)
  else:
    if what.nodeType == Word and what.wordVal in sugar:
      discard
    else:
      targetSeq.addFirst(what)
  
proc expandRight*(targetSeq: var LsSeq, bySeq: var LsSeq, invalid: bool = false)=
  var byThis = deepCopy(bySeq)
  for i in 0..<len(bySeq):
    if bySeq[0].nodeType == Word and bySeq[0].wordVal in sugar:
      discard
    else:
      targetSeq.addLast(popFirst(byThis))
      targetSeq[^1].invalid = targetSeq[^1].invalid or invalid

proc growRight*(targetSeq: var LsSeq, what: LsNode)= 
  if what.nodeType in typeMap["Blocky"]:
    expandRight(targetSeq, what.seqVal, what.invalid)
  else:
    if what.nodeType == Word and what.wordVal in sugar:
      discard
    else:
      targetSeq.addLast(what)

proc rollLeft*(targetseq: var LsSeq, count: int64)=
  var icount = count mod len(targetseq)
  if count > 0:
    for i in 1..icount:
      targetSeq.addLast(targetSeq.popFirst())
  elif count < 0:
    for i in 1..abs(icount):
      targetSeq.addFirst(targetSeq.popLast())
  else:
    discard

proc rollRight*(targetseq: var LsSeq, count: int64)=
  var icount = count mod len(targetseq)
  if count < 0:
    for i in 1..abs(icount):
      targetSeq.addLast(targetSeq.popFirst())
  elif count > 0:
    for i in 1..icount:
      targetSeq.addFirst(targetSeq.popLast())
  else:
    discard

proc insertLeft*(targetseq: var LsSeq, item: LsNode, where: int64)=
  if abs(where) > len(targetSeq):
    let message = "Attempt to insertLeft past end of sequence"
    raise newException(LsTypeError, message)
  if where == len(targetSeq):
    targetseq.addLast(item)
  elif where == -len(targetSeq):
    targetSeq.addFirst(item)
  elif where > 0:
    targetSeq.rollLeft(where)
    targetSeq.addFirst(item)
    targetSeq.rollRight(where)
  elif where < 0:
    targetSeq.rollRight(where)
    targetseq.addLast(item)
    targetSeq.rollLeft(where)
  else:
    targetSeq.addFirst(item)

proc insertRight*(targetseq: var LsSeq, item: LsNode, where: int64)=
  if abs(where) > len(targetSeq):
    let message = "Attempt to insertLeft past end of sequence"
    raise newException(LsTypeError, message)
  if where == len(targetSeq):
    targetSeq.addFirst(item)
  elif where == -len(targetSeq):
    targetSeq.addLAst(item)
  elif where < 0:
    targetSeq.rollLeft(where)
    targetSeq.addFirst(item)
    targetSeq.rollRight(where)
  elif where > 0:
    targetSeq.rollRight(where)
    targetseq.addLast(item)
    targetSeq.rollLeft(where)
  else:
    targetSeq.addLast(item)

proc delFromLeft*(targetSeq: var LsSeq, where: int64)=
  if abs(where) >= len(targetSeq):
    let message = "Attempt to insertLeft past end of sequence"
    raise newException(LsTypeError, message)
  if where == len(targetseq) - 1:
    targetSeq.shrink(fromLast = 1)
  elif where == -(len(targetSeq) - 1):
    targetSeq.shrink(fromFirst = 1)
  elif where > 0:
    targetSeq.rollLeft(where)
    targetSeq.shrink(fromFirst = 1)
    targetSeq.rollRight(where)
  elif where < 0:
    targetSeq.rollRight(where)
    targetSeq.shrink(fromFirst = 1)
    targetSeq.rollLeft(where)
  else:
    targetSeq.shrink(fromFirst = 1)

proc delFromRight*(targetSeq: var LsSeq, where: int64)=
  if abs(where) >= len(targetSeq):
    let message = "Attempt to insertLeft past end of sequence"
    raise newException(LsTypeError, message)
  if where == len(targetseq) - 1:
    targetSeq.shrink(fromFirst = 1)
  elif where == -(len(targetSeq) - 1):
    targetSeq.shrink(fromLast = 1)
  elif where < 0:
    targetSeq.rollLeft(where)
    targetSeq.shrink(fromLast = 1)
    targetSeq.rollRight(where)
  elif where > 0:
    targetSeq.rollRight(where)
    targetSeq.shrink(fromLast = 1)
    targetSeq.rollLeft(where)
  else:
    targetSeq.shrink(fromLast = 1)

proc getSeq*(target: LsNode): LsSeq = 
  if target.nodeType in typeMap["Coll"]:
    return target.seqVal
  elif target.nodeType == Object and target.objectVal.nodeType in typeMap["Coll"]:
    return target.objectVal.seqVal
  else:
    raise newException(LsTypeError, "Attempted to get sequence from item: " & $target)

proc addLast*(target: var LsNode, item: LsNode)=
  if target.nodeType in typeMap["Coll"]:
    target.seqVal.addLast(item)
  else:
    let message = "Attempt to addLast " & $item & " to " & $target
    raise newException(LsTypeError, message)

proc addFirst*(target: var LsNode, item: LsNode)=
  if target.nodeType in typeMap["Coll"]:
    target.seqVal.addFirst(item)
  else:
    let message = "Attempt to addFirst " & $item & " to " & $target
    raise newException(LsTypeError, message)

proc len*(target: LsNode): int64 =
  if target.nodeType in typeMap["Coll"]:
    return len(target.seqVal)
  elif target.nodeType == Null:
    return 0
  else:
    return 1

proc lsSorted*(target: var LsSeq): LsSeq =
  var sortedList: LsSeq
  if len(target) > 0:
    var collType = target[0].nodeType
    for item in target:
      if item.nodeType != collType:
        let message = "Cannot sort a mixed list"
        raise newException(LsTypeError, message)
    case collType:
    of Null:
      var sortable: seq[bool]
      for item in target:
        sortable.add(item.invalid)
      sort(sortable, system.cmp[bool], order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newNullNode(item))
    of Bool:
      var sortable: seq[bool]
      for item in target:
        sortable.add(item.boolVal)
      sort(sortable, system.cmp[bool], order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newBoolNode(item))
    of Char:
      var sortable: seq[char]
      for item in target:
        sortable.add(item.charVal)
      sort(sortable, system.cmp[char], order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newCharNode(item))
    of String:
      var sortable: seq[string]
      for item in target:
        sortable.add(item.stringVal)
      sort(sortable, system.cmp[string], order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newStringNode(item))
    of Word: 
      proc myCollCmp(x,y: LsNode): int = 
        return system.cmp(x.wordVal, y.wordVal)
      var sortable: seq[LsNode]
      for item in target:
        sortable.add(item)
      sort(sortable, myCollCmp, order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(item)
    of Int:
      var sortable: seq[int64]
      for item in target:
        sortable.add(item.intVal)
      sort(sortable, system.cmp[int64], order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newIntNode(item))
    of Float:
      var sortable: seq[float64]
      for item in target:
        sortable.add(item.floatVal)
      sort(sortable, system.cmp[float64], order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newFloatNode(item))
    of Block:
      proc myCollCmp(x,y: LsSeq): int = 
        return system.cmp(len(x), len(y))
      var sortable: seq[LsSeq]
      for item in target:
        sortable.add(item.seqVal)
      sort(sortable, myCollCmp, order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newBlockNode(item))
    of List:
      proc myCollCmp(x,y: LsSeq): int = 
        return system.cmp(len(x), len(y))
      var sortable: seq[LsSeq]
      for item in target:
        sortable.add(item.seqVal)
      sort(sortable, myCollCmp, order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newListNode(item))
    of Seq:
      proc myCollCmp(x,y: LsSeq): int = 
        return system.cmp(len(x), len(y))
      var sortable: seq[LsSeq]
      for item in target:
        sortable.add(item.seqVal)
      sort(sortable, myCollCmp, order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(newSeqNode(item))
    of Object:
      proc myCollCmp(x,y: LsNode): int = 
        return system.cmp(x.objectVal, y.objectVal)
      var sortable: seq[LsNode]
      for item in target:
        sortable.add(item)
      sort(sortable, myCollCmp, order = SortOrder.Ascending)
      for item in sortable:
        sortedList.addLast(item)
  return sortedList
  

when isMainModule:
  discard

## lstypehelpers
## Listack 0.4.0
## Language:  Nim 1.6.12, Linux formatted
## Copyright (c) 2023, Charles Fout
## All rights reserved.
## May be freely redistributed and used with attribution under GPL3.