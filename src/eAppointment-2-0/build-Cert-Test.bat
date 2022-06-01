@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-nts-multiple.xml -Dinput.dirs="src/eAppointment-2-0/Test,src/eAppointment-2-0/Cert" %*

pause