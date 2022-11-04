# This is just an example to get you started. A typical binary package
# uses this sourceFile as the main entry point of the application.

import std/[parseopt, options, strutils]

import Utils
import Interpreter
import Parser
import Ast
import Typecheck
import Canon
import Codegen


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
  log("[INFO] Source read:\n", source, '\n', "-".repeat(25))

  log("[CMD] Parsing source...")
  let nodes = parse(source)

  var interp = newInterpreter()

  log("[CMD] Establishing Scopes...")
  establishScopes(interp, nodes)

  log("[CMD] Typechecking nodes...")
  typecheck(interp, nodes)

  log("[INFO] nodes:")
  for node in nodes:
    node.print()

  log("[CMD] Compiling node...")
  compile(interp, nodes)
  

when isMainModule:
  main()

