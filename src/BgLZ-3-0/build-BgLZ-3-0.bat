@setlocal enableextensions
@echo off

call ant -f build.xml -Dproject=BgLZ-3-0 %*
pause