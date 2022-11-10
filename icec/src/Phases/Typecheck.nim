import std/[options, strformat]

import ../Interpreter
import ../Utils
import ../structures/[Ast, Scope, Types]
from Tokenize import TokenKind


type
  TypeError = object of CatchableError


func typecheck(node: Ast) =
  case node.kind:
  # Nullary
  of astIdent:
    var ident = node.tok.ident
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
    var ident = node.lhs.tok.ident
    typecheck(node.rhs)

    let varType = node.rhs.typ.orRaise(TypeError, "Initializer of let statement must have a type.")
    if not node.scope.addBinding(ident, Binding(kind: bkVar, typ: varType)):
      raise newException(TypeError, fmt"Redeclaration of `{ident}`")


func typecheck*(interp: var Interpreter, nodes: seq[Ast]) =
  for node in nodes:
    typecheck(node)

