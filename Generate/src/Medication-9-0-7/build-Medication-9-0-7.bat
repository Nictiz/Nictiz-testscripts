@setlocal enableextensions
@echo off

call ant -f build.xml -Dproject=Medication-9-0-7 %*

pause