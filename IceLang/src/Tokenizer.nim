import std/[options, unicode, strutils, strformat, parseutils]
import sugar

import Utils


type
  RuneIterator = object
    i: int
    s: string

  TokenKind* = enum
    tkSemicolon,
    tkIdent,
    tkInt,
    tkEqual,
    tkPlus,
    tkDash,
    tkLet
  
  Token* = object
    case kind*: TokenKind
    of tkIdent:
      ident: string
    of tkInt:
      intVal*: int
    else:
      discard

  TokenPrecedence* = enum
    tpNone,
    tpAssignment,
    tpTerm,
    tpFactor,
    tpUnary

  Tokenizer* = object
    source: RuneIterator
    peekedTokens: seq[Token]
    previousWasNewline: bool


func precedence*(kind: TokenKind): TokenPrecedence =
  case kind:
  of tkSemicolon: tpNone
  of tkIdent:     tpNone
  of tkInt:       tpNone
  of tkEqual:     tpAssignment
  of tkPlus:      tpTerm
  of tkDash:      tpTerm
  of tkLet:       tpNone


func newTokenizer*(source: string): Tokenizer =
  Tokenizer(source: RuneIterator(i: 0, s: source), peekedTokens: @[], previousWasNewline: true)


func findLastWhere(r: RuneIterator, predicate: (Rune) -> bool): int =
  result = r.i
  while result < len(r.s):
    var rune: Rune
    let previous = result
    fastRuneAt(r.s, result, rune)
    if not predicate(rune):
      result = previous
      break


func peekChar(t: Tokenizer, k: int = 0): Rune {.inline.} =
  if t.source.i < len(t.source.s):
    var r: Rune
    fastRuneAt(t.source.s, t.source.i, r, doInc=false)
    result = r


func nextChar(t: var Tokenizer): Option[Rune] {.inline.} =
  if t.source.i < len(t.source.s):
    var r: Rune
    fastRuneAt(t.source.s, t.source.i, r)
    result = some(r)


func skipWhitespace(t: var Tokenizer) {.inline.} =
  while isWhitespace(t.peekChar()):
    discard t.nextChar()


func tokenizeNumber(t: var Tokenizer): Option[Token] =
  let startIndex = t.source.i
  let endIndex = t.source.findLastWhere((c) => isDigit(char(c)))
  let slice = t.source.s[startIndex..<endIndex]
  t.source.i = endIndex

  var num: int
  discard parseInt(slice, num)

  return some(Token(kind: tkInt, intVal: num))


func tokenizeIdentOrKeyword(t: var Tokenizer): Option[Token] =
  let startIndex = t.source.i
  let endIndex = t.source.findLastWhere((c) => isAlphaNumeric(char(c)))
  let slice = t.source.s[startIndex..<endIndex]
  t.source.i = endIndex

  let token = 
    case slice
    of "let":
      Token(kind: tkLet)
    else:
      Token(kind: tkIdent, ident: slice)

  return some(token)


func tokenizeOperator(t: var Tokenizer): Option[Token] =
  let c = t.nextChar().get
  case c
  of Rune(';'):
    result = some(Token(kind: tkSemicolon))
  of Rune('='):
    result = some(Token(kind: tkEqual))
  of Rune('+'):
    result = some(Token(kind: tkPlus))
  of Rune('-'):
    result = some(Token(kind: tkDash))
  else:
    raise newException(Exception, fmt"`{c}` is not a valid operator.")


func nextNoPeeking(t: var Tokenizer): Option[Token] =
  t.skipWhitespace()

  let c = t.peekChar()
  case c
  of Rune('\0'): 
    return
  elif isDigit(char(c)):
    result = t.tokenizeNumber()
  elif isAlpha(c):
    result = t.tokenizeIdentOrKeyword()
  else:
    result = t.tokenizeOperator()


func peek*(t: var Tokenizer, n: Natural = 0): Option[Token] =
  while t.peekedTokens.len <= n:
    let token = t.nextNoPeeking().orReturn(none(Token))
    t.peekedTokens.add(token)

  let token = t.peekedTokens[n]
  return some(token)


func next*(t: var Tokenizer): Option[Token] =
  if len(t.peekedTokens) != 0:
    result = some(t.peekedTokens[0])
    t.peekedTokens.delete(0)
  else:
    result = t.nextNoPeeking()
