
type
  Pid* = BiggestUInt
  Interpreter* = object
    currentPid: Pid


func newInterpreter*(): Interpreter =
  Interpreter(currentPid: 0)


proc nextPid*(self: var Interpreter): Pid =
  result = self.currentPid
  inc self.currentPid
