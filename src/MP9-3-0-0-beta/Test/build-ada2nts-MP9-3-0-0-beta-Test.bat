@setlocal enableextensions
@echo off

cd _internalTools
echo.ant mp9 30 ada2nts build...
call ant -f ant-build\build-ada2nts-mp-930.xml >ant-build.log
cd ..
call ant -f  ..\..\build-single.xml -propertyfile build.properties %*

pause