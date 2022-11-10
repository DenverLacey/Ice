import std/[options, tables]

import structures/Types

type
  Interpreter* = object
    pids: Table[PidDomain, PidValue]
    functions: Table[Pid, Function]


func newInterpreter*(): Interpreter =
  let pids = {
    pdFunc: 0.PidValue
  }.toTable

  Interpreter(pids: pids)


func nextPid*(self: var Interpreter, domain: PidDomain): Pid =
  var current = addr self.pids[domain]
  result = newPid(domain, current[])
  current[] += 1


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


func getFunction*(self: var Interpreter, value: PidValue): Option[ptr Function] =
  let pid = newPid(pdFunc, value)
  self.getFunction(pid)


iterator functions*(self: var Interpreter): Function =
  for fn in self.functions.values:
    yield fn

