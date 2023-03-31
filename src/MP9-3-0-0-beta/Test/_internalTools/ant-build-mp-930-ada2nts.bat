@setlocal enableextensions

@echo off

echo.ant mp9 30 ada2nts build...
call ant -f ant-build\build-ada2nts-mp-930.xml >ant-build.log

echo.Done
pause
