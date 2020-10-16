{.experimental: "codeReordering".}
import jsffi
import options
import karax/vstyles
include karax/prelude

# TODO: render a list of all tabs in current window, with checkmarks
# TODO: show full tab title on hover
# TODO: render a dropdown with tree of bookmark folder names
# TODO: render an input box for (optional) new folder name
# TODO: render an [Archive] button
# TODO: after pressing [Archive]:
#       - create new bookmark folder (if input box nonempty)
#       - clear the input box
#       [LATER] - refresh the dopdown & select the new bookmark folder in dropdown
#       - add bookmarks in the selected folder for all selected tabs
#       - close all selected tabs

var browser {.importc, nodecl.}: JsObject

setRenderer createDom

type tabRow = tuple
  title: string
  checked: bool
  faviconUrl: string  # empty if none

var tabRows: seq[tabRow] = @[
  (title: "hello 1", checked: false, faviconUrl: ""),
  (title: "rather longer entry", checked: true, faviconUrl: ""),
  (title: "super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super longer entry", checked: true, faviconUrl: ""),
]


proc createDom(): VNode =
  let
    titleStyle = style(
      (overflow, kstring"hidden"),
      (textOverflow, kstring"ellipsis"),
      (whiteSpace, kstring"nowrap"),
      (width, kstring"500px"),
    )
  buildHtml(tdiv):
    table:
      for i, row in tabRows.mpairs:
        tr:
          td:
            if row.faviconUrl != "":
              img(src=row.faviconUrl, width="16", height="16")
          td:
            tdiv(style=titleStyle):
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
