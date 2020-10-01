@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=GGZ-2-0 %*
pause