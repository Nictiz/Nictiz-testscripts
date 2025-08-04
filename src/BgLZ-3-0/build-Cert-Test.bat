@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/BgLZ-3-0/Test, src/BgLZ-3-0/Cert" %*
pause