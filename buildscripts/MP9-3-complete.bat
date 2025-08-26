@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test, src/MP9-3-0-0-beta/Test-MedMij, src/MP9-3-0-0-beta/Cert, src/MP9-3-0-0-beta/Cert-MedMij"

echo.Done
pause