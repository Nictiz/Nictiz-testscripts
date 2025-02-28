#!/bin/bash
export JAVA_HOME=`/usr/libexec/java_home`

echo "test-medmij"
cd Test-MedMij
./build-MP9-3-0-0-beta-Test-MedMij.sh

echo "test"
cd ../Test
./build-MP9-3-0-0-beta-Test.sh

echo "cert-medmij"
cd ../Cert-MedMij
./build-MP9-3-0-0-beta-Cert-MedMij.sh

echo "cert"
cd ../Cert
./build-MP9-3-0-0-beta-Cert.sh

