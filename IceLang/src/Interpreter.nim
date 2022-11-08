import std/[options, tables]

type
  Pid* = uint64
  Size* = uint32
  Addr* = uint16

  Bytecode* {.size: sizeof(byte).} = enum
    bcNone  = 0,
    bcPush0 = 1,
    bcPush1 = 2,
    bcNeg   = 3,
    bcAdd   = 4,
    bcSub   = 5

  Function* = object
    id*: Pid
    code*: seq[Bytecode]

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

