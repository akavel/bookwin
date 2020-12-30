{.experimental: "codeReordering".}
import jsffi
import asyncjs

# Inspired by: https://github.com/nim-lang/Nim/blob/version-1-4/lib/js/dom.nim

when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

template soon*(body: untyped) =
  proc f() {.async, gensym.} =
    body
  # TODO: somehow add `.catch(...)` handler, forwarding the exception to Nim
  discard f()

type
  Browser* = ref BrowserObj
  BrowserObj* {.importjs.} = object of RootObj  # TODO(akavel): do I need 'of RootObj'?
    bookmarks*: Bookmarks
    tabs*: Tabs

  Bookmarks* = ref BookmarksObj
  BookmarksObj* {.importjs.} = object of RootObj

  Tabs* = ref TabsObj
  TabsObj* {.importjs.} = object of RootObj

  BookmarkTreeNode* = ref BookmarkTreeNodeObj ## https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/bookmarks/BookmarkTreeNode
  BookmarkTreeNodeObj* {.importjs.} = object of RootObj
    children*: seq[BookmarkTreeNode]
    id*: cstring
    title*: cstring
    url*: cstring
    # TODO: incomplete...

  BookmarkCreateDetails* = ref BookmarkCreateDetailsObj ## https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/bookmarks/CreateDetails
  BookmarkCreateDetailsObj* {.importjs.} = object of RootObj
    parentId*: cstring
    title*: cstring
    url*: cstring
    # TODO: incomplete...

  Tab* = ref TabObj
  TabObj* {.importjs.} = object of RootObj
    favIconUrl*: cstring
    id*: ref int  # TODO(akavel): does 'ref' work correct here? is it needed?
    title*: cstring
    url*: cstring

  TabsQueryOpts* = ref TabsQueryOptsObj
  TabsQueryOptsObj* {.importjs.} = object of RootObj
    currentWindow*: bool
    # TODO: incomplete...

  TabUpdateOpts* = ref TabUpdateOptsObj ## https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/API/tabs/update
  TabUpdateOptsObj* {.importjs.} = object of RootObj
    active*: bool  # `false` does nothing
    # TODO: incomplete...

var browser* {.importjs, nodecl.}: Browser

{.push importcpp.} # "auto-magically" declare JS methods

# Bookmarks "methods"
using bs: Bookmarks
proc create*(bs; b: BookmarkCreateDetails): Future[BookmarkTreeNode] {.async.}
proc getTree*(bs): Future[seq[BookmarkTreeNode]] {.async.}

# Tabs "methods"
using ts: Tabs
proc query*(ts; opts: TabsQueryOpts): Future[seq[Tab]] {.async.}
proc remove*(ts; ids: varargs[int]) {.async.}
proc update*(ts; id: int, opts: TabUpdateOpts): Future[Tab] {.async.}

{.pop.}  # ...importjs

