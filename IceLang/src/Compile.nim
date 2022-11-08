import std/[options, enumerate]

import Ast
import Interpreter
import Utils
import Scope
import Types
from Tokenize import TokenKind

type
  Compiler = object
    interp: ptr Interpreter
    stackTop: Natural
    function: ptr Function


template trackStack(c: var Compiler, size: Size) =
  let oldTop = c.stackTop
  defer: c.stackTop = oldTop + Natural(size)


func emit(c: var Compiler, bytecode: Bytecode) =
  c.function.code.add(bytecode)


func emitInt(c: var Compiler, value: int) =
  if value == 0:
    c.emit(bcPush0)
  elif value == 1:
    c.emit(bcPush1)
  else:
    doAssert(false, "TODO: Implement arbitrary integer literals.")
  
  c.stackTop += INT_TYPE.size()


func compile(c: var Compiler, node: Ast)


func compileUnary(c: var Compiler, inst: Bytecode, unaryNode: Ast) =
  c.trackStack(unaryNode.typ.orRaise(Exception, "[ERR] unary node expected to have a type.").size())

  c.compile(unaryNode.sub)
  c.emit(inst)


func compileBinary(c: var Compiler, inst: Bytecode, binaryNode: Ast) =
  c.trackStack(binaryNode.typ.orRaise(Exception, "[ERR] binary node expected to have a type.").size())

  c.compile(binaryNode.lhs)
  c.compile(binaryNode.rhs)
  c.emit(inst)


func compile(c: var Compiler, node: Ast) = 
  case node.kind:
  # Nullary
  of astIdent:
    assert(false, "TODO: Implement compilation of ident nodes.")
  of astInt:
    c.emitInt(node.tok.intVal)
  
  # Unary
  of astNeg:
    c.compileUnary(bcNeg, node)

  # Binary
  of astAssignment:
    assert(false, "TODO: Implement compilation of assign nodes.")
  of astAdd:
    c.compileBinary(bcAdd, node)
  of astSub:
    c.compileBinary(bcSub, node)
  of astLet:
    var ident = node.lhs.tok.ident
    let binding = node.scope.findBindingPtr(ident).orRaise(Exception, "[ERR] ident of let node could not be found in scope.")
    binding.stackPosition = c.stackTop

    c.compile(node.rhs)


proc compile*(interp: var Interpreter, nodes: seq[Ast]) =
  let globalFunction = interp.getFunction(0).orRaise(Exception, "[ERR] Failed to retrieve global function from registry.")
  var c = Compiler(interp: addr interp, stackTop: 0, function: globalFunction)

  for node in nodes:
    c.compile(node)

  log("[INFO] Bytecode:")
  for i, code in enumerate(c.function.code):
    echo(i, ": ", code, " (", code.byte, ')')

