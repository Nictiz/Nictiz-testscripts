#!/bin/bash
ant -f ../build-multiple.xml -Dinput.dirs="src/NTV-PDFA-3-0/Validation, src/NTV-PDFA-3-0/Prevalidation" $*
