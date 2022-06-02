@setlocal enabledelayedexpansion
@echo off

ant -f ..\build-multiple.xml -propertyfile build.properties %*
pause