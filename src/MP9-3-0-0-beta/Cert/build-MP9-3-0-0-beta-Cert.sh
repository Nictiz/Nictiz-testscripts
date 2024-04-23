
#!/bin/bash
ant -Drun-ivy=false -f ../../build-single.xml -propertyfile build.properties $*
echo "Done"
read -p "Press any key to resume ..."