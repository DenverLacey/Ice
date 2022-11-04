import std/[tables, options]

import Utils
from Interpreter import Pid
from Types import Type


type
  BindingKind* = enum
    bkVar,
    bkProc,

  Binding* = object
    typ*: Type
    case kind*: BindingKind:
    of bkVar:
      stackPosition*: Natural
    of bkProc:
      id*: Pid

  Scope* = ref object
    parent*: Scope
    bindings: Table[string, Binding]


func addBinding*(s: Scope, name: string, binding: Binding): bool =
  assert(not s.isNil, "s is nil!!!")

  if name in s.bindings:
    return false

  s.bindings[name] = binding
  return true


func findBindingPtr*(s: Scope, name: string): Option[ptr Binding] =
  var it = s
  while it != nil:
    if name in it.bindings:
      return some(addr it.bindings[name])

    it = it.parent

  return none(ptr Binding)


func findBinding*(s: Scope, name: string): Option[Binding] =
  let bindingPtr = s.findBindingPtr(name).orReturn(none(Binding))
  return some(bindingPtr[])

