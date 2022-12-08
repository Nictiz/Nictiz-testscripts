@setlocal enableextensions

@echo off
echo.ant mp 920 proposals ada2nts build...
echo.ant mp 920 proposal ma ada2nts build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_prop_ma_920 >ant-build-prop-ma.log
echo.Done with proposal ma

echo.ant mp 920 reply proposal ma ada2nts build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_reply_prop_ma_920 >ant-build-repl-prop-ma.log
echo.Done with reply proposal ma

echo.ant mp 920 proposal vv ada2nts build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_prop_vv_920 >ant-build-prop-vv.log
echo.Done with proposal vv

echo.ant mp 920 reply proposal vv ada2nts build...
call ant -f ant-build\build-ada2nts-mp-920.xml convert_ada2nts_reply_prop_vv_920 >ant-build-repl-prop-vv.log

echo.Done
pause
