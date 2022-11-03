import std/[tables, options]
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
      discard
    of bkProc:
      id: Pid

  Scope* = ref object
    parent*: Scope
    bindings: Table[string, Binding]


func addBinding*(s: Scope, name: string, binding: Binding): bool =
  assert(not s.isNil, "s is nil!!!")

  if name in s.bindings:
    return false

  s.bindings[name] = binding
  return true


func findBinding*(s: Scope, name: string): Option[Binding] =
  var it = s
  while it != nil:
    if name in it.bindings:
      return some(it.bindings[name])

    it = it.parent

  return none(Binding)

