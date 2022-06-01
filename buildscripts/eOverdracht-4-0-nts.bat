@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-nts-multiple.xml -propertyfile eOverdracht-4.0.properties 

pause