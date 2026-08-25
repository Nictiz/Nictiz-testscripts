#@setlocal enableextensions
#@echo off
JAVA_HOME=`/usr/libexec/java_home -v 1.8`
#PWD=`dirname $0`

#echo "Removing ..."
#rm -f "$PWD/_reference/resources/*.xml"
#SOURCEDIR=`readlink -f "$PWD/../../../../HL7-mappings/ada_2_fhir/bgz_msz/1.2/beschikbaarstellen/fhir_instance/"`
#echo "Copying from $SOURCEDIR"
#echo "          to $PWD/_reference/resources/"
#cp "$SOURCEDIR/*.xml" "$PWD/_reference/resources/"

ant -f $PWD/../../build-single.xml -propertyfile $PWD/build.properties $*
