#!/bin/bash
ant -f ../../build-multiple.xml -Dinput.dirs="src/PatientSummary/1.0/NL-PS-Plugathon, src/PatientSummary/1.0/SystemCheck" $*
