@setlocal enableextensions

@echo off

echo.ant cio 200 copy fixtures for Test...
call ant -f ant-build\build-ada2nts-cio-200.xml copy_fixtures-Test >ant-copyfixtures-Test.log

echo.Done
pause
