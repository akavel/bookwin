{.experimental: "codeReordering".}
import webext
import dom
import jsffi
import asyncjs
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
#       (done: create new bookmark folder (if input box nonempty))
#       - clear the input box
#       [LATER] - refresh the dropdown & select the new bookmark folder in dropdown
#       (done: add bookmarks in the selected folder for all selected tabs)
#       (done: close all selected tabs)
# TODO[LATER]: make table rows fixed-width
# TODO[LATER]: highlight the row corresponding to currently active tab
# TODO[LATER]: scroll down, centering on the row corresponding to currently active tab
# (done: make the dropdown+inputbox+button always visible at fixed position in the dialog (but not covering the tabs list))
# TODO[LATER]: prettier vertical alignment of favicons and tab titles
# TODO[LATER]: when hovering over tab title, show full tab title immediately in a tooltip
# (done: add [Close] button (closing checked tabs))
# TODO[LATER]: add [Rename] button (renaming bookmark folder)
# (done: double-click to browse to specified tab)
# TODO[LATER] separate button [New] to create bookmarks subfolder, separate to [Archive]

var browser {.importc, nodecl.}: JsObject

# echo "in plug-in!"

setRenderer createDom

type tabRow = tuple
  id: int
  url: string
  title: string
  checked: bool
  faviconUrl: string  # empty if none

var tabRows: seq[tabRow] = @[
  (id: -1, url: "", title: "hello 1", checked: false, faviconUrl: ""),
  (id: -2, url: "", title: "rather longer entry", checked: true, faviconUrl: ""),
  (id: -3, url: "", title: "super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super super longer entry", checked: true, faviconUrl: ""),
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

var
  folderName: string
  parentFolderID: string

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
          td(onclick=toggle(row), ondblclick=activate(row)):
            tdiv(style=titleStyle, title=row.title):
              text row.title
          td:
            form:
              input(`type`="checkbox", checked=toChecked(row.checked), onchange=toggle(row))
    form(style=formStyle):
      select(onchange=setParentFolder):
        for f in bookmarkFolders:
          option(value=f.id):
            text f.title
      br()
      input(`type`="text", style=style((width, kstring"500px")), value=folderName, onblur=setFolderName)
      br()
      # FIXME: button(onclick=archivize):
      a(href="#", onclick=archivize):
        text "Archive"
      a(href="#", onclick=closeTabs, style=style((marginLeft, kstring"10em"))):
        text "Close"

# proc DBG[T](prefix: string, v: T): T =
#   echo prefix & $v
#   return v

proc toggle(row: var tabRow): proc() =
  return proc() =
    row.checked = not row.checked

proc activate(row: tabRow): proc() =
  return proc() =
    echo "ACT: " & row.title
    updateTab(row.id.toJs, js{active: true.toJs})
    # TODO: also, make it so that text will not become selected

proc setParentFolder(ev: Event, n: VNode) =
  parentFolderID = $n.value
  echo "SEL: " & $n.value

proc setFolderName(ev: Event, n: VNode) =
  folderName = $n.value
  echo "V: " & $n.value

proc archivize(ev: Event, n: VNode) =
  soon:
    echo "Archivize!"
    var folderID = parentFolderID
    if folderName != "":
      let b = await createBookmark(js{
        parentId: parentFolderID.toJs,
        title: folderName.toJs,
      })
      folderID = $b.id.to(cstring)
      echo "NEW: " & $b.id.to(cstring) & " " & $b.title.to(cstring)

    echo "IN: start"
    var rest: seq[tabRow]
    for t in tabRows:
      # echo "IN? " & t.title
      if not t.checked:
        rest.add t
        continue
      # TODO: handle exceptions
      echo "IN: create..." & t.title & " (id=" & $t.id & ")"
      discard await createBookmark(js{
        parentId: folderID.toJs,
        title: t.title.toJs,
        url: t.url.toJs,
      })
      echo "IN: close tab...: " & $t.id
      discard await removeTabs(t.id.toJs)
    echo "IN: ending..."
    tabRows = rest
    redraw()
    echo "IN: end"

  # FIXME: folderName = "" -- doesn't seem to work; use getVNodeById(id) ?
  # ev.stopPropagation()


soon:
  # TODO: how to check if browser.tabs is empty, to allow
  # rendering/testing outside Firefox addon?
  let tabs = await queryTabs(js{
    currentWindow: true.toJs,
  })
  tabRows.setLen 0
  for x in tabs:
    tabRows.add (
      id: x.id.to(int),
      url: $x.url.to(cstring),
      title: $x.title.to(cstring),
      checked: false,
      faviconUrl: if isnil x.favIconUrl: "" else: $x.favIconUrl.to(cstring),
    )
  redraw()

proc closeTabs() =
  soon:
    var rest: seq[tabRow]
    for t in tabRows:
      if not t.checked:
        rest.add t
        continue
      discard await removeTabs(t.id.toJs)
    tabRows = rest
    redraw()


# Collect full bookmark folders tree
soon:
  let items = await getBookmarksTree()
  bookmarkFolders.setLen 0
  extractFolders(items[0])
  redraw()

proc extractFolders(node: JsObject, indent: Natural = 0) =
  if node.url != nil: return # we're only interested in folders
  # if node.unmodifiable != nil: return  # TODO: add or not?
  bookmarkFolders.add (
    title: ". ".repeat(indent) & $node.title.to(cstring),
    id: $node.id.to(cstring))
  for c in node.children:
    extractFolders(c, indent+1)

template soon(body: untyped) =
  proc f() {.async, gensym.} =
    body
  # TODO: somehow add `.catch(...)` handler, forwarding the exception to Nim
  discard f()

