#!/bin/bash
#export JAVA_HOME=`/usr/libexec/java_home`
#export JAVA_HOME=`$(/usr/libexec/java_home -v 21.0.2)`
#JAVA_HOME=`/usr/libexec/java_home -v 1.8.0.402`
#export JAVA_HOME=`/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`
echo "ant mp9 30 ada2nts build cert...." 
ant -f ant-build/build-ada2nts-mp-930.xml convert_ada_2_nts_930_cert > ant-build-cert.log

echo "ant mp9 30 ada2nts build test..." 
ant -Drun-ivy=false -f ant-build/build-ada2nts-mp-930.xml convert_ada_2_nts_930_test > ant-build-test.log

echo "Done"