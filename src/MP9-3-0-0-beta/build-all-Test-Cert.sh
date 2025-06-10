#!/bin/bash
export JAVA_HOME=`/usr/libexec/java_home`
#use this script while CL-44 is being implemented by Interoplab 

echo "test"
cd Test
./build-MP9-3-0-0-beta-Test.sh

echo "cert"
cd ../Cert
./build-MP9-3-0-0-beta-Cert.sh

