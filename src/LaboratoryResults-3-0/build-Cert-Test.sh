#export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home
export JAVA_HOME=`/usr/libexec/java_home`
ant -f ../build-multiple.xml -propertyfile build.properties $*