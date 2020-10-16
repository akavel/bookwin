{.experimental: "codeReordering".}
import jsffi
import options
import strutils
import karax/vstyles
include karax/prelude

# (done: render a list of all tabs in current window, with checkmarks)
# (done: show full tab title on hover)
# (done: clicking tab title should toggle the checkmark)
# (done: render a dropdown with tree of bookmark folder names)
# (done: render an input box for (optional) new folder name)
# (done: render an [Archive] button)
# TODO: after pressing [Archive]:
#       - create new bookmark folder (if input box nonempty)
#       - clear the input box
#       [LATER] - refresh the dopdown & select the new bookmark folder in dropdown
#       - add bookmarks in the selected folder for all selected tabs
#       - close all selected tabs
# TODO[LATER]: make table rows fixed-width
# TODO[LATER]: highlight the row corresponding to currently active tab
# TODO[LATER]: scroll down to center on the row corresponding to currently active tab
# (done: make the dropdown+inputbox+button always visible at fixed position in the dialog (but not covering the tabs list))
# TODO[LATER]: prettier vertical alignment of favicons and tab titles
# TODO[LATER]: when hovering over tab title, show full tab title immediately in a tooltip

var browser {.importc, nodecl.}: JsObject

# echo "in plug-in!"

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

type bookmarkFolder = tuple
  title: string
  id: string
var bookmarkFolders: seq[bookmarkFolder]
# var bookmarkFolders: seq[bookmarkFolder] = @[
#   (title: "fake-root", id: "-1"),
#   (title: ". fake-folder", id: "-2"),
#   (title: ". . fake-subfolder", id: "-3"),
# ]

proc createDom(): VNode =
  let
    formH = "5em"  # FIXME: make it work without fixed height...
    tableStyle = style(
      # (width, kstring"550px"),
      (margin, kstring"0 10px 0 0"),  # without this, Firefox adds ugly horizontal scrollbar in the addon window
      (paddingBottom, kstring(formH)),
    )
    titleStyle = style(
      (overflow, kstring"hidden"),
      (textOverflow, kstring"ellipsis"),
      (whiteSpace, kstring"nowrap"),
      (width, kstring"500px"),
      # (backgroundColor, kstring"#ffff88"),
      # (height, kstring"100%"),
      # (position, kstring"absolute"),
    )
    formStyle = style(
      (position, kstring"fixed"),
      (bottom, kstring"0"),
      (height, kstring(formH)),
      (width, kstring"100%"),
      (background, kstring"#ffffff"),
    )
  buildHtml(tdiv):
    # table(style=tableStyle, border="1", cellpadding="0", cellspacing="0"):
    table(style=tableStyle):
      for i, row in tabRows.mpairs:
        tr:
          td:
            if row.faviconUrl != "":
              img(src=row.faviconUrl, width="16", height="16")
          td(onclick=toggle(row)):
            tdiv(style=titleStyle, title=row.title):
              text row.title
          td:
            form:
              input(`type`="checkbox", checked=toChecked(row.checked), onchange=toggle(row))
    form(style=formStyle):
      select:
        for f in bookmarkFolders:
          option(value=f.id):
            text f.title
      br()
      input(`type`="text", style=style((width, kstring"500px")))
      br()
      button:
        text "Archive"

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
)
# TODO: somehow add `.catch(...)` handler above

# Collect full bookmark folders tree
browser.bookmarks.getTree().then(proc(items: JsObject) =
  # var list: seq[string]
  # echo "getTree:"
  proc extractFolders(node: JsObject, indent: Natural) =
    if node.url != nil: return  # we're only interested in folders
    # list.add "  ".repeat(indent) & $node.title.to(cstring)
    bookmarkFolders.add (
      title: ". ".repeat(indent) & $node.title.to(cstring),
      id: $node.id.to(cstring))
    # echo ">" & list[^1]
    for c in node.children:
      extractFolders(c, indent+1)
  extractFolders(items[0], 0)
  redraw()
)
# TODO: somehow add `.catch(...)` handler above
