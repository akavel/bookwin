{.experimental: "codeReordering".}
import jsffi
import asyncjs

proc createBookmark*(b: JsObject): Future[JsObject] {.
  async, importjs: "browser.bookmarks.create(@)".}

proc removeTabs*(ids: JsObject): Future[JsObject] {.
  async, importjs: "browser.tabs.remove(@)".}
proc updateTab*(id, props: JsObject): Future[JsObject] {.
  async, importjs: "browser.tabs.update(@)", discardable.}


