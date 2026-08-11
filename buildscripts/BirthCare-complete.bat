@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/BirthCare/3.0/PregnancyCard/Ultrasound/Test,src/BirthCare/3.0/PregnancyCard/MaternityCare/Test"

pause