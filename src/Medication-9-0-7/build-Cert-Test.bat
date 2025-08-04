@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/Medication-9-0-7/Test, src/Medication-9-0-7/Cert" %*
pause