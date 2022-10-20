@setlocal enableextensions
@echo off

echo ==ADA2NTS==
call ant -f _internalTools\ant-build\build-ada2nts-mp-920.xml >_internalTools\ant-build.log

echo ==NTS==
call ant -f  ..\..\build-nts-single.xml -propertyfile build.properties %*

rem local Arianne dir
rem call ant -f ..\..\build-nts-single.xml -propertyfile build.properties %* -Dtestscripttools.localdir=C:\SourceTree\GitHub\Nictiz-tooling-testscripts\generate

pause