@setlocal enableextensions

@echo off

echo.ant mp 920 ada2nts meddata pull build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_pull_meddata_920 >ant-build-pull-meddata.log

echo.Done
pause
