{.experimental: "codeReordering".}
import jsffi
include karax/prelude

var browser {.importc, nodecl.}: JsObject

setRenderer createDom

type tabRow = tuple
  # TODO: favicon
  title: string
  checked: bool

var tabRows: seq[tabRow] = @[
  (title: "hello 1", checked: false),
  (title: "rather longer entry", checked: true),
]

proc createDom(): VNode =
  buildHtml(tdiv):
    table:
      for i, row in tabRows.mpairs:
        tr:
          td:
            text row.title
          td:
            form:
              input(`type`="checkbox", checked=toChecked(row.checked), onchange=toggle(row))

proc toggle(row: var tabRow): proc() =
  return proc() =
    row.checked = not row.checked

# TODO: how to check if browser.tabs is empty, to allow
# rendering/testing outside Firefox addon?
browser.tabs.query(js{
  currentWindow: true.toJs,
}).then(proc(tabs: JsObject) =
  echo "MCDBG: tabs!2"
  for i, x in tabs:
    # echo $i
    echo $x.title.to(cstring)
).catch(proc() =
  echo "MCDBG: error..."
)
