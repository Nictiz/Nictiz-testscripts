@setlocal enableextensions
@echo off

call ant -f ..\..\build.xml -Dproject=eAppointment-2-0 %*
pause