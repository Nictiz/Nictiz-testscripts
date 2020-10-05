@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=BgLZ-2-0 %*
pause