@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/eOverdracht-4-2/Cert, src/eOverdracht-4-2/Test" %*


pause