@setlocal enableextensions
@echo off

call ant -f  ..\..\build-nts-single.xml -propertyfile build.properties %*

rem local Arianne dir
rem call ant -f ..\..\build-nts-single.xml -propertyfile build.properties %* -Dtestscripttools.localdir=C:\SourceTree\GitHub\Nictiz-tooling-testscripts\generate

pause