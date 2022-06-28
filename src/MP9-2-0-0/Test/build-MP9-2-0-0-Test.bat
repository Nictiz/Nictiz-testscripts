@setlocal enableextensions
@echo off

rem call ant -f ..\..\..\build.xml -propertyfile build.properties %* -Dtestscripttools.localdir=C:\Users\144189-ADM\Documents\Git\Nictiz-tooling-testscripts\generate
call ant -f ..\..\..\build.xml -propertyfile build.properties %*
pause