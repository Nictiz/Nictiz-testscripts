@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile eOverdracht-4-0.properties
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile eOverdracht-4-0.properties 

pause