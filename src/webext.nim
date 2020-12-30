{.experimental: "codeReordering".}
import jsffi
import asyncjs

proc getBookmarksTree*(): Future[JsObject] {.
  async, importjs: "browser.bookmarks.getTree(@)".}
proc createBookmark*(b: JsObject): Future[JsObject] {.
  async, importjs: "browser.bookmarks.create(@)".}

proc queryTabs*(params: JsObject): Future[JsObject] {.
  async, importjs: "browser.tabs.query(@)".}
proc removeTabs*(ids: JsObject): Future[JsObject] {.
  async, importjs: "browser.tabs.remove(@)".}
proc updateTab*(id, props: JsObject): Future[JsObject] {.
  async, importjs: "browser.tabs.update(@)", discardable.}


