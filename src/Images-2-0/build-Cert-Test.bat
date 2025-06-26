@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/Images-2-0/Test, src/Images-2-0/Cert" %*
pause