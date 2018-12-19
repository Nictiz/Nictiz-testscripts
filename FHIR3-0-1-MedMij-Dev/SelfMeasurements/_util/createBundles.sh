#!/bin/bash
pwd=`PWD`
export saxon=~/Development/lib/SaxonPE9-5-1-10J/saxon9pe.jar
cd "`dirname $0`"
java -jar ${saxon} -xsl:"Query-Send-Scenario2-1-createBundle-bodyweight-most-recent.xsl" -s:"_include/createBundle.xsl"
java -jar ${saxon} -xsl:"Query-Send-Scenario2-2-createBundle-bloodpressures-in-june-2018.xsl" -s:"_include/createBundle.xsl"
java -jar ${saxon} -xsl:"Query-Send-Scenario2-3-createBundle-observations-in-june-2018.xsl" -s:"_include/createBundle.xsl"
java -jar ${saxon} -xsl:"Serve-Receive-Scenario2-1-createBundle-bodyweight-most-recent.xsl" -s:"_include/createBundle.xsl"
java -jar ${saxon} -xsl:"Serve-Receive-Scenario2-2-createBundle-bloodpressures-in-june-2018.xsl" -s:"_include/createBundle.xsl"
java -jar ${saxon} -xsl:"Serve-Receive-Scenario2-3-createBundle-observations-in-june-2018.xsl" -s:"_include/createBundle.xsl"
cd "$pwd"