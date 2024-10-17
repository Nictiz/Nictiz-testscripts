#/bin/bash

ant -f ../src/build-multiple.xml -propertyfile FHIR4-0-1.properties 
ant -f ../src/build-centralizeLoadResources.xml -propertyfile FHIR4-0-1.properties

echo Done ..