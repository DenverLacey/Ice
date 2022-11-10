import std/strformat

import ../structures/[Ast, Scope, Types]
import ../Interpreter


type
  Context = object
    currentScope: Scope


func beginScope(ctx: var Context) =
  let newScope = Scope(parent: ctx.currentScope)
  ctx.currentScope = newScope


func endScope(ctx: var Context) =
  ctx.currentScope = ctx.currentScope.parent


func establishScopes(ctx: var Context, node: Ast) =
  assert(not ctx.currentScope.isNil, "currentScope shouldn't be null here.")
  node.scope = ctx.currentScope

  case node.kind:
  # Nullary
  of
    astIdent,
    astInt:
      discard

  # Unary
  of
    astNeg:
      ctx.establishScopes(node.sub)
      
  # Binary
  of
    astAssignment,
    astAdd,
    astSub,
    astLet:
      ctx.establishScopes(node.lhs)
      ctx.establishScopes(node.rhs)


func establishScopes*(interp: var Interpreter, nodes: seq[Ast]) =
  var ctx = Context()
  ctx.beginScope()

  let id = interp.nextPid(pdFunc)
  doAssert(id == newPid(pdFunc, 0), fmt"[ERR] Global function Pid is not 0 but {id}")
  if not interp.addFunction(Function(id: id)): raise newException(Exception, "Failed to add global function to function registry.")

  for node in nodes:
    ctx.establishScopes(node)

