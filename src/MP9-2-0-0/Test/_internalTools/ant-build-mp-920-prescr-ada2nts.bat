@setlocal enableextensions

@echo off

echo.ant mp 920 ada2nts build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_prescription_920 >ant-build-presc.log

echo.Done
pause
