@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-nts-multiple.xml -propertyfile MedMij-V6.properties 
call ant -f ..\src\build-centralizeLoadResources.xml -propertyfile MedMij-V6.properties
call ant -f ..\src\build-addNarratives.xml -propertyfile MedMij-V6.properties

pause