#!/bin/ash

if [[ $1 -eq "single" ]]; then
    ant -f /repo/src/build-single.xml -propertyfile $2
elif [[ $1 -eq "multiple" ]]; then
    ant -f /repo/src/build-multiple.xml -propertyfile $2
elif [[ $1 -eq "tree" ]]; then
    ant -f /repo/src/build-multiple.xml -propertyfile $2
    ant -f /repo/src/build-centralizeLoadResources.xml -propertyfile $2
else
    echo "Specify 'single', 'multiple' or 'tree' as the first argument"
fi