@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/PDFA-3-0/Test, src/PDFA-3-0/Cert" %*
pause