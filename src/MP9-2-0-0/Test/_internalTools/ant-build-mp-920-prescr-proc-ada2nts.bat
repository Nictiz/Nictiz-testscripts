@setlocal enableextensions

@echo off

echo.ant mp 920 ada2nts build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_prescription_processing_920 >ant-build-presc-proc.log

echo.Done
pause
