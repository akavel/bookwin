@echo off
if "%1" == "" goto :default
goto :%1
goto:eof

:default
nimble build && move /y tmm.exe tmm.js
goto:eof

:karax
karun -w src/tmm.nim
goto:eof

:eof
