{.expermiental: "codeReordering".}

import jsffi

var browser {.importc, nodecl.}: JsObject

# TODO: icons in manifest.json

browser.contextMenus.create(js{
  id: "move-to-bookmarks",
  # TODO: browser.i18n.getMessage
  title: "Archive all tabs",
  contexts: ["tab"],
  # TODO: icons
})

browser.menus.onClicked.addListener(proc(info, tab: JsObject) =
  case info.menuItemId
  of "move-to-bookmarks":
    echo "clicked on move-to-bookmarks!"
)
