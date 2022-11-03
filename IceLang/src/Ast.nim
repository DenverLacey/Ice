import std/[options, strformat, strutils]

from Tokenizer import Token
from Scope import Scope


type
  Type = Natural # @TODO: use actual `Type` type

  AstKind* = enum
    # Nullary
    astIdent,
    astInt,

    # Unary
    astNeg,

    # Binary
    astAssignment,
    astAdd,
    astSub,
    astLet

  Ast* = ref object
    typ*: Option[Type]
    tok*: Token
    scope*: Scope
    case kind*: AstKind:
    of astNeg:
      sub*: Ast
    of astAssignment, astAdd, astSub, astLet:
      lhs*: Ast
      rhs*: Ast
    else:
      discard


func newAst*(kind: AstKind, token: Token): Ast {.inline.} =
  Ast(typ: none(Type), tok: token, kind: kind)


func newAstUnary*(kind: AstKind, token: Token, sub: Ast): Ast {.inline.} =
  case kind:
  of astNeg:
    Ast(typ: none(Type), tok: token, kind: kind, sub: sub)
  else:
    raise newException(Exception, fmt"Cannot make a unary node of kind `{kind}`.")


func newAstBinary*(kind: AstKind, token: Token, lhs: Ast, rhs: Ast): Ast {.inline.} =
  case kind
  of astAssignment, astAdd, astSub, astLet:
    Ast(typ: none(Type), tok: token, kind: kind, lhs: lhs, rhs: rhs)
  else:
    raise newException(Exception, fmt"Cannot make a binary node of kind `{kind}`.")


func `$`*(node: Ast): string =
  case node.kind:
  of astIdent:
    fmt"(kind: {node.kind}, ident: {node.tok})"
  of astInt:
    fmt"(kind: {node.kind}, val: {node.tok})"
  of astNeg:
    fmt"(kind: {node.kind}, sub: {node.sub})"
  of astAssignment, astAdd, astSub, astLet:
    fmt"(kind: {node.kind}, lhs: {node.lhs}, rhs: {node.rhs})"  


proc print*(node: Ast, indent: Natural = 0)
const INDENT: Natural = 2


proc printField(fieldName: string, field: Ast, indent: Natural) =
  stdout.write(" ".repeat(INDENT * indent))
  stdout.write(fieldName)
  stdout.write(": ")
  field.print(indent)


proc printField[T](fieldName: string, value: T, indent: Natural) =
  echo(" ".repeat(INDENT * indent), fieldName, ": ", value)


proc print*(node: Ast, indent: Natural = 0) =
  echo(node.kind, ':')
  printField("typ", node.typ, indent + 1)
  printField("tok", node.tok, indent + 1)

  case node.kind:
  # Nullary
  of
    astIdent,
    astInt:
      discard

  # Unary
  of
    astNeg:
      printField("sub", node.sub, indent + 1)
  
  # Binary
  of 
    astAssignment,
    astAdd,
    astSub,
    astLet:
      printField("lhs", node.lhs, indent + 1)
      printField("rhs", node.rhs, indent + 1)

