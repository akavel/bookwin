{.experimental: "codeReordering".}
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
          td(onclick=toggle(row)):
            tdiv(style=titleStyle, title=row.title):
              text row.title
          td:
            form:
              input(`type`="checkbox", checked=toChecked(row.checked), onchange=toggle(row))
    form(style=formStyle):
      select(onchange=setParent):
        for f in bookmarkFolders:
          option(value=f.id):
            text f.title
      br()
      input(`type`="text", style=style((width, kstring"500px")), value=folderName, onblur=setFolderName)
      br()
      # FIXME: button(onclick=archivize):
      a(href="#", onclick=archivize):
        text "Archive"

proc toggle(row: var tabRow): proc() =
  return proc() =
    row.checked = not row.checked

proc setParent(ev: Event, n: VNode) =
  parentFolderID = $n.value
  echo "SEL: " & $n.value

proc setFolderName(ev: Event, n: VNode) =
  folderName = $n.value
  echo "V: " & $n.value

proc createBookmark(b: JsObject): Future[JsObject] {.async, importcpp: "browser.bookmarks.create(#)".}
proc removeTab(ids: JsObject): Future[JsObject] {.async, importcpp: "browser.tabs.remove(#)".}

proc archivize(ev: Event, n: VNode) =
  echo "Archivize!"

  # proc createBookmark(b: JsObject): Future[JsObject] {.async, importcpp: "browser.bookmarks.create(#)".}

  if folderName != "":
    browser.bookmarks.create(js{
      parentId: parentFolderID.toJs,
      title: folderName.toJs,
    # }).then(proc(b: JsObject): Future[JsObject] {.async.} =
    }).then(proc(b: JsObject) {.async.} =
      let parent = $b.id.to(cstring)
      echo "NEW: " & $b.id.to(cstring) & " " & $b.title.to(cstring)
      await archivizeIn(parent)
      # let b2 = await createBookmark(js{})
    )
    return
  discard archivizeIn(parentFolderID)

  # proc createBookmark(b: JsObject): Future[JsObject] {.async, importcpp: "browser.bookmarks.create(#)".}

  # proc foobar(): Future[JsObject] {.async.} =
  #   let b = await createBookmark(js{
  #     parentId: parentFolderID.toJs,
  #     title: folderName.toJs,
  #   })

  # if folderName != "":
  #   echo "P0: " & parentFolderID
  #   let b = await createBookmark(js{
  #     parentId: parentFolderID.toJs,
  #     title: folderName.toJs,
  #   })
  #   echo "P1: " & $b.id.to[cstring]
  # echo "xxx"

  # var archive, rest: seq[tabRow]
  # for t in tabRows:
  #   if t.checked:
  #     archive.add t
  #   else:
  #     rest.add t

  # proc book(parent, title, url: string): Future[JsObject] {.async.} =
  # proc addBookmarks(folder: JsObject): JsObject =
  #   for t in archive:
  #     f = f.then(proc(x: JsObject): JsObject =
  #       return browser.bookmarks.create(js{
  #         parentId: folder.id,
  #         title: t.title.toJs,
  #         url: t.url.toJs,
  #       })
  #     )

  # let p =
  #   if folderName != "":
  #     browser.bookmarks.create(js{
  #       parentId: parent.toJs,
  #       title: folderName.toJs,
  #     })
  #   else:
  #     browser.bookmarks.get(
  #       parent.toJs
  #     ).then(proc(list: JsObject) =

  # echo "Archivize!"
  # var parent = parentFolderID
  # if folderName != "":
  #   browser.bookmarks.create(js{
  #     parentId: parent.toJs,
  #     title: folderName.toJs,
  #   }).then(proc(b: JsObject) =
  #     parent = $b.id.to(cstring)
  #     echo "NEW: " & $b.id.to(cstring) & " " & $b.title.to(cstring)
  #   )
  # echo "P: " & parent
  # var rest: seq[tabRow]
  # for t in tabRows:
  #   if not t.checked:
  #     rest.add t
  #     continue
  #   var ok = false
  #   browser.bookmarks.create(js{
  #     parentId: parent.toJs,
  #     title: t.title.toJs,
  #     url: t.url.toJs,
  #   }).then(proc(b: JsObject) =
  #     ok = true
  #   })

  # FIXME: folderName = "" -- doesn't seem to work; use getVNodeById(id) ?
  # ev.stopPropagation()

# proc archivizeIn(folderID: string): Future[JsObject] {.async.} =
proc archivizeIn(folderID: string) {.async.} =
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
    discard await removeTab(t.id.toJs)
  echo "IN: ending..."
  # tabRows = rest
  echo "IN: end"


# TODO: how to check if browser.tabs is empty, to allow
# rendering/testing outside Firefox addon?
browser.tabs.query(js{
  currentWindow: true.toJs,
}).then(proc(tabs: JsObject) =
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
)
# TODO: somehow add `.catch(...)` handler above

# Collect full bookmark folders tree
browser.bookmarks.getTree().then(proc(items: JsObject) =
  # var list: seq[string]
  # echo "getTree:"
  bookmarkFolders.setLen 0
  proc extractFolders(node: JsObject, indent: Natural) =
    if node.url != nil: return  # we're only interested in folders
    # if node.unmodifiable != nil: return  # TODO: add or not?
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
