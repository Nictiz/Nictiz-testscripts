@setlocal enabledelayedexpansion
@echo off
#NICTIZ-31371 don't use this script if CL-44 is still being implemented by Interoplab but use build-all-Test-Cert.bat instead


@REM rem call ant -f ..\build-multiple.xml -propertyfile build.properties %*
@REM rem calling separate build scripts, otherwise narrative generation does not work for MedMij target
@REM cd Test
@REM @echo | call build-MP9-3-0-0-beta-Test.bat

@REM cd ..\Test-MedMij
@REM @echo | call build-MP9-3-0-0-beta-Test-MedMij.bat

@REM cd ..\Cert
@REM @echo | call build-MP9-3-0-0-beta-Cert.bat

@REM cd ..\Cert-MedMij
@REM @echo | call build-MP9-3-0-0-beta-Cert-MedMij.bat

@REM pause