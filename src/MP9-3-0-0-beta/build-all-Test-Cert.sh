#!/bin/bash
ant -f ../build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test,src/MP9-3-0-0-beta/Test-MedMij, src/MP9-3-0-0-beta/Cert,src/MP9-3-0-0-beta/Cert-MedMij" $*
ant -f ../build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test-mbhid,src/MP9-3-0-0-beta/Test-mbhid-MedMij, src/MP9-3-0-0-beta/Cert-mbhid,src/MP9-3-0-0-beta/Cert-mbhid-MedMij" $*
