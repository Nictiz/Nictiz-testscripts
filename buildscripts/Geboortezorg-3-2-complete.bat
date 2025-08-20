@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/Geboortezorg-3-2/Cert"

pause
