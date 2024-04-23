#!/bin/bash
#export JAVA_HOME=`/usr/libexec/java_home -v 1.8.0.402`

ant -Drun-ivy=false -f ../../build-single.xml -propertyfile build.properties $*
echo "Done"
read -p "Press any key to resume ..."