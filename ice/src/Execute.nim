

type
  Exe* = object


proc run*(exe: Exe) =
  discard


func parseExecutable*(exe: string): Exe =
  doAssert(exe[0..<4] == "BERG", "This is not a berg file.")

