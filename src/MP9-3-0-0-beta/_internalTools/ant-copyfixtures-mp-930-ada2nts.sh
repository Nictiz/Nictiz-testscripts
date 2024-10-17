#!/bin/bash

echo "ant mp9 30 copy fixtures for Test..." 
ant -Drun-ivy=false -f ant-build/build-ada2nts-mp-930.xml copy_fixtures-Test > ant-copyfixtures-Test.log

echo "ant mp9 30 copy fixtures for Cert..." 
ant -Drun-ivy=false -f ant-build/build-ada2nts-mp-930.xml copy_fixtures-Cert > ant-copyfixtures-Cert.log

echo "Done"


