#@setlocal enableextensions
#@echo off
PWD=`dirname $0`

rm -f "$PWD/_reference/resources/*.xml"
cp `readlink -f "$PWD/../../../../HL7-mappings/ada_2_fhir/bgz_msz/1.2/beschikbaarstellen/fhir_instance/"`/*.xml "$PWD/_reference/resources/"

ant -f $PWD/../../build-single.xml -propertyfile $PWD/build.properties $*
