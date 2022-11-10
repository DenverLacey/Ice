type
  Pid* = uint64
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
