@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/BgLZ-3-0/Test,src/BgLZ-3-0/Cert" %*

pause