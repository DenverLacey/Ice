import std/[options, strformat]

import Utils
import Tokenizer
import Ast


type
  Parser = object
    tokenizer: Tokenizer

  ParseError* = object of CatchableError
    discard


func parsePrecedence(p: var Parser, prec: TokenPrecedence): Ast


func check(p: var Parser, tokenKind: TokenKind): bool =
  let token = p.tokenizer.peek().orReturn(false)
  return token.kind == tokenKind


func match(p: var Parser, tokenKind: TokenKind): Option[Token] =
  if not p.check(tokenKind):
    return
  p.tokenizer.next()


func expect(p: var Parser, tokenKind: TokenKind, msg: string): Token =
  let token = p.match(tokenKind).orRaise(ParseError, msg)
  return token


func parseIdent(p: var Parser, errMsg: string): Ast =
  let identToken = p.expect(tkIdent, errMsg)
  return newAst(astIdent, identToken)


func parseUnary(p: var Parser, kind: AstKind, token: Token): Ast =
  let sub = p.parsePrecedence(tpUnary)
  return newAstUnary(kind, token, sub)


func parseBinary(p: var Parser, kind: AstKind, prec: TokenPrecedence, lhs: Ast, token: Token): Ast =
  let rhs = p.parsePrecedence(prec)
  return newAstBinary(kind, token, lhs, rhs)


func parsePrefix(p: var Parser, token: Token): Ast =
  case token.kind:
  of tkIdent:
    result = Ast(kind: astIdent, tok: token)
  of tkInt:
    result = newAst(astInt, token)
  of tkDash:
    result = p.parseUnary(astNeg, token)
  else:
    raise newException(ParseError, fmt"`{token.kind}` is not a prefix operation.")


func parseInfix(p: var Parser, previous: Ast, token: Token): Ast =
  let prec = token.kind.precedence()
  case token.kind:
  of tkPlus:
    result = p.parseBinary(astAdd, prec, previous, token)
  of tkDash:
    result = p.parseBinary(astSub, prec, previous, token)
  else:
    raise newException(ParseError, fmt"`{token.kind}` is not an infix operation.")


func parsePrecedence(p: var Parser, prec: TokenPrecedence): Ast =
  let token = p.tokenizer.next().orRaise(ParseError, "Unterminated statement.")
  result = p.parsePrefix(token)

  while prec <= p.tokenizer.peek().orReturn(result).kind.precedence():
    let token = p.tokenizer.next().unsafeGet()
    result = p.parseInfix(result, token)


func parseExpression(p: var Parser, banAssignment: bool = true): Ast =
  result = p.parsePrecedence(tpAssignment)
  if banAssignment and (not result.isNil) and result.kind == astAssignment:
    raise newException(ParseError, "Cannot assign in expression context.")


func parseLetStatement(p: var Parser): Ast =
  let letToken = p.expect(tkLet, "Expected `let` keyword to begin let statement.")

  let ident = p.parseIdent("Expected an identifier after `let` keyword.")

  discard p.expect(tkEqual, "Expected `=` after identifier of let statement.")
  let expr = p.parseExpression()

  return newAstBinary(astLet, letToken, ident, expr)


func parseStatementRequireSemicolon(p: var Parser): Ast = 
  case p.tokenizer.peek().orReturn(nil).kind:
  of tkLet:
    result = p.parseLetStatement()
  else:
    result = p.parseExpression(banAssignment=false)

  discard p.expect(tkSemicolon, "Expected `;` to terminate statement.")


func parseStatement(p: var Parser): Ast =
  case p.tokenizer.peek().orReturn(nil).kind:
  else:
    p.parseStatementRequireSemicolon()


func parseDeclaration(p: var Parser): Ast =
  case p.tokenizer.peek().orReturn(nil).kind:
  else:
    p.parseStatement()


func parse*(source: string): seq[Ast] =
  var p = Parser(tokenizer: newTokenizer(source))

  while true:
    let node = p.parseDeclaration()
    if node.isNil:
      break
    
    result.add(node)

