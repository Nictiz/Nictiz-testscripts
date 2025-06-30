#!/bin/bash

ant -f ../build-multiple.xml -Dinput.dirs="src/PatientCorrections-1-0/Test, src/PatientCorrections-1-0/Cert" $*
