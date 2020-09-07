@setlocal enabledelayedexpansion
@echo off

cd src
for /d %%i in (%cd%\*) do (
   set "project=%%~nxi"
   if /i not "!project!"==common-asserts (
      cd "%%i"
      echo ------
      echo !project!
      echo ------
      echo | call "build-!project!.bat"
      cd ..
   )
)


pause