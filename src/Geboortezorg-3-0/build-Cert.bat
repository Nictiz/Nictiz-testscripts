@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/Geboortezorg-3-0/Cert" %*

pause