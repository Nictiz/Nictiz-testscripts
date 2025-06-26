@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/GGZ-2-0/Test, src/GGZ-2-0/Cert" %*
pause