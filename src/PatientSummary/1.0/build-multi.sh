#!/bin/bash
ant -f ../../build-multiple.xml -Dinput.dirs="src/PatientSummary/1.0/euPS, src/PatientSummary/1.0/nlPS" $*
