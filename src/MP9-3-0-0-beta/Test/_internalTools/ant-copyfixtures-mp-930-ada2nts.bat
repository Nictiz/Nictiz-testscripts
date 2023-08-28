@setlocal enableextensions

@echo off

echo.ant mp9 30 copy fixtures...
call ant -f ant-build\build-ada2nts-mp-930.xml copy_fixtures >ant-copyfixtures.log

echo.Done
pause
