@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/eOverdracht-4-0/Prevalidation, src/eOverdracht-4-0/Validation, src/eOverdracht-4-0/Cert, src/eOverdracht-4-0/Test" %*

pause