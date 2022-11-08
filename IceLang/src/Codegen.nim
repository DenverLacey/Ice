import std/[strformat, strutils, options, bitops]
import parsecfg

import Interpreter
import Utils


type
  Version = object
    major: uint16
    minor: uint16


const
  FN_BEGIN: uint16 = 0xF4B9
  FN_END: uint16   = 0xF4ED


func toBytes[T: SomeInteger](i: T): array[sizeof(T), byte] =
  when T is uint16:
    [
      uint8(bitand(i, 0xFF00) shr 8),
      uint8(bitand(i, 0x00FF) shr 0),
    ]
  elif T is uint64:
    [
      uint8(bitand(i, 0xFF00_0000_0000_0000'u64) shr 56),
      uint8(bitand(i, 0x00FF_0000_0000_0000'u64) shr 48),
      uint8(bitand(i, 0x0000_FF00_0000_0000'u64) shr 40),
      uint8(bitand(i, 0x000F_00FF_0000_0000'u64) shr 32),
      uint8(bitand(i, 0x0000_0000_FF00_0000'u64) shr 24),
      uint8(bitand(i, 0x0000_0000_00FF_0000'u64) shr 16),
      uint8(bitand(i, 0x0000_0000_0000_FF00'u64) shr 8),
      uint8(bitand(i, 0x0000_0000_0000_00FF'u64) shr 0),
    ]


func fromBytes[T: SomeInteger](bytes: openArray[byte]): T =
  when T is uint16:
    assert(bytes.len == 2)
    bitor(bytes[0].uint16 shl 8, bytes[1].uint16 shl 0)
  elif T is uint64:
    assert(bytes.len == 8)
    bitor(
      bytes[0].uint64 shl 56,
      bytes[1].uint64 shl 48,
      bytes[2].uint64 shl 40,
      bytes[3].uint64 shl 32,
      bytes[4].uint64 shl 24,
      bytes[5].uint64 shl 16,
      bytes[6].uint64 shl 8,
      bytes[7].uint64 shl 0,
    )


proc checkEncodeDecode[T: SomeInteger](bytes: openArray[byte], expected: T) =
  log("[INFO] Checking encode/decode functions for bytes `", bytes, '`')
  let actual = fromBytes[T](bytes)
  assert(actual == expected)


proc writeInteger[T: SomeInteger](f: var File, value: T) =
  let bytes = toBytes(value)

  when not defined(release):
    checkEncodeDecode(bytes, value)

  discard f.writeBytes(bytes, 0, bytes.len)


proc getCompilerVersion(): Option[Version] =
  let config = loadConfig("./IceLang.nimble")
  assert(config != nil, "Failed to load config file of ice compiler `./IceLang.nimble`")

  let 
    sectionValue = config.getSectionValue("", "version")
    segments = sectionValue.split('.', 3)
  assert(segments.len == 3, fmt"Invalid compiler version `{sectionValue}`. Expected <major>.<minor>.<patch> format.")
  
  let
    major = segments[0].parseInt.uint16
    minor = segments[1].parseInt.uint16
  
  return some(Version(major: major, minor: minor))


proc writeBergBegin(f: var File, version: Version) =
  f.write("BERG")
  f.writeInteger(version.major)
  f.writeInteger(version.minor)
  f.write('\n')


func arrayToPtrAndLen[T](arr: openArray[T]): tuple[items: ptr T, len: Natural] =
  let x = cast[ptr UncheckedArray[T]](arr)
  let itemsPtr = addr x[0]
  let itemsLen = arr.len
  return (items: itemsPtr, len: itemsLen.Natural)


proc writeArray[T](f: var File, arr: openArray[T]) =
  const lenScaleFactor = sizeof(T) div sizeof(byte)
  let (p, len) = arrayToPtrAndLen(arr)
  discard f.writeBuffer(p, len * lenScaleFactor)


proc writeFunction(f: var File, fn: Function) =
  f.writeInteger(FN_BEGIN)
  f.write(' ')
  f.writeInteger(fn.id.uint64)
  f.write(':')

  static: assert(sizeof(Bytecode) == sizeof(byte), "Bytecode expected to be 1 byte large.")
  f.writeArray(fn.code)
  f.write('\0')

  f.writeInteger(FN_END)


proc outputBergFile*(interp: var Interpreter, f: var File) =
  let version = getCompilerVersion().orRaise(Exception, "Failed to load compiler version.")
  f.writeBergBegin(version)

  for fn in interp.functions:
    f.writeFunction(fn)

