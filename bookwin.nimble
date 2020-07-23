# Package

version       = "0.1.0"
author        = "Mateusz Czapliński"
description   = "Firefox webextension for moving window tabs to bookmarks."
license       = "LGPL-3.0"
srcDir        = "src"
bin           = @["bookwin"]

backend       = "js"

# Dependencies

requires "nim >= 1.2.0"
