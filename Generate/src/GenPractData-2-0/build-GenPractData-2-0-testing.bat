@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=GenPractData-2-0 -Dtestscripttools.localdir=../../Nictiz-tooling-testscripts/generate

pause