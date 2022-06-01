@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/eOverdracht-4-0/Test,src/eOverdracht-4-0/Cert" %*

pause