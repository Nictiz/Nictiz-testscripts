@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/LaboratoryResults-3-0/Test, src/LaboratoryResults-3-0/Cert" %*
pause