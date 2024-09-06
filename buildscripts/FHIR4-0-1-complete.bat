@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile MP9-3.properties
call ant -f ..\src\build-multiple.xml -propertyfile CiO-2.properties
call ant -f ..\src\build-multiple.xml -propertyfile LaboratoryResults-3.properties
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile FHIR4-0-1.properties

pause