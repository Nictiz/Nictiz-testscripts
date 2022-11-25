@echo off
setlocal enabledelayedexpansion

cd ..\_reference\fixtures

if "%1"=="" (
	echo.converting bundles to json for receive
	for /R %%F in (*-tst-*.xml) do java -jar C:\util\validator_cli.jar "%%F" -version 4.0.1 -convert -output "%%~nF.json"
) else (
	echo.converting %1 to json for receive
	set input=%1
	java -jar C:\util\validator_cli.jar "!input!.xml" -version 4.0.1 -convert -output "!input!.json"
)

pause