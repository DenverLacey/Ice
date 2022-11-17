# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import std/[parseopt, options]
import Execute

proc getBergFileName(): Option[string] =
  var args = initOptParser("")
  while true:
    args.next()
    case args.kind
    of cmdArgument:
      return some(args.key)
    else:
      break;


proc main() =
  let optBergFileName = getBergFileName()
  if optBergFileName.isNone:
    echo("[ERR] Please provide a berg file to execute.")
    return

  let bergFileName = optBergFileName.unsafeGet()

  var bergFile: File
  if not open(bergFile, bergFileName):
    echo("[ERR] Could not open `", bergFileName, "`.")
    return
  defer: close(bergFile)

  let exeString = bergFile.readAll()
  let exe = parseExecutable(exe_string)
  run(exe)


when isMainModule:
  main()

