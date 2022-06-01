@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/Images-2-0/Test,src/Images-2-0/Cert" %*

pause