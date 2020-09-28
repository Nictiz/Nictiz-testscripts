@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=SelfMeasurements-2-0 %*
pause