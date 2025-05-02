@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile MedMij-V6.properties 
REM call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile MedMij-V6.properties

pause