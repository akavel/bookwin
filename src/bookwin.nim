# {.expermiental: "codeReordering".}

import jsffi

var browser {.importc, nodecl.}: JsObject

# TODO: icons in manifest.json

browser.contextMenus.create(js{
  id: "move-to-bookmarks".toJs,
  # TODO: browser.i18n.getMessage
  title: "Archive all tabs".toJs,
  contexts: ["tab".toJs],
  # TODO: icons
})

browser.contextMenus.onClicked.addListener(proc(info, tab: JsObject) =
  case $info.menuItemId.to(cstring)
  of "move-to-bookmarks":
    echo "clicked on move-to-bookmarks!"
)
