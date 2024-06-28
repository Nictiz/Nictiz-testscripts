@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -propertyfile MP9-3.properties 

pause