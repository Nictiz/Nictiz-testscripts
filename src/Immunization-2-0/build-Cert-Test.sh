#!/bin/bash

ant -f ../build-multiple.xml -Dinput.dirs="src/Immunization-2-0/Test, src/Immunization-2-0/Cert" $*
