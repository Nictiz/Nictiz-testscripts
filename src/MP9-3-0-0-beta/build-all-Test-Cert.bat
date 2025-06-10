@setlocal enabledelayedexpansion
@echo off

@REM use this script while CL-44 is being implemented by Interoplab

rem call ant -f ..\build-multiple.xml -propertyfile build.properties %*
rem calling separate build scripts, otherwise narrative generation does not work for MedMij target
cd Test
@echo | call build-MP9-3-0-0-beta-Test.bat

cd ..\Cert
@echo | call build-MP9-3-0-0-beta-Cert.bat

pause