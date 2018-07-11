#!/bin/bash
pwd=`PWD`
export saxon=~/Development/lib/SaxonPE9-5-1-10J/saxon9pe.jar

cd "`dirname $0`"

java -jar ${saxon} -s:"Scenario2-1-createBundle-bodyweight-most-recent.xsl" -xsl:"Scenario2-1-createBundle-bodyweight-most-recent.xsl"

java -jar ${saxon} -s:"Scenario2-2-createBundle-bloodpressures-in-june-2018.xsl" -xsl:"Scenario2-2-createBundle-bloodpressures-in-june-2018.xsl"

java -jar ${saxon} -s:"Scenario2-3-createBundle-observations-in-june-2018.xsl" -xsl:"Scenario2-3-createBundle-observations-in-june-2018.xsl"

cd "$pwd"