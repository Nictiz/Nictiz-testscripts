@setlocal enableextensions
@echo off

call ant -f build.xml -Dproject=Questionnaires-1-0-0 %*

pause