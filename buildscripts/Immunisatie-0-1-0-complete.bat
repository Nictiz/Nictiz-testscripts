@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-nts-multiple.xml -propertyfile Immunisatie-0-1.properties
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile Immunisatie-0-1.properties 
call ant -f ..\src\build-addNarratives.xml -propertyfile Immunisatie-0-1.properties

pause