@setlocal enableextensions
@echo off

call ant -f  ..\..\build-nts-single.xml -propertyfile build-medmij.properties %*

pause