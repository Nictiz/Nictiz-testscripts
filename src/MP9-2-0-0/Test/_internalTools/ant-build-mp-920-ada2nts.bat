@setlocal enableextensions

@echo off

echo.ant mp 920 ada2nts build...
call ant -f ant-build\build-ada2nts-mp-920.xml >ant-build.log

echo.Done
pause
