import std/[options, unicode, strutils, strformat]
import sugar

import ../Utils


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


func toChar(rune: Rune): char =
  char(rune)


func firstWhereNot(r: RuneIterator, predicate: (Rune) -> bool): int =
  result = r.i
  while result < r.s.len:
    var rune: Rune
    let previous = result
    fastRuneAt(r.s, result, rune)
    if not predicate(rune):
      result = previous
      break


func takeWhile(r: var RuneIterator, predicate: (Rune) -> bool): string =
  let startIndex = r.i
  let endIndex = r.firstWhereNot(predicate)
  let slice = r.s[startIndex..<endIndex]
  r.i = endIndex
  return slice


func peekRune(t: Tokenizer, k: int = 0): Rune {.inline.} =
  if t.source.i < t.source.s.len:
    var r: Rune
    fastRuneAt(t.source.s, t.source.i, r, doInc=false)
    result = r


func nextRune(t: var Tokenizer): Option[Rune] {.inline.} =
  if t.source.i < t.source.s.len:
    var r: Rune
    fastRuneAt(t.source.s, t.source.i, r)
    result = some(r)


func skipWhitespace(t: var Tokenizer) {.inline.} =
  while t.peekRune().isWhitespace():
    discard t.nextRune()


func tokenizeNumber(t: var Tokenizer): Option[Token] =
  let 
    slice = t.source.takeWhile(isDigit <. toChar)
    num = slice.parseInt()

  return some(Token(kind: tkInt, intVal: num))


func tokenizeIdentOrKeyword(t: var Tokenizer): Token =
  let slice = t.source.takeWhile(isAlphaNumeric <. toChar)

  let token = 
    case slice
    of "let":
      Token(kind: tkLet)
    else:
      Token(kind: tkIdent, ident: slice)

  return token


func tokenizeOperator(t: var Tokenizer): Token =
  let r = t.nextRune().get()
  case r
  of Rune(';'):
    result = Token(kind: tkSemicolon)
  of Rune('='):
    result = Token(kind: tkEqual)
  of Rune('+'):
    result = Token(kind: tkPlus)
  of Rune('-'):
    result = Token(kind: tkDash)
  else:
    raise newException(Exception, fmt"`{r}` is not a valid operator.")


func nextNoPeeking(t: var Tokenizer): Option[Token] =
  t.skipWhitespace()

  let r = t.peekRune()
  case r
  of Rune('\0'): 
    return
  elif r.toChar().isDigit():
    result = t.tokenizeNumber()
  elif r.isAlpha():
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
  if t.peekedTokens.len != 0:
    result = some(t.peekedTokens[0])
    t.peekedTokens.delete(0)
  else:
    result = t.nextNoPeeking()

