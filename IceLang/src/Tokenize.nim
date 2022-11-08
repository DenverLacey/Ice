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
      ident*: string
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


func firstWhereNot(r: RuneIterator, predicate: (Rune) -> bool): int =
  result = r.i
  while result < len(r.s):
    var rune: Rune
    let previous = result
    fastRuneAt(r.s, result, rune)
    if not predicate(rune):
      result = previous
      break


func takeWhile(r: var RuneIterator, predicate: (Rune) -> bool): string =
  let startIndex = r.i
  let endIndex = r.firstWhereNot((c) => isDigit(char(c)))
  let slice = r.s[startIndex..<endIndex]
  r.i = endIndex
  return slice


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
  let slice = t.source.takeWhile((c) => isDigit(char(c)))

  var num: int
  discard parseInt(slice, num)

  return some(Token(kind: tkInt, intVal: num))


func tokenizeIdentOrKeyword(t: var Tokenizer): Token =
  let slice = t.source.takeWhile((c) => isAlphaNumeric(char(c)))

  let token = 
    case slice
    of "let":
      Token(kind: tkLet)
    else:
      Token(kind: tkIdent, ident: slice)

  return token


func tokenizeOperator(t: var Tokenizer): Token =
  let c = t.nextChar().get
  case c
  of Rune(';'):
    result = Token(kind: tkSemicolon)
  of Rune('='):
    result = Token(kind: tkEqual)
  of Rune('+'):
    result = Token(kind: tkPlus)
  of Rune('-'):
    result = Token(kind: tkDash)
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
    result = some(t.tokenizeIdentOrKeyword())
  else:
    result = some(t.tokenizeOperator())


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

