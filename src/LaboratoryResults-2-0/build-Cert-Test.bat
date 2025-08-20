@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/LaboratoryResults-2-0/Test, src/LaboratoryResults-2-0/Cert" %*
pause