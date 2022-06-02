@setlocal enabledelayedexpansion
@echo off

call ant -f ..\build-multiple.xml -propertyfile build.properties %*
pause