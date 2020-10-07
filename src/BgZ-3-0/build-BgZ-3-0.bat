@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=BgZ-3-0 %*
pause