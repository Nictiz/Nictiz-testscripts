@setlocal enableextensions
@echo off

rem local Jorn dir
rem call ant -f ..\..\..\build.xml -propertyfile build.properties %* -Dtestscripttools.localdir=C:\Users\144189-ADM\Documents\Git\Nictiz-tooling-testscripts\generate
rem local Arianne dir
call ant -f ..\..\..\build.xml -propertyfile build.properties %* -Dtestscripttools.localdir=C:\SourceTree\GitHub\Nictiz-tooling-testscripts\generate

rem call ant -f ..\..\..\build.xml -propertyfile build.properties %*
pause