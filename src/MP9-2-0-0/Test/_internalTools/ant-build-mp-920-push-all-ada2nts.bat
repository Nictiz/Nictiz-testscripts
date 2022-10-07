@setlocal enableextensions

@echo off

echo.ant mp 920 ada2nts push all build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_push_all_920 >ant-build-push.log

echo.Done
pause
