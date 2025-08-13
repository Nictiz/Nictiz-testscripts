@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/BgZ-MSZ-2-0/Test, src/BgZ-MSZ-2-0/Cert" %*
pause