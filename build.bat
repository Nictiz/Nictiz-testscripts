@setlocal enableextensions
@echo off

call ant -f build.xml -q %*

pause