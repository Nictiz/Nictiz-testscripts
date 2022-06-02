@setlocal enableextensions
@echo off

call ant -f ..\..\build-single.xml -propertyfile build.properties %*
pause