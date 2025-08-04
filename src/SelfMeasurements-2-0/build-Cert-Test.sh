#!/bin/bash
ant -f ../build-multiple.xml -Dinput.dirs="src/SelfMeasurements-2-0/Test, src/SelfMeasurements-2-0/Cert" $*
