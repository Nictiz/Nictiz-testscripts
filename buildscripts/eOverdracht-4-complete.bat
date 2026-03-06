@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/eOverdracht-4-0/Test,src/eOverdracht-4-0/Cert,src/eOverdracht-4-1/Test,src/eOverdracht-HeO/Test"

pause