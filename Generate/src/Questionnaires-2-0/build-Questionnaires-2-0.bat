@setlocal enableextensions
@echo off

call ant -f build.xml -Dproject=Questionnaires-2-0 %*

pause