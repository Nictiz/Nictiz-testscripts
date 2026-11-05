#!/bin/bash

ant -f ../src/build-multiple.xml -Dinput.dirs="src/BirthCare/4.0/PregnancyCard/Ultrasound/Test,src/BirthCare/4.0/PregnancyCard/MaternityCare/Test,src/BirthCare/4.0/PregnancyCard/ObstetricCare/Test, src/Geboortezorg-2-0/Cert"
