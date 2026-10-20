@setlocal enabledelayedexpansion
@echo off

call ant -f ..\..\build-multiple.xml -Dinput.dirs="src/PatientSummary/1.0/NL-PS-Plugathon, src/PatientSummary/1.0/ConnectionCheck" %*
pause