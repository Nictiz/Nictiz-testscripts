JAVA_HOME=`/usr/libexec/java_home -v 1.8`
ant -f ../build-multiple.xml -propertyfile ./build.properties $*