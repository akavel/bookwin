import macros
import karax/kbase

type css* = distinct void
macro `{}`*(cssTag: typedesc[css]; xs: varargs[untyped]): auto =
  # echo xs.treeRepr
  result = nnkBracket.newNimNode(xs)
  for x in xs.children:
    if x.kind != nnkExprColonExpr:
      error("Expression `" & $x.toStrLit & "` not allowed in `css{}` macro")
    let
      left = x[0]
      right = x[1]
    if right.kind == nnkStrLit:
      result.add quote do:
        (`left`, kstring(`right`))
    else:
      result.add quote do:
        (`left`, `right`)
  result = newCall("style", result)
