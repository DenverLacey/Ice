from Interpreter import Size

type
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

