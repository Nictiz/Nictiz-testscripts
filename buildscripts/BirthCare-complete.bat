@setlocal enabledelayedexpansion
@echo off

call ant -f ..\src\build-multiple.xml -Dinput.dirs="src/BirthCare/4.0/PregnancyCard/Ultrasound/Test,src/BirthCare/4.0/PregnancyCard/MaternityCare/Test,src/BirthCare/4.0/PregnancyCard/ObstetricCare/Test"

pause