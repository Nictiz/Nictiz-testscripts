@setlocal enabledelayedexpansion
@echo off

call ant -f ..\..\build-multiple.xml -Dinput.dirs="src/PatientSummary/1.0/NL-PS-Plugathon-PatientToken, src/PatientSummary/1.0/NL-PS-Plugathon-PatientId, src/PatientSummary/1.0/SystemCheck" %*
pause