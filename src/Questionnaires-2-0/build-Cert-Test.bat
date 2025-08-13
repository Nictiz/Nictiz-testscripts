@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -Dinput.dirs="src/Questionnaires-2-0/Test, src/Questionnaires-2-0/Cert" %*
pause