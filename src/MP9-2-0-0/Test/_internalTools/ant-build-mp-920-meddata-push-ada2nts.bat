@setlocal enableextensions

@echo off

echo.ant mp 920 ada2nts meddata push build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_meddata_920 >ant-build-meddata-push.log

echo.Done
pause
