@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile MedMij-2019.01.properties 
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile MedMij-2019.01.properties

pause