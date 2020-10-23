@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=PDFA-3-0 %*
pause