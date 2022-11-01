# This is just an example to get you started. A typical binary package
# uses this sourceFile as the main entry point of the application.

import std/[parseopt, options]


template log(args: varargs[untyped]): untyped =
  when not defined(release):
    echo args


proc getSourceFileName(): Option[string] =
  var args = initOptParser("")
  while true:
    args.next()
    case args.kind
    of cmdArgument:
      return some(args.key)
    else:
      break


proc main() =
  log("[CMD] Getting source file from command line")
  let optSourceFileName = getSourceFileName()
  if optSourceFileName.isNone:
    echo("[ERR] Please provide a source file to compile.")
    return

  let sourceFileName = optSourceFileName.get()
  log("[INFO] Source file provided: \"", sourceFileName, '"')

  log("[CMD] Reading `", sourceFileName, "`")
  var sourceFile: File
  if not open(sourceFile, sourceFileName):
    echo("[ERR] Could not open `", sourceFileName, "`.")
    return
  defer: close(sourceFile)
  
  let source = sourceFile.readAll()
  log("[INFO] Source read:\n", source, '\n')


when isMainModule:
  main()
