import std/[options, tables, strformat]

import structures/Types

type
  Interpreter* = object
    currentPid: Pid
    functions: Table[Pid, Function]


func newInterpreter*(): Interpreter =
  Interpreter(currentPid: 0)


func nextPid*(self: var Interpreter): Pid =
  result = self.currentPid
  inc self.currentPid


func addFunction*(self: var Interpreter, fn: Function): bool =
  return not self.functions.hasKeyOrPut(fn.id, fn)


func getFunction*(self: var Interpreter, id: Pid): Option[ptr Function] =
  if id notin self.functions:
    return

  # @SAFETY:
  # All functions are put into the table during canonicalization phase
  # which never calls this function. Therefore, since the table doesn't
  # get further modified it is safe to take pointers into the table.
  #
  return some(addr self.functions[id])


iterator functions*(self: var Interpreter): Function =
  for fn in self.functions.values:
    yield fn


proc printBytecode*(code: openArray[Bytecode]) =
  template read[T](): T =
    let codeArray = cast[ptr UncheckedArray[Bytecode]](code)
    let tp = cast[ptr T](addr codeArray[i])
    i += sizeof(T)
    tp[]

  var i = 0
  while i < code.len:
    let i0 = i
    let op = read[Bytecode]
    case op
    of bcNone:
      echo fmt"{i0:04X}: None"
    of bcPush0:
      echo fmt"{i0:04X}: Push0"
    of bcPush1:
      echo fmt"{i0:04X}: Push1"
    of bcPushInt:
      let n = read[int]
      echo fmt"{i0:04X}: PushInt `{n}`"
    of bcNeg:
      echo fmt"{i0:04X}: Neg"
    of bcAdd:
      echo fmt"{i0:04X}: Add"
    of bcSub:
      echo fmt"{i0:04X}: Sub"
    else:
      raise newException(Exception, fmt"Invalid bytecode operation `{op}`")

