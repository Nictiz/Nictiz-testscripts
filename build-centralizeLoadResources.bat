REM Centralize LoadResources files

@setlocal enabledelayedexpansion
@echo off

call ant -f build-centralizeLoadResources.xml %*
pause