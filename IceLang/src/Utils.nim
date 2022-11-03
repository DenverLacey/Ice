import std/options


template orReturn*[T, U](a: Option[T], b: U): untyped =
  let opt = a
  if opt.isNone:
    return b
  opt.unsafeGet()


template orReturn*[T](a: Option[T]): untyped =
  let opt = a
  if opt.isNone:
    return
  opt.unsafeGet()


template orRaise*[T](a: Option[T], typ: typedesc, msg: string): untyped =
  let opt = a
  if opt.isNone:
    raise newException(typ, msg)
  opt.unsafeGet()


template log*(args: varargs[untyped, `$`]): untyped =
  when not defined(release):
    echo args


template dbg*(x: untyped): untyped =
  let xResult = x
  log("[DBG] ", xResult)
  xResult

