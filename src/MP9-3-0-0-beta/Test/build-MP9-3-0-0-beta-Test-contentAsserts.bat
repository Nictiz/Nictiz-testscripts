@setlocal enableextensions
@echo off

call ant -f  ..\..\build-nts-single.xml -propertyfile build-contentAsserts.properties %*

ren ..\..\..\dev\FHIR4-0-1-Test\MP9-3-0-0-beta\contentAsserts\MedicationData\Serve\AdministrationAgreement-contentAsserts AdministrationAgreement

pause