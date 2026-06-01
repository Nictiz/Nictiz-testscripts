@setlocal enableextensions
@echo off

call ant -f ..\..\build-nts-single.xml -propertyfile build.properties %* -Dtool.localdir="C:\Users\LisaDekker\git\Nictiz\Nictiz-tooling-testscripts\generate"
pause