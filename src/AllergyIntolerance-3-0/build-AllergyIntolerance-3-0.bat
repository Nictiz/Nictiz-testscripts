@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=AllergyIntolerance-3-0 %*
pause