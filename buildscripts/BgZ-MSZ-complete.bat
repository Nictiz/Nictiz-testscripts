@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile BgZ-MSZ.properties
REM call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile BgZ-MSZ.properties 

pause