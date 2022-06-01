@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/Questionnaires-2-0/Test,src/Questionnaires-2-0/Cert" %*

pause