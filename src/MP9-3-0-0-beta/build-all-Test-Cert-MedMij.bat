@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test-MedMij, src/MP9-3-0-0-beta/Cert-MedMij" %*

pause