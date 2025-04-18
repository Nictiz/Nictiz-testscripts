@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-multiple.xml -Dinput.dirs="src/BgZ-3-0/Test, src/BgZ-3-0/Cert" %*
pause