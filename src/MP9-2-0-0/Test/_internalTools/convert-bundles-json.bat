@echo off

echo.converting bundles to json for receive

cd ..\_reference\fixtures

for /R %%F in (*-tst-*.xml) do java -jar C:\util\validator_cli.jar "%%F" -version 4.0.1 -convert -output "%%~nF.json"

pause