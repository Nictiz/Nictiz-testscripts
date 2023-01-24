@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile FHIR4-0-1.properties 
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile FHIR4-0-1.properties

pause