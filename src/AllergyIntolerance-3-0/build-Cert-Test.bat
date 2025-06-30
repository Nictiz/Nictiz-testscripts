@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/AllergyIntolerance-3-0/Test,src/AllergyIntolerance-3-0/Cert" %*
pause