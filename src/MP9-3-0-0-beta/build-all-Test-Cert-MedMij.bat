@setlocal enabledelayedexpansion
@echo off
@REM #NICTIZ-31371 don't use this script if CL-44 is still being implemented by Interoplab but use build-all-Test-Cert.bat instead


rem call ant -f ..\build-multiple.xml -propertyfile build.properties %*
rem calling separate build scripts, otherwise narrative generation does not work for MedMij target
cd Test
@echo | call build-MP9-3-0-0-beta-Test.bat

cd ..\Test-MedMij
@echo | call build-MP9-3-0-0-beta-Test-MedMij.bat

cd ..\Cert
@echo | call build-MP9-3-0-0-beta-Cert.bat

cd ..\Cert-MedMij
@echo | call build-MP9-3-0-0-beta-Cert-MedMij.bat

pause