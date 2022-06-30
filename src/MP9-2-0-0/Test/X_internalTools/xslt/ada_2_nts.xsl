<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:import href="https://raw.githubusercontent.com/Nictiz/HL7-mappings/master/util/constants.xsl"/>
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
    
    <xsl:strip-space elements="*"/>

    <xsl:param name="mappingsUrl4FhirFixtures">https://raw.githubusercontent.com/Nictiz/HL7-mappings/MP920/ada_2_fhir-r4/mp/9.2.0/4TouchstoneMPServe</xsl:param>
    <xsl:param name="buildingBlockShort"/>
    
    <xsl:variable name="ntsInclude" select="concat('mp9-', lower-case($buildingBlockShort), '-retrieve')"/>
    
    <xsl:variable name="bsnSystem" select="$oidMap[@oid=$oidBurgerservicenummer]/@uri"/>

    <xsl:template match="/">

        <xsl:variable name="adaTransaction" select="adaxml/data/*" as="element()*"/>

        <xsl:for-each select="$adaTransaction">

            <xsl:variable name="fhirFixture" select="document(concat($mappingsUrl4FhirFixtures, '/', @id, '.xml'))"/>
            <xsl:variable name="fixturePatient" select="$fhirFixture//f:Patient[1]"/>
            <xsl:variable name="matchResources" select="$fhirFixture/f:Bundle/f:entry[f:search/f:mode/@value='match']/f:resource/*"/>
            <!-- We assume the first 'match' resource found in the Bundle is the resource that was queried for, we also assume the first category is applicable for the query -->
            <xsl:variable name="matchCategory" select="$matchResources[1]/f:category[1]/f:coding"/>
            
            <!-- Construct the string that lists the breakdown, such as (Consists of 6 MedicationDispense and 6 Medication resources.) -->
            <xsl:variable name="breakDown" as="xs:string*">               
                <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/*" group-by="local-name()">
                    <xsl:value-of select="concat(count(current-group()), ' ', current-group()[1]/local-name())"/>                    
                </xsl:for-each-group>
             </xsl:variable>
            
            <xsl:variable name="ada_id" select="//beschikbaarstellen_medicatiegegevens/@id"/>
            
            <xsl:variable name="additionalScenarioParams">
                <xsl:choose>
                    <!--TA-->
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-2'">
                        <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.422037009.1|MBH_200_QA1_TA'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-3optioneel'">
                        <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-4'">
                        <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-5'">
                        <xsl:value-of select="'&amp;period-of-use=lt${DATE, T, D,-22}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-6'">
                        <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}&amp;period-of-use=le${DATE, T, D,-7}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-7'">
                        <xsl:value-of select="'&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-TA-Scenarioset0-v20-0-8'">
                        <xsl:value-of select="'&amp;period-of-use=le${DATE, T, D,-110}'"/>
                    </xsl:when>
                    <!--VV-->
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-VV-Scenarioset0-v20-0-2'">
                        <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.52711000146108.1|MBH_200_QA1_VV'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-VV-Scenarioset0-v20-0-3optioneel'">
                        <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-VV-Scenarioset0-v20-0-4'">
                        <xsl:value-of select="'&amp;medicationtreatment=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-VV-Scenarioset0-v20-0-5'">
                        <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.52711000146108.1|MBH_200_QAnietaanwezig'"/>
                    </xsl:when>
                    <!--MTD-->
                    <!--MA-->
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-2'">
                        <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.16076005.1|MBH_200_QA1_MA'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-3optioneel'">
                        <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-4'">
                        <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-5'">
                        <xsl:value-of select="'&amp;period-of-use=lt${DATE, T, D,-22}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-6'">
                        <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}&amp;period-of-use=le${DATE, T, D,-7}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-7'">
                        <xsl:value-of select="'&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MA-Scenarioset0-v20-0-8'">
                        <xsl:value-of select="'&amp;period-of-use=le${DATE, T, D,-110}'"/>
                    </xsl:when>
                    <!--MVE-->
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-2'">
                        <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.373784005.1|MBH_200_QA1_MVE'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-3optioneel'">
                        <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-4'">
                        <xsl:value-of select="'&amp;whenhandedover=ge${DATE, T, D,-21}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-5'">
                        <xsl:value-of select="'&amp;whenhandedover=lt${DATE, T, D,-22}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-6'">
                        <xsl:value-of select="'&amp;whenhandedover=ge${DATE, T, D,-21}&amp;whenhandedover=le${DATE, T, D,-7}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-7'">
                        <xsl:value-of select="'&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MVE-Scenarioset0-v20-0-8'">
                        <xsl:value-of select="'&amp;whenhandedover=le${DATE, T, D,-110}'"/>
                    </xsl:when>
                    <!--MGB-->
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-2'">
                        <xsl:value-of select="'&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.6.1|MBH_200_QA1_MGB'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-3optioneel'">
                        <xsl:value-of select="'&amp;medication.code=urn:oid:2.16.840.1.113883.2.4.4.10|3956'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-4'">
                        <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-5'">
                        <xsl:value-of select="'&amp;period-of-use=lt${DATE, T, D,-22}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-6'">
                        <xsl:value-of select="'&amp;period-of-use=ge${DATE, T, D,-21}&amp;period-of-use=le${DATE, T, D,-7}'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-7'">
                        <xsl:value-of select="'&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|MBH_200_QA1'"/>
                    </xsl:when>
                    <xsl:when test="$ada_id = 'mg-mp-mg-tst-MGB-Scenarioset0-v20-0-8'">
                        <xsl:value-of select="'&amp;period-of-use=le${DATE, T, D,-110}'"/>
                    </xsl:when>
                    <!--WDS-->
                </xsl:choose>
            </xsl:variable> 

            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="client">
                <nts:include value="{$ntsInclude}">
                    <nts:with-parameter name="scenarioset" value="{replace(scenario-nr/@value, '(\d+)\.?(\d*)', '$1')}"/>
                    <nts:with-parameter name="scenario" value="{replace(scenario-nr/@value, '(\d+)\.?(\d*)', '$2')}"/>
                    <nts:with-parameter name="scenarioDescription" value="{replace(@desc, '(&lt;.+?&gt;)', '')}"/>
                    <nts:with-parameter name="scenarioPatient" value="{$fixturePatient/f:id/@value}"/>
                    <nts:with-parameter name="scenarioParams" value="?patient.identifier={$bsnSystem}|{$fixturePatient/f:identifier[f:system/@value=$bsnSystem]/f:value/@value}&amp;category={$matchCategory/f:system/@value}|{$matchCategory/f:code/@value}{$additionalScenarioParams}&amp;_include={local-name($matchResources[1])}:medication"/>
                    <nts:with-parameter name="returnCount" value="{count($matchResources)}"/>
                    <nts:with-parameter name="returnEntryCount" value="{count($fhirFixture/f:Bundle/f:entry)}"/>
                    <nts:with-parameter name="returnEntryBreakdown" value="(Consists of {string-join($breakDown, ', ')} resources.)"/>
                </nts:include>
            </TestScript>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
