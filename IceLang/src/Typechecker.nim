import std/[options, strformat]

import Ast
import Scope
import Types
import Utils
from Tokenizer import TokenKind


type
  TypeError = object of CatchableError


func typecheck(node: Ast) =
  case node.kind:
  # Nullary
  of astIdent:
    var ident: string
    case node.tok.kind:
    of tkIdent:
      ident = node.tok.ident
    else:
      raise newException(Exception, "[ERR] node with kind `astIdent` doesn't have an ident token.")

    let binding = node.scope.findBinding(ident).orRaise(TypeError, fmt"Undeclared identifier `{ident}`.")
    node.typ = some(binding.typ)

  of astInt:
    node.typ = some(INT_TYPE)

  # Unary
  of astNeg:
    typecheck(node.sub)

    if node.sub.typ.orRaise(TypeError, "Unary `-` requires its operand to be an `int`.").kind != typInt:
      raise newException(TypeError, "Unary `-` requires its operand to be an `int`.")
    
    node.typ = node.sub.typ

  # Binary
  of astAssignment:
    assert(false, "TODO: Implement typechecking assignments.")

  of astAdd, astSub:
    typecheck(node.lhs)
    typecheck(node.rhs)

    if node.lhs.typ.orRaise(TypeError, "`+` requires its operands to be an `int`.").kind != typInt or
        node.rhs.typ.orRaise(TypeError, "`+` requires its operands to be an `int`.").kind != typInt:
      raise newException(TypeError, "`+` requires its operands to be an `int`.")
    
    node.typ = node.lhs.typ

  of astLet:
    var ident: string 
    case node.lhs.kind:
    of astIdent:
      case node.lhs.tok.kind:
      of tkIdent:
        ident = node.lhs.tok.ident
      else:
        raise newException(Exception, "[ERR] lhs of let node not an ident.")
    else:
      raise newException(Exception, "[ERR] lhs of let node not an ident.")

    typecheck(node.rhs)

    let varType = node.rhs.typ.orRaise(TypeError, "Initializer of let statement must have a type.")
    if not node.scope.addBinding(ident, Binding(kind: bkVar, typ: varType)):
      raise newException(TypeError, fmt"Redeclaration of `{ident}`")


func typecheck*(nodes: seq[Ast]) =
  for node in nodes:
    typecheck(node)

