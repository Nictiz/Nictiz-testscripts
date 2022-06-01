@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/PDFA-3-0/Test,src/PDFA-3-0/Cert" %*

pause