@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-multiple.xml -Dinput.dirs="src/BgZ-MSZ-1-0/Cert" %*
pause