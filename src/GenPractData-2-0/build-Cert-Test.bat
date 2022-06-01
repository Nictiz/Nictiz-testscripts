@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/GenPractData-2-0/Test,src/GenPrachtData-2-0/Cert" %*

pause