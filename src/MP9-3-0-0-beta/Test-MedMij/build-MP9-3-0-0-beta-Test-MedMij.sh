#!/bin/bash
export JAVA_HOME=`/usr/libexec/java_home`
ant -v -f ../../build-single.xml -propertyfile build.properties $*
