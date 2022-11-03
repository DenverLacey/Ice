import Ast
import Scope


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


func establishScopes*(nodes: seq[Ast]) =
  var ctx = Context()
  ctx.beginScope()

  for node in nodes:
    ctx.establishScopes(node)

