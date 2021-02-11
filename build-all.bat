@setlocal enabledelayedexpansion
@echo off

cd src
for /d %%i in (%cd%\*) do (
   set "project=%%~nxi"
   if /i not !project!==common-asserts (
      cd "%%i"
      echo ------
      echo !project!
      echo ------
      for /d %%j in (%cd%\!project!\*) do (
         set "folder=%%~nxj"
         cd "%%j"
         echo --- !folder! ---
         echo | call "build-!project!-!folder!.bat"
         cd ..
      )
      cd ..
   )
)


pause