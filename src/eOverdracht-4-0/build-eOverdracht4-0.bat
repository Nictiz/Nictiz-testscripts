@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/eOverdracht-4-0/Prevalidation, src/eOverdracht-4-0/Validation" %*

pause