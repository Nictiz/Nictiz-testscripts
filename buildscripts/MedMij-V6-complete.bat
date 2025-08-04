@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/PatientCorrections-1-0/Test, src/PatientCorrections-1-0/Cert, src/Immunization-2-0/Test, src/Immunization-2-0/Cert" 

pause