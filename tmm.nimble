# Package

version       = "0.1.0"
author        = "Mateusz Czapliński"
description   = "Firefox webextension: Tab Manager Minus"
license       = "MIT"
srcDir        = "src"
bin           = @["tmm"]

backend       = "js"

# Dependencies

requires "nim >= 1.2.0"
requires "karax 1.1.2"
