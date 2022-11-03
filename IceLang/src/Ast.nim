import std/[options, strformat]

from Tokenizer import Token


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

