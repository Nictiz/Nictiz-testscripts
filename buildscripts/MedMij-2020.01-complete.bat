@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-nts-multiple.xml -propertyfile MedMij-2020.01.properties 
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile MedMij-2020.01.properties
call ant -f ..\src\build-addNarratives.xml -propertyfile MedMij-2020.01.properties

pause