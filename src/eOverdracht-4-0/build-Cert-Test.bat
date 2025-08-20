@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/eOverdracht-4-0/Test, src/eOverdracht-4-0/Cert" %*

pause