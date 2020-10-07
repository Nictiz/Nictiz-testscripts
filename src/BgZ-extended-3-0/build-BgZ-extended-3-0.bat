@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=BgZ-extended-3-0 %*
pause