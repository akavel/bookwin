{.experimental: "codeReordering".}
import jsffi
import options
import karax/vstyles
include karax/prelude

# (done: render a list of all tabs in current window, with checkmarks)
# (done: show full tab title on hover)
# TODO[LATER]: clicking tab title should toggle the checkmark
# TODO: render a dropdown with tree of bookmark folder names
# TODO: render an input box for (optional) new folder name
# TODO: render an [Archive] button
# TODO: after pressing [Archive]:
#       - create new bookmark folder (if input box nonempty)
#       - clear the input box
#       [LATER] - refresh the dopdown & select the new bookmark folder in dropdown
#       - add bookmarks in the selected folder for all selected tabs
#       - close all selected tabs
# TODO[LATER]: make table rows fixed-width
# TODO[LATER]: highlight the row corresponding to currently active tab
# TODO[LATER]: scroll down to center on the row corresponding to currently active tab
# TODO[LATER]: make the dropdown+inputbox+button always visible at fixed position in the dialog (but not covering the tabs list)
# TODO[LATER]: prettier vertical alignment of favicons and tab titles
# TODO[LATER]: when hovering over tab title, show full tab title immediately in a tooltip

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
    tableStyle = style(
      # (width, kstring"550px"),
      (margin, kstring"0 10px 0 0"),  # without this, Firefox adds ugly horizontal scrollbar in the addon window
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
  buildHtml(tdiv):
    # table(style=tableStyle, border="1", cellpadding="0", cellspacing="0"):
    table(style=tableStyle):
      for i, row in tabRows.mpairs:
        tr:
          td:
            if row.faviconUrl != "":
              img(src=row.faviconUrl, width="16", height="16")
          td:
            tdiv(style=titleStyle, title=row.title):
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
