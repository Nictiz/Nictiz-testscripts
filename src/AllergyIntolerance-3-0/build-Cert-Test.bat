@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/AllergyIntolerance-3-0/Test,src/AllergyIntolerance-3-0/Cert" %*
pause