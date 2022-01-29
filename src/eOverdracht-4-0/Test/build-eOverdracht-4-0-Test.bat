@setlocal enableextensions
@echo off

call ant -f ..\..\..\build.xml -propertyfile build.properties %*
pause