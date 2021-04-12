@setlocal enabledelayedexpansion
@echo off

for /F %%i IN ('cd') do (
   set "project=%%~nxi"
)
for /d %%i in (%cd%\*) do (
   set "folder=%%~nxi"
   cd "%%i"
   echo --- !folder! ---
   echo | call "build-!project!-!folder!.bat"
   cd ..
)

pause