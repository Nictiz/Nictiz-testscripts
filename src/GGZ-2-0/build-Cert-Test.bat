@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/GGZ-2-0/Test,src/GGZ-2-0/Cert" %*

pause