@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile MedMij-2020.01.properties 
rem call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile MedMij-2020.01.properties

pause