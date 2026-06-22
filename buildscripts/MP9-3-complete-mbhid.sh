#/bin/bash

# ant -f ../src/build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test, src/MP9-3-0-0-beta/Test-MedMij, src/MP9-3-0-0-beta/Cert, src/MP9-3-0-0-beta/Cert-MedMij"

echo "ant mp9 30 MP9-3-build Test mbhid..."
ant -f ../src/build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test-mbhid" >MP9-3-0-0-beta_Test-mbhid.log 

echo "ant mp9 30 MP9-3-build Test-MedMij mbhid..."
ant -f ../src/build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Test-mbhid-MedMij" >MP9-3-0-0-beta_Test-MedMij-mbhid.log

echo "ant mp9 30 MP9-3-build Cert mbhid..."
ant -f ../src/build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Cert-mbhid" >MP9-3-0-0-beta_Cert-mbhid.log 

echo "ant mp9 30 MP9-3-build Cert-MedMij mbhid..."
ant -f ../src/build-multiple.xml -Dinput.dirs="src/MP9-3-0-0-beta/Cert-mbhid-MedMij" >MP9-3-0-0-beta_Cert-MedMij-mbhid.log

echo "Done"