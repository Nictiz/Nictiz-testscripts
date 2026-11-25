@setlocal enabledelayedexpansion
@echo off

call ant -f ..\..\build-multiple.xml -Dinput.dirs="src/PatientSummary-AI/1.0/NL-PS-Aanvullend-PatientToken, src/PatientSummary-AI/1.0/NL-PS-Aanvullend-PatientId, src/PatientSummary-AI/1.0/NL-PS-Aanvullend-SystemCheck", "src/PatientSummary-AI/1.0/NL-PS-Regressie-PatientId, src/PatientSummary-AI/1.0/NL-PS-Regressie-PatientToken" %*
pause