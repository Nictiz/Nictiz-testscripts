@setlocal enabledelayedexpansion
@echo off

@REM call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test, src/MP9-3-0-0-beta/Test-MedMij, src/MP9-3-0-0-beta/Cert, src/MP9-3-0-0-beta/Cert-MedMij"
echo.ant MP9-3-0-0-beta_Test...
call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test" >MP9-3-0-0-beta_Test.log

echo.ant MP9-3-0-0-beta_Test-MedMij...
call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test-MedMij" >MP9-3-0-0-beta_Test-MedMij.log

echo.ant MP9-3-0-0-beta_Cert...
call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Cert, src/MP9-3-0-0-beta/Cert-MedMij" >MP9-3-0-0-beta_Cert.log

echo.ant MP9-3-0-0-beta_Cert-MedMij...
call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Cert-MedMij" >MP9-3-0-0-beta_Cert-MedMij.log

echo.Done
pause