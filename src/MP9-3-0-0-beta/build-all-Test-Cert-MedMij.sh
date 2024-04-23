#!/bin/bash
#rem call ant -f ..\build-multiple.xml -propertyfile build.properties %*
#rem calling separate build scripts, otherwise narrative generation does not work for MedMij target
cd Test
echo "@echo | call build-MP9-3-0-0-beta-Test.sh" 
sh build-MP9-3-0-0-beta-Test.sh
echo "Done"

cd ../Test-MedMij
echo "@echo | call build-MP9-3-0-0-beta-Test-MedMij.sh" 
sh build-MP9-3-0-0-beta-Test-MedMij.sh
echo "Done"

cd ../Cert
echo "@echo | call build-MP9-3-0-0-beta-Cert.sh" 
sh build-MP9-3-0-0-beta-Test-Cert.sh
echo "Done"

cd ../Cert-MedMij
echo "@echo | call build-MP9-3-0-0-beta-Cert-MedMij.sh" 
sh build-MP9-3-0-0-beta-Test-Cert-MedMij.sh
echo "Done"
read -p "Press any key to resume ..."
