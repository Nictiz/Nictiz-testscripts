@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/VitalSigns-2-0/Test, src/VitalSigns-2-0/Cert" %*
pause