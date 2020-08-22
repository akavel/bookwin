{.experimental: "codeReordering".}
import jsffi
import options
include karax/prelude

var browser {.importc, nodecl.}: JsObject

setRenderer createDom

type tabRow = tuple
  title: string
  checked: bool
  faviconUrl: string  # empty if none

var tabRows: seq[tabRow] = @[
  (title: "hello 1", checked: false, faviconUrl: ""),
  (title: "rather longer entry", checked: true, faviconUrl: ""),
]

proc createDom(): VNode =
  buildHtml(tdiv):
    table:
      for i, row in tabRows.mpairs:
        tr:
          td:
            if row.faviconUrl != "":
              img(src=row.faviconUrl, width="16", height="16")
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
  tabRows.setLen 0
  for x in tabs:
    tabRows.add (
      title: $x.title.to(cstring),
      checked: false,
      faviconUrl: if isnil x.favIconUrl: "" else: $x.favIconUrl.to(cstring),
    )
  redraw()
).catch(proc() =
  echo "MCDBG: error..."
)
