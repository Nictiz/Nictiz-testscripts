@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile BgZ-MSZ-1-0.properties
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile BgZ-MSZ-1-0.properties 

pause