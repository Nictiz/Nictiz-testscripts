<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:import href="https://raw.githubusercontent.com/Nictiz/HL7-mappings/master/util/constants.xsl"/>
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
    
    <xsl:strip-space elements="*"/>

    <xsl:param name="mappingsUrl4FhirFixtures">https://raw.githubusercontent.com/Nictiz/HL7-mappings/MP920/ada_2_fhir-r4/mp/9.2.0/4TouchstoneMPServe</xsl:param>
    <xsl:param name="ntsInclude">mp9-ta-retrieve</xsl:param>
    
    <xsl:variable name="bsnSystem" select="$oidMap[@oid=$oidBurgerservicenummer]/@uri"/>

    <xsl:template match="/">

        <xsl:variable name="adaTransaction" select="adaxml/data/*" as="element()*"/>

        <xsl:for-each select="$adaTransaction">

            <xsl:variable name="fhirFixture" select="document(concat($mappingsUrl4FhirFixtures, '/', @id, '.xml'))"/>
            <xsl:variable name="fixtPatient" select="$fhirFixture//f:Patient[1]"/>
            <xsl:variable name="matchResources" select="$fhirFixture/f:Bundle/f:entry[f:search/f:mode/@value='match']/f:resource/*"/>
            <!-- we assume the first 'match' resource found in the Bundle is the resource that was queried for, we also assume the first category is applicable for the query -->
            <xsl:variable name="matchCategory" select="$matchResources[1]/f:category[1]/f:coding"/>
            
            <!-- Construct the string that lists the breakdown, such as (Consists of 6 MedicationDispense and 6 Medication resources.) -->
            <xsl:variable name="breakDown" as="xs:string*">               
                <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/*" group-by="local-name()">
                    <xsl:value-of select="concat(count(current-group()), ' ', current-group()[1]/local-name())"/>                    
                </xsl:for-each-group>
             </xsl:variable>

            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="client">
                <nts:include value="{$ntsInclude}">
                    <nts:with-parameter name="scenarioset" value="{replace(scenario-nr/@value, '(\d+)\.?(\d*)', '$1')}"/>
                    <nts:with-parameter name="scenario" value="{replace(scenario-nr/@value, '(\d+)\.?(\d*)', '$2')}"/>
                    <nts:with-parameter name="scenarioDescription" value="{replace(@desc, '(&lt;.+?&gt;)', '')}"/>
                    <nts:with-parameter name="scenarioPatient" value="{$fixtPatient/f:id/@value}"/>
                    <nts:with-parameter name="scenarioParams" value="?patient.identifier={$bsnSystem}|{$fixtPatient/f:identifier[f:system/@value=$bsnSystem]/f:value/@value}&amp;category={$matchCategory/f:system/@value}|{$matchCategory/f:code/@value}&amp;_include={local-name($matchResources[1])}:medication"/>
                    <nts:with-parameter name="returnCount" value="{count($matchResources)}"/>
                    <nts:with-parameter name="returnEntryCount" value="{count($fhirFixture/f:Bundle/f:entry)}"/>
                    <nts:with-parameter name="returnEntryBreakdown" value="(Consists of {string-join($breakDown, ', ')} resources.)"/>
                </nts:include>
            </TestScript>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
