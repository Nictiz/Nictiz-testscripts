@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile Geboortezorg-3-2.properties
REM call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile Geboortezorg-3-2.properties 

pause
