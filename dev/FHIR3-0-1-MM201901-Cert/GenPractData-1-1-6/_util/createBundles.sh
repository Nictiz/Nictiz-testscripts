#!/bin/bash
pwd=`PWD`
export saxon=~/Development/lib/SaxonPE9-5-1-10J/saxon9pe.jar
export inputDir1=resources-query-send
export inputDir2=../_reference/resources-generic
export outputDir1=../_reference/resources-query-send
cd "`dirname $0`"
#if [ -e "${outputDir}" ]; then 
    #echo "Removing output directory: $outputDir"
    #rm -rf "$outputDir"
#fi
#for file in `ls ${inputDir1}/*.xml`
#do 
#    echo "Processing $file ..."
    #java -jar ${saxon} -xsl:"processProcessingInstructions.xsl" -s:$file T=2018-07-17 outputDir=$outputDir1
#    java -jar ${saxon} -xsl:"processProcessingInstructions.xsl" -s:$file outputDir=$outputDir1
#done
echo "Creating Composition resources from Encounters"
java -jar ${saxon} -xsl:"createComposition.xsl" -s:createComposition.xsl inputDir1=$outputDir1
echo "Creating Create TestScript resource from fixtures"
java -jar ${saxon} -xsl:"createTestScript.xsl" -s:createTestScript.xsl -o:../_LoadResources/medmij-gpdata-fhir3-0-1-load-resources-createupdate-xml.xml  inputDir1=$inputDir2 inputDir2=$outputDir1
echo "Creating Delete TestScript resource from fixtures"
java -jar ${saxon} -xsl:"createTestScript.xsl" -s:createTestScript.xsl -o:../_ClearResources/medmij-gpdata-fhir3-0-1-clear-resources-delete-xml.xml  inputDir1=$inputDir2 inputDir2=$outputDir1
cd "$pwd"