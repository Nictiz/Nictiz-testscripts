#!bin/bash

echo ant mp9 30 ada2nts build test...
ant -f ant-build/build-ada2nts-mp-930.xml convert_ada_2_nts_930_test >ant-build-cert.log

echo Done
