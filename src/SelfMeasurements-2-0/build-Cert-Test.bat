@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/SelfMeasurements-2-0/Test,src/SelfMeasurements-2-0/Cert" %*

pause