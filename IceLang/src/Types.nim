
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

