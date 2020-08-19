@setlocal enableextensions
@echo off

call ant -f ..\build.xml -q -Dproject=Questionnaires-1-0-0 -DoutputXisInternal=true

pause