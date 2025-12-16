@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test, src/MP9-3-0-0-beta/Test-MedMij, src/MP9-3-0-0-beta/Cert, src/MP9-3-0-0-beta/Cert-MedMij" -Dbuild-CLPropertiesFiles.skip=true -DgenerateTestScriptsForProjects.tool.version=4.0.0

pause