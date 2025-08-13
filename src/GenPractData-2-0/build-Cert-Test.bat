@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/GenPractData-2-0/Test, src/GenPractData-2-0/Cert" %*
pause