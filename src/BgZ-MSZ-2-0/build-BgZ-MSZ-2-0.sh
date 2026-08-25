#!/bin/bash
ant -f ../build-multiple.xml -Dinput.dirs="src/BgZ-MSZ-2-0/Prevalidation, src/BgZ-MSZ-2-0/Validation" $*
