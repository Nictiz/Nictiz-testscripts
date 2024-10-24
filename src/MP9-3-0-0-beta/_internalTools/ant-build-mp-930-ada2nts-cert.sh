#!bin/bash

echo ant mp9 30 ada2nts build cert...
ant -f ant-build/build-ada2nts-mp-930.xml convert_ada_2_nts_930_cert >ant-build-cert.log

echo Done
