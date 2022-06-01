@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/LaboratoryResults-2-0/Test,src/LaboratoryResults-2-0/Cert" %*

pause