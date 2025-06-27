@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/Immunization-2-0/Test, src/Immunization-2-0/Cert" %*
pause