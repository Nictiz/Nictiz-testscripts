@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/BgLZ-3-0/Cert"

pause