import std/[options, unicode, strutils]


type
  RuneIterator = object
    i: int
    s: string

  TokenKind* = enum
    tkInt,
    tkPlus,
    tkDash
  
  Token* = object
    case kind*: TokenKind
    of tkInt:
      intVal*: int
    else:
      discard

  Tokenizer = object
    source: RuneIterator
    peekedTokens: seq[Token]
    previousWasNewline: bool
  
  Parser = object
    tokenizer: Tokenizer


func newTokenizer(source: string): Tokenizer =
  Tokenizer(source: RuneIterator(i: 0, s: source), peekedTokens: @[], previousWasNewline: true)


func peekChar(t: Tokenizer, k: int = 0): Rune {.inline.} =
  if t.source.i < t.source.s.len:
    var r: Rune
    fastRuneAt(t.source.s, t.source.i, r, doInc=false)
    result = r


proc nextChar(t: var Tokenizer): Option[Rune] {.inline.} =
  if t.source.i < t.source.s.len:
    var r: Rune
    fastRuneAt(t.source.s, t.source.i, r)
    result = some(r)


proc skipWhitespace(t: var Tokenizer) {.inline.} =
  while isWhitespace(t.peekChar()):
    discard t.nextChar()


proc tokenizeNumber(t: var Tokenizer): Option[Token] =
  discard


proc tokenizeIdentOrKeyword(t: var Tokenizer): Option[Token] =
  discard


proc tokenizeOperator(t: var Tokenizer): Option[Token] =
  discard


proc nextNoPeeking(t: var Tokenizer): Option[Token] =
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


proc next(t: var Tokenizer): Option[Token] =
  if t.peekedTokens.len != 0:
    result = some(t.peekedTokens[0])
    t.peekedTokens.delete(0)
  else:
    result = t.nextNoPeeking()


proc parse*(source: string): seq[Token] =
  var p = Parser(tokenizer: newTokenizer(source))

  while true:
    let token = p.tokenizer.next()
    if token.isNone:
      break

    result.add(token.unsafeGet())

