{.experimental: "codeReordering".}
import webext
import dom
import asyncjs
import options
import strutils
import karax/vstyles
include karax/prelude
import karax_css

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
# (done: highlight the row corresponding to currently active tab)
# (done: scroll down, centering on the row corresponding to currently active tab)
# (done: make the dropdown+inputbox+button always visible at fixed position in the dialog (but not covering the tabs list))
# TODO[LATER]: prettier vertical alignment of favicons and tab titles
# TODO[LATER]: when hovering over tab title, show full tab title immediately in a tooltip
# (done: add [Close] button (closing checked tabs))
# TODO[LATER]: add [Rename] button (renaming bookmark folder)
# (done: double-click to browse to specified tab)
# TODO[LATER] separate button [New] to create bookmarks subfolder, separate to [Archive]

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
  (id: -3, url: "", title: "super ".repeat(50) & "longer entry", checked: true, faviconUrl: ""),
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
  activeTabID: int

proc createDom(): VNode =
  let
    formH = kstring"5em"  # FIXME: make it work without fixed height...
    tableStyle = css{
      # width: "550px",
      margin: "0 10px 0 0",  # without this, Firefox adds ugly horizontal scrollbar in the addon window
      padding_bottom: formH,
    }
    titleStyleNormal = css{
      overflow: "hidden",
      text_overflow: "ellipsis",
      white_space: "nowrap",
      width: "500px",
      # backgroundColor: "#ffff88",
      # height: "100%",
      # position: "absolute",
    }
    titleStyleBold = titleStyleNormal.merge css{
      font_weight: "bold",
      background: "#ffd",
    }
    formStyle = css{
      position: "fixed",
      bottom: "0",
      height: formH,
      width: "100%",
      background: "#ffffff",
    }
  soon:
    getElementById($activeTabID).scrollIntoView(`block`="center")
  buildHtml(tdiv):
    # table(style=tableStyle, border="1", cellpadding="0", cellspacing="0"):
    table(style=tableStyle):
      for i, row in tabRows.mpairs:
        let titleStyle =
          if row.id == activeTabID: titleStyleBold
          else: titleStyleNormal
        tr(id=kstring($row.id)):
          td:
            if row.faviconUrl != "":
              img(src=row.faviconUrl, width="16", height="16")
          td(onclick=toggle(row.id), ondblclick=activate(row)):
            tdiv(style=titleStyle, title=row.title):
              text row.title
          td:
            form:
              input(`type`="checkbox", checked=toChecked(row.checked), onchange=toggle(row.id))
    form(style=formStyle):
      select(onchange=setParentFolder):
        for f in bookmarkFolders:
          option(value=f.id):
            text f.title
      br()
      input(`type`="text", style=css{width: "500px"}, value=folderName, onblur=setFolderName)
      br()
      # FIXME: button(onclick=archivize):
      a(href="#", onclick=archivize):
        text "Archive"
      a(href="#", onclick=closeTabs, style=css{margin_left: "10em"}):
        text "Close"

# proc DBG[T](prefix: string, v: T): T =
#   echo prefix & $v
#   return v

proc toggle(rowID: int): proc() =
  return proc() =
    var row = addr findRow(rowID)
    row.checked = not row.checked

proc findRow(id: int): var tabRow =
  for row in tabRows.mitems:
    if row.id == id:
      return row
  return new(tabRow)[]

proc activate(row: tabRow): proc() =
  return proc() =
    echo "ACT: " & row.title
    discard browser.tabs.update(row.id, TabUpdateOpts(
      active: true))
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
      let b = await browser.bookmarks.create(BookmarkCreateDetails(
        parentId: parentFolderID,
        title: folderName))
      folderID = $b.id
      echo "NEW: " & $b.id & " " & $b.title

    echo "IN: start"
    var rest: seq[tabRow]
    for t in tabRows:
      # echo "IN? " & t.title
      if not t.checked:
        rest.add t
        continue
      # TODO: handle exceptions
      echo "IN: create..." & t.title & " (id=" & $t.id & ")"
      discard await browser.bookmarks.create(BookmarkCreateDetails(
        parentId: folderID,
        title: t.title,
        url: t.url))
      echo "IN: close tab...: " & $t.id
      await browser.tabs.remove(t.id)
    echo "IN: ending..."
    tabRows = rest
    redraw()
    echo "IN: end"

  # FIXME: folderName = "" -- doesn't seem to work; use getVNodeById(id) ?
  # ev.stopPropagation()


soon:
  # TODO: how to check if browser.tabs is empty, to allow
  # rendering/testing outside Firefox addon?
  let tabs = await browser.tabs.query(TabsQueryOpts(
    currentWindow: true))
  tabRows.setLen 0
  for x in tabs:
    tabRows.add (
      id: x.id,
      url: $x.url,
      title: $x.title,
      checked: false,
      faviconUrl: if isnil x.favIconUrl: "" else: $x.favIconUrl,
    )
    if x.highlighted:
      echo "HIGH ", x.title
      activeTabID = x.id
  redraw()

proc closeTabs() =
  soon:
    var rest: seq[tabRow]
    for t in tabRows:
      if not t.checked:
        rest.add t
        continue
      await browser.tabs.remove(t.id)
    tabRows = rest
    redraw()


# Collect full bookmark folders tree
soon:
  let items = await browser.bookmarks.getTree()
  bookmarkFolders.setLen 0
  extractFolders(items[0])
  redraw()

proc extractFolders(node: BookmarkTreeNode, indent: Natural = 0) =
  if node.url != nil: return # we're only interested in folders
  # if node.unmodifiable != nil: return  # TODO: add or not?
  bookmarkFolders.add (
    title: ". ".repeat(indent) & $node.title,
    id: $node.id)
  for c in node.children:
    extractFolders(c, indent+1)

proc scrollIntoView(n: Node, `block`: cstring = "start") {.
  importcpp: "#.scrollIntoView({block: #})".}

