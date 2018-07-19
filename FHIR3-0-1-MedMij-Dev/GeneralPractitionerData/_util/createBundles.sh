#!/bin/bash
pwd=`PWD`
export saxon=~/Development/lib/SaxonPE9-5-1-10J/saxon9pe.jar
export inputDir=resources-query-send
export outputDir=../_reference/resources-query-send

cd "`dirname $0`"

if [ -e "${outputDir}" ]; then 
    echo "Removing output directory: $outputDir"
    rm -rf "$outputDir"
fi

for file in `ls ${inputDir}/*.xml`
do 
    echo "Processing $file ..."
    java -jar ${saxon} -xsl:"processProcessingInstructions.xsl" -s:$file T=2018-07-17 outputDir=$outputDir
done

cd "$pwd"