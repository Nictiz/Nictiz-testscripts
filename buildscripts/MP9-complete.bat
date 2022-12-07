@setlocal enabledelayedexpansion
@echo off

rem call ant -f ..\src\build-nts-multiple.xml -propertyfile MP9.properties
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile MP9.properties
rem call ant -f ..\src\build-addNarratives.xml -propertyfile MP9.properties

pause