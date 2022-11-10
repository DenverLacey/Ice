import std/[bitops, math, strformat, enumerate]


type
  PidDomain* {.size:sizeof(byte).} = enum
    pdFunc = 0

  PidValue* = range[0..2^(7*8)]

  Pid* = distinct uint64
  Size* = uint32
  Addr* = uint16

  Bytecode* {.size: sizeof(byte).} = enum
    bcNone    = 0,
    bcPush0   = 1,
    bcPush1   = 2,
    bcPushInt = 3
    bcNeg     = 4,
    bcAdd     = 5,
    bcSub     = 6

  Function* = object
    id*: Pid
    code*: seq[Bytecode]

  TypeKind* = enum
    typBool,
    typChar,
    typInt
  
  Type* = object
    case kind*: TypeKind:
    of
      typBool,
      typChar,
      typInt:
        discard


func newPid*(domain: PidDomain, value: PidValue): Pid =
  (domain.uint64 shl (sizeof(Pid) - 8)).bitor(value.uint64).Pid


func domain*(pid: Pid): PidDomain =
  (pid.uint64.bitand(0xFF00_0000_0000_0000'u64) shr 56).PidDomain


func value*(pid: Pid): PidValue =
  (pid.uint64.bitand(0x00FF_FFFF_FFFF_FFFF'u64)).PidValue


func `==`*(pid1, pid2: Pid): bool =
  pid1.uint64 == pid2.uint64


func `$`*(pid: Pid): string =
  let 
    domainChar =
      case pid.domain
      of pdFunc: 'F'
    
    value = pid.value
  
  fmt"{domainChar}.{value:X}"


const BOOL_TYPE*: Type = Type(kind: typBool)
const CHAR_TYPE*: Type = Type(kind: typChar)
const INT_TYPE*: Type = Type(kind: typInt)


func size*(typ: Type): Size =
  case typ.kind:
  of typBool:
    1
  of typChar:
    1 # Maybe should be 4 to support unicode
  of typInt:
    4


template read[T](): T =
  when T is SomeInteger:
    let byteArray = code[i..<i+sizeof(T)]
    var r: T = 0
    for k, byt in enumerate(byteArray):
      let sh = sizeof(T)*8 - k*8 - 8
      r = r.bitor(byt.T shl sh)
    i += sizeof(T)
    r
  else:
    let codeArray = cast[ptr UncheckedArray[Bytecode]](code)
    let tp = cast[ptr T](addr codeArray[i])
    i += sizeof(T)
    tp[]
  

proc printBytecode*(code: openArray[Bytecode]) =
  var i = 0
  while i < code.len:
    let i0 = i
    let op = read[Bytecode]
    case op
    of bcNone:
      echo fmt"{i0:04X}: None"
    of bcPush0:
      echo fmt"{i0:04X}: Push0"
    of bcPush1:
      echo fmt"{i0:04X}: Push1"
    of bcPushInt:
      let n = read[int]
      echo fmt"{i0:04X}: PushInt `{n}`"
    of bcNeg:
      echo fmt"{i0:04X}: Neg"
    of bcAdd:
      echo fmt"{i0:04X}: Add"
    of bcSub:
      echo fmt"{i0:04X}: Sub"
    else: 
      # @SAFETY:
      # Turning this warning off because although we are handling all the cases
      # we're doing some unsafe stuff so we're not guaranteed to get a valid
      # bytecode value.
      #
      {.warning[UnreachableElse]:off.}
      raise newException(Exception, fmt"Invalid bytecode operation `{op}`")

