<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:f="http://hl7.org/fhir"
    xmlns:util="urn:hl7:utilities"
    xmlns:nf="http://www.nictiz.nl/functions"
    exclude-result-prefixes="#all"
    version="2.0"
    xmlns=""
    >
    
    <!-- imports you already had -->
    <xsl:import href="../../../../../YATC-internal/ada-2-fhir-r4/env/fhir/2_fhir_fixtures.xsl"/>
    <xsl:import href="ada_2_nts.xsl"/>
    
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>
    
    <!-- params -->
    <xsl:param name="transactionType"/>
    <xsl:param name="inputDir"/>
    <xsl:param name="outputDir"/>
    <xsl:param name="refDir"/>
    <xsl:param name="enableContentAsserts" select="true()"/>
    <xsl:param name="testGoal" as="xs:string?">
        <xsl:choose>
            <xsl:when test="contains(upper-case($outputDir), 'CERT')">Cert</xsl:when>
            <xsl:otherwise>Test</xsl:otherwise>
        </xsl:choose>
    </xsl:param>
    
    <!-- normalized paths and helpers -->
    <xsl:variable name="refDirNormalized" select="nf:normalize-path($refDir)"/>
    <xsl:variable name="transactionTypeNormalized" select="normalize-space(lower-case($transactionType))"/>
    <xsl:variable name="inputDirNormalized" select="nf:normalize-path($inputDir)"/>
    <xsl:variable name="outputDirNormalized" select="nf:normalize-path($outputDir)"/>
    
    <!-- ===== Start template ===== -->
    <xsl:template match="/">
        <xsl:call-template name="util:logMessage">
            <xsl:with-param name="level" select="$logINFO"/>
            <xsl:with-param name="msg">transactionTypeNormalized: <xsl:value-of select="$transactionTypeNormalized"/> - inputDir: <xsl:value-of select="$inputDirNormalized"/> - outputDir: <xsl:value-of select="$outputDirNormalized"/></xsl:with-param>
        </xsl:call-template>
        
        <!-- Determine file pattern (tst/kwal) -->
        <xsl:variable name="fileNamePart" as="xs:string">
            <xsl:choose>
                <xsl:when test="$testGoal = 'Cert'">kwal</xsl:when>
                <xsl:otherwise>tst</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- normal (non CONS) -->
        <xsl:for-each select="collection(concat($inputDirNormalized, '?select=mg-mp-mg-', $fileNamePart, '-*.xml'))">
            <xsl:variable name="scenarioset" select="xs:integer(replace(./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$1'))"/>
            <xsl:variable name="buildingBlockShort" select="substring-before(substring-after(./adaxml/data/beschikbaarstellen_medicatiegegevens/@id, concat('mg-mp-mg-', $fileNamePart, '-')), '-')[1]" as="xs:string*"/>
            
            <xsl:choose>
                <!-- Set 0: use filter-aware path -->
                <xsl:when test="$scenarioset = 0">
                    <xsl:choose>
                        <xsl:when test="./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value = '0'"/>
                        <xsl:otherwise>
                            <xsl:call-template name="handleFilterScenario">
                                <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                                <xsl:with-param name="scenarioset" select="$scenarioset"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- Other sets -->
                <xsl:otherwise>
                    <xsl:call-template name="createNts">
                        <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                        <xsl:with-param name="scenarioset" select="$scenarioset"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
        <!-- consolidation -->
        <xsl:for-each select="collection(concat($inputDirNormalized, '?select=mg-mp-mg-CONS-*.xml'))">
            <xsl:variable name="scenarioset" select="./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value"/>
            <xsl:choose>
                <xsl:when test="$scenarioset = '0'"/>
                <xsl:otherwise>
                    <xsl:variable name="buildingBlockShort" select="substring-before(substring-after(./adaxml/data/beschikbaarstellen_medicatiegegevens/@id, 'mg-mp-mg-'), '-Scenarioset')"/>
                    <xsl:call-template name="createNts">
                        <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                        <xsl:with-param name="scenarioset" select="$scenarioset"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ===== Content fixture lookup (unchanged behavior) ===== -->
    <xsl:template name="findContentAssertFixture">
        <xsl:param name="identifier"/>
        <xsl:for-each select="collection(concat($refDirNormalized, '?select=mp-*-*.xml'))">
            <xsl:variable name="logicalId" select="./*/f:id/@value"/>
            <xsl:variable name="resIdentifier" select="./*/f:identifier/f:value/@value"/>
            <xsl:if test="$resIdentifier = $identifier">
                <xsl:value-of select="$logicalId"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <!-- ===== Non-filter scenarios ===== -->
    <xsl:template name="createNts">
        <xsl:param name="buildingBlockShort"/>
        <xsl:param name="scenarioset"/>
        
        <xsl:variable name="adaInstance" select="adaxml/data/beschikbaarstellen_medicatiegegevens"/>
        <xsl:variable name="buildingBlockLong" select="nf:makeBuildingBlockLong($buildingBlockShort)"/>
        <xsl:variable name="scenario">x</xsl:variable>
        <xsl:variable name="newFilename" select="concat($buildingBlockShort, '-Scenarioset', $scenarioset, '.xml')"/>
        
        <xsl:variable name="ntsScenario" as="xs:string?">
            <xsl:choose>
                <xsl:when test="$transactionTypeNormalized = ('retrieve', 'send')">client</xsl:when>
                <xsl:when test="$transactionTypeNormalized = ('serve', 'receive')">server</xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Unknown transactionType</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="matchCategoryCode" select="nf:matchCategoryCode($buildingBlockShort)"/>
        <xsl:variable name="matchResource" select="nf:matchResource($buildingBlockShort)"/>
        
        <!-- patient -->
        <xsl:variable name="patient" select="$adaInstance[1]/patient[1]"/>
        <xsl:variable name="patientBsn" select="$patient/identificatienummer/@value"/>
        <xsl:variable name="patientName">
            <xsl:choose>
                <xsl:when test="$patient/naamgegevens[*[not(name() = 'naamgebruik')]]">
                    <xsl:value-of select="translate(normalize-space(string-join($patient/naamgegevens[1]//*[not(name() = 'naamgebruik')]/@value, ' ')), '_. ', '--')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="util:logMessage">
                        <xsl:with-param name="level" select="$logFATAL"/>
                        <xsl:with-param name="msg">Cannot determine patient name: <xsl:value-of select="$patientBsn"/></xsl:with-param>
                        <xsl:with-param name="terminate" select="true()"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- params -->
        <xsl:variable name="theParamParts"
            select="concat('category=http://snomed.info/sct|', $matchCategoryCode, '&amp;_include=', $matchResource, ':medication','&amp;_include=', $matchResource, ':subject')"/>
        <xsl:variable name="practitionerParamParts"
            select="'&amp;_include:iterate=PractitionerRole:organization&amp;_include:iterate=PractitionerRole:practitioner&amp;_include:iterate=PractitionerRole:location'"/>
        <xsl:variable name="theAdditionalParamParts">
            <xsl:choose>
                <xsl:when test="$buildingBlockShort = 'MA'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':reason', '&amp;_include=', $matchResource, ':next-practitioner', '&amp;_include=', $matchResource, ':requester', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MGB'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':author', '&amp;_include=', $matchResource, ':prescriber', '&amp;_include=', $matchResource, ':source', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MTD'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':performer', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MVE'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':performer', '&amp;_include=', $matchResource, ':destination', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'TA'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':performer', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'VV'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':requester', '&amp;_include=', $matchResource, ':dispense-location', $practitionerParamParts)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="theScenarioParams" select="concat('?patient.identifier=', $bsnSystem, '|', $patientBsn, '&amp;', $theParamParts, $theAdditionalParamParts)"/>
        <xsl:variable name="theScenarioParamsMedMij" select="concat('?', $theParamParts, $theAdditionalParamParts)"/>
        
        <!-- counts -->
        <xsl:variable name="returnCount" select="count($adaInstance/medicamenteuze_behandeling/*[not(self::identificatie)])"/>
        <xsl:variable name="returnMedicationCount" select="count($adaInstance/bouwstenen/farmaceutisch_product)"/>
        <xsl:variable name="returnEntryCount" select="$returnCount + $returnMedicationCount"/>
        <xsl:variable name="returnEntryBreakdown">
            <xsl:choose>
                <xsl:when test="$returnEntryCount gt 0">
                    <xsl:value-of select="concat('(Consists of ', $returnCount, ' ', $matchResource, ' and ', $returnMedicationCount, ' Medication resources.)')"/>
                </xsl:when>
                <xsl:otherwise>(Consists of no resources.)</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- description -->
        <xsl:variable name="description" as="xs:string?">
            <xsl:choose>
                <xsl:when test="string-length($adaInstance/@title) gt 0 and string-length($adaInstance/@desc) gt 0">
                    <xsl:value-of select="string-join(($adaInstance/@title, $adaInstance/@desc), ' - ')"/>
                </xsl:when>
                <xsl:when test="string-length($adaInstance/@title) gt 0">
                    <xsl:value-of select="$adaInstance/@title"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$adaInstance/@desc"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- emit -->
        <xsl:result-document href="{concat($outputDirNormalized, nf:system-dir($transactionTypeNormalized), '/', $buildingBlockLong, '/', $newFilename)}">
            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                <id value="mp9-{if(contains($buildingBlockShort,'CONS')) then 'Consolidation-' else ''}{$buildingBlockLong}-{$transactionTypeNormalized}-{$scenarioset}-{$scenario}"/>
                <version value="r4-mp9-3.0.0-beta"/>
                <name value="Medication Process 9 3.0.0-beta  - {if(contains($buildingBlockShort,'CONS')) then 'Consolidation - ' else ''}{$buildingBlockLong} - {nf:first-cap($transactionTypeNormalized)} - Scenario {$scenarioset}.{$scenario}"/>
                <description value="Scenario {$scenarioset}.{$scenario} - {$description}"/>
                <nts:authToken patientResourceId="nl-core-Patient-mp9-{$patientName}" nts:in-targets="MedMij"/>
                <nts:includeDateT value="no"/>
                
                <test id="Scenario-{$scenarioset}-{$scenario}">
                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                    <description value="{$description}"/>
                    <xsl:choose>
                        <xsl:when test="$transactionTypeNormalized = 'retrieve'">
                            <nts:include value="test.client.search" scope="common" nts:in-targets="#default">
                                <nts:with-parameter name="description" value="Test client to retrieve {$matchResource} resource(s) representing MP9 building block {$buildingBlockLong}"/>
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="params" value="{$theScenarioParams}"/>
                            </nts:include>
                            <nts:include value="medmij/test.phr.search" scope="common" nts:in-targets="MedMij">
                                <nts:with-parameter name="description" value="Test PHR client to retrieve {$matchResource} resource(s) representing MP9 building block {$buildingBlockLong}"/>
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="params" value="{$theScenarioParamsMedMij}"/>
                            </nts:include>
                            <nts:include value="canary-assert.response.successfulSearch" scope="common"/>
                            <nts:include value="assert-returnCount" scope="project">
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="count" value="{$returnCount}"/>
                            </nts:include>
                            <nts:include value="assert-returnEntryCountAtLeast" scope="project">
                                <nts:with-parameter name="count" value="{$returnEntryCount}"/>
                                <nts:with-parameter name="breakdown" value="{$returnEntryBreakdown}"/>
                            </nts:include>
                        </xsl:when>
                        
                        <xsl:when test="$transactionTypeNormalized = 'serve'">
                            <nts:include value="test.server.search" scope="common" nts:in-targets="#default">
                                <nts:with-parameter name="description" value="Test server to serve {$matchResource} resource(s) representing MP9 building block {$buildingBlockLong}"/>
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="params" value="{$theScenarioParams}"/>
                            </nts:include>
                            <nts:include value="medmij/test.xis.search" scope="common" nts:in-targets="MedMij">
                                <nts:with-parameter name="description" value="Test XIS server to serve {$matchResource} resource(s) representing MP9 building block {$buildingBlockLong}"/>
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="params" value="{$theScenarioParamsMedMij}"/>
                            </nts:include>
                            
                            <nts:include value="assert.response.successfulSearch" scope="common"/>
                            <nts:include value="assert-responseBundleContent-noMM"/>
                            <nts:include value="assert-returnCountAtLeast" scope="project">
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="count" value="{$returnCount}"/>
                            </nts:include>
                            <nts:include value="assert-returnEntryCountAtLeast" scope="project">
                                <nts:with-parameter name="count" value="{$returnEntryCount}"/>
                                <nts:with-parameter name="breakdown" value="{$returnEntryBreakdown}"/>
                            </nts:include>
                        </xsl:when>
                    </xsl:choose>
                </test>
            </TestScript>
        </xsl:result-document>
    </xsl:template>
    
    <!-- ===== Filter scenarios (set 0.*) with dynamic PoU tolerance ===== -->
    <xsl:template name="handleFilterScenario">
        <xsl:param name="buildingBlockShort"/>
        <xsl:param name="scenarioset"/>
        
        <xsl:variable name="adaInstance" select="adaxml/data/beschikbaarstellen_medicatiegegevens"/>
        <xsl:variable name="theScenario" select="$adaInstance/scenario-nr/@value"/>
        <xsl:variable name="theScenarioForTestscript" select="replace(nf:removeSpecialCharacters($theScenario), '\.', '-')"/>
        
        <!-- patient -->
        <xsl:variable name="patient" select="$adaInstance/patient"/>
        <xsl:variable name="patientBsn" select="$patient/identificatienummer/@value"/>
        <xsl:variable name="patientName">
            <xsl:choose>
                <xsl:when test="$patient/naamgegevens[*[not(name() = 'naamgebruik')]]">
                    <xsl:value-of select="translate(normalize-space(string-join($patient/naamgegevens[1]//*[not(name() = 'naamgebruik')]/@value, ' ')), '_. ', '--')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="util:logMessage">
                        <xsl:with-param name="level" select="$logFATAL"/>
                        <xsl:with-param name="msg">Cannot determine patient name: <xsl:value-of select="$patientBsn"/></xsl:with-param>
                        <xsl:with-param name="terminate" select="true()"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="buildingBlockLong" select="nf:makeBuildingBlockLong($buildingBlockShort)"/>
        <xsl:variable name="matchCategoryCode" select="nf:matchCategoryCode($buildingBlockShort)"/>
        <xsl:variable name="matchResource" select="nf:matchResource($buildingBlockShort)"/>
        
        <xsl:variable name="newFilename" select="concat($buildingBlockShort, '-Scenario', $theScenarioForTestscript, '.xml')"/>
        
        <!-- external scenario config -->
        <xsl:variable name="set0config" select="document('set0-config.xml')"/>
        <xsl:variable name="configCurrentScenario" select="$set0config//*[local-name() = $testGoal]/*[local-name() = nf:first-cap($transactionTypeNormalized)]/*[local-name() = $buildingBlockLong]/TestScript[scenarioFullNumber/@value = $theScenario]"/>
        <xsl:variable name="additionalScenarioParams" select="$configCurrentScenario/params/@value" as="xs:string?"/>
        
        <!-- normalize additional params -->
        <xsl:variable name="theParamParts">
            <xsl:variable name="normalizedAdd">
                <xsl:choose>
                    <xsl:when test="starts-with($additionalScenarioParams, '&amp;amp;') or string-length($additionalScenarioParams) = 0">
                        <xsl:value-of select="$additionalScenarioParams"/>
                    </xsl:when>
                    <xsl:when test="starts-with($additionalScenarioParams, '&amp;')">
                        <xsl:value-of select="concat('&amp;', substring-after($additionalScenarioParams, '&amp;'))"/>
                    </xsl:when>
                    <xsl:when test="starts-with($additionalScenarioParams, '?')">
                        <xsl:value-of select="concat('&amp;', substring-after($additionalScenarioParams, '?'))"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="concat('category=http://snomed.info/sct|', $matchCategoryCode, replace($additionalScenarioParams, '&amp;', '&amp;'), '&amp;_include=', $matchResource, ':medication')"/>
        </xsl:variable>
        
        <xsl:variable name="practitionerParamParts" select="'&amp;_include:iterate=PractitionerRole:organization&amp;_include:iterate=PractitionerRole:practitioner&amp;_include:iterate=PractitionerRole:location'"/>
        <xsl:variable name="theAdditionalParamParts">
            <xsl:choose>
                <xsl:when test="$buildingBlockShort = 'MA'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':reason', '&amp;_include=', $matchResource, ':next-practitioner', '&amp;_include=', $matchResource, ':requester', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MGB'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':author', '&amp;_include=', $matchResource, ':prescriber', '&amp;_include=', $matchResource, ':source', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MTD'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':performer', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'MVE'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':performer', '&amp;_include=', $matchResource, ':destination', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'TA'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':performer', $practitionerParamParts)"/>
                </xsl:when>
                <xsl:when test="$buildingBlockShort = 'VV'">
                    <xsl:value-of select="concat('&amp;_include=', $matchResource, ':requester', '&amp;_include=', $matchResource, ':dispense-location', $practitionerParamParts)"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="theScenarioParams" select="concat('?patient.identifier=', $bsnSystem, '|', $patientBsn, '&amp;', $theParamParts, $theAdditionalParamParts)"/>
        <xsl:variable name="theScenarioParamsMedMij" select="concat('?', $theParamParts , $theAdditionalParamParts)"/>
        
        <xsl:variable name="description" as="xs:string?" select="$adaInstance/@desc"/>
        <xsl:variable name="returnCount" select="count($adaInstance/medicamenteuze_behandeling/*[not(self::identificatie)])"/>
        <xsl:variable name="returnEntryCount" select="$returnCount + count($adaInstance/bouwstenen/farmaceutisch_product)"/>
        <xsl:variable name="returnEntryBreakdown">
            <xsl:choose>
                <xsl:when test="$returnEntryCount gt 0">
                    <xsl:value-of select="concat('(Consists of ', $returnCount, ' ', $matchResource, ' and ', count($adaInstance/bouwstenen/farmaceutisch_product), ' Medication resources.)')"/>
                </xsl:when>
                <xsl:otherwise>(Consists of no resources.)</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:result-document href="{concat($outputDirNormalized, nf:system-dir($transactionTypeNormalized), '/', $buildingBlockLong, '/', $newFilename)}">
            <xsl:variable name="ntsScenario" as="xs:string?">
                <xsl:choose>
                    <xsl:when test="$transactionTypeNormalized = ('retrieve')">client</xsl:when>
                    <xsl:when test="$transactionTypeNormalized = ('serve')">server</xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="util:logMessage">
                            <xsl:with-param name="level" select="$logFATAL"/>
                            <xsl:with-param name="msg">Unknown $transactionTypeNormalized: <xsl:value-of select="$transactionTypeNormalized"/></xsl:with-param>
                            <xsl:with-param name="terminate" select="true()"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                <!-- optional include passthrough -->
                <xsl:if test="$configCurrentScenario/include/*">
                    <xsl:apply-templates select="$configCurrentScenario/include/*" mode="copy"/>
                </xsl:if>
                
                <id value="mp9-{lower-case($buildingBlockShort)}-{$transactionType}-{$theScenarioForTestscript}"/>
                <version value="r4-mp9-3.0.0-beta"/>
                <name value="Medication Process 9 3.0.0-beta  - {$buildingBlockLong} - {nf:first-cap($transactionType)} - Scenario {$theScenario}"/>
                <description value="Scenario {$theScenario} - {$description}"/>
                <nts:authToken patientResourceId="nl-core-Patient-mp9-{$patientName}" nts:in-targets="MedMij"/>
                <xsl:if test="contains($additionalScenarioParams, '${DATE, T,')">
                    <nts:includeDateT value="yes"/>
                </xsl:if>
                
                <test id="Scenario-{$theScenarioForTestscript}">
                    <name value="Scenario {$theScenario}"/>
                    <description value="{$description}"/>
                    
                    <xsl:choose>
                        <xsl:when test="$transactionTypeNormalized = 'retrieve'">
                            <nts:include value="test.client.search" scope="common" nts:in-targets="#default">
                                <nts:with-parameter name="description" value="Test client to retrieve {$matchResource} resource(s) representing MP9 building block {$buildingBlockLong}"/>
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="params" value="{$theScenarioParams}"/>
                            </nts:include>
                            <nts:include value="medmij/test.phr.search" scope="common" nts:in-targets="MedMij">
                                <nts:with-parameter name="description" value="Test PHR client to retrieve {$matchResource} resource(s) representing MP9 building block {$buildingBlockLong}"/>
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="params" value="{$theScenarioParamsMedMij}"/>
                            </nts:include>
                            <nts:include value="canary-assert.response.successfulSearch" scope="common"/>
                            <nts:include value="assert-returnCount" scope="project">
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="count" value="{$returnCount}"/>
                            </nts:include>
                            <nts:include value="assert-returnEntryCountAtLeast" scope="project">
                                <nts:with-parameter name="count" value="{$returnEntryCount}"/>
                                <nts:with-parameter name="breakdown" value="{$returnEntryBreakdown}"/>
                            </nts:include>
                        </xsl:when>
                        
                        <xsl:when test="$transactionTypeNormalized = 'serve'">
                            <nts:include value="test.server.search" scope="common" nts:in-targets="#default">
                                <nts:with-parameter name="description" value="Test server to serve {$matchResource} resource(s) representing MP9 building block {$buildingBlockLong}"/>
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="params" value="{$theScenarioParams}"/>
                            </nts:include>
                            <nts:include value="medmij/test.xis.search" scope="common" nts:in-targets="MedMij">
                                <nts:with-parameter name="description" value="Test XIS server to serve {$matchResource} resource(s) representing MP9 building block {$buildingBlockLong}"/>
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="params" value="{$theScenarioParamsMedMij}"/>
                            </nts:include>
                            
                            <nts:include value="assert.response.successfulSearch" scope="common"/>
                            <nts:include value="assert-responseBundleContent-noMM"/>
                            <nts:include value="assert-returnCount" scope="project">
                                <nts:with-parameter name="resource" value="{$matchResource}"/>
                                <nts:with-parameter name="count" value="{$returnCount}"/>
                            </nts:include>
                            <nts:include value="assert-returnEntryCountAtLeast" scope="project">
                                <nts:with-parameter name="count" value="{$returnEntryCount}"/>
                                <nts:with-parameter name="breakdown" value="{$returnEntryBreakdown}"/>
                            </nts:include>
                            
                            <!-- ===== BEGIN: filter-aware, XPath 2.0–only FHIRPath asserts ===== -->
                            <xsl:variable name="paramsString" select="$theScenarioParams"/>
                            <xsl:variable name="hasPou" select="matches($paramsString, 'period-of-use=[a-z]{2}\$\{DATE,\s*T,\s*D,\s*[+-]?\d+\}')"/>
                            
                            <!-- Select ADA primary building-block entries -->
                            <xsl:variable name="adaBouwstenen" select="$adaInstance/medicamenteuze_behandeling/*[not(self::identificatie)]"/>
                            
                            <!-- Extract PoU operator and offset (if present); used only to compute filtered list from ADA macros) -->
                            <xsl:variable name="pouOp" select="replace($paramsString, '.*period-of-use=([a-z]{2}).*', '$1')"/>
                            <xsl:variable name="pouOffsetRaw" select="replace($paramsString, '.*period-of-use=[a-z]{2}\$\{DATE,\s*T,\s*D,\s*([+-]?\d+)\}.*', '$1')"/>
                            
                            <!-- Compute filtered ADA set by comparing macro offsets (if ADA end uses same macro) -->
                            <xsl:variable name="bouwstenenFiltered" as="element()*">
                                <xsl:choose>
                                    <xsl:when test="$hasPou">
                                        <xsl:variable name="rhs" select="xs:integer($pouOffsetRaw)"/>
                                        <xsl:for-each select="$adaBouwstenen">
                                            <xsl:variable name="endVal"
                                                select="(./gebruiksperiode/eind_datum/@value,
                                                        ./gebruiksperiode/einddatum/@value,
                                                        ./gebruiksperiode/@einddatum,
                                                        ./periode/eind_datum/@value)[1]"/>
                                            <xsl:variable name="endValNorm" select="normalize-space($endVal)"/>
                                            <xsl:variable name="isMacro" select="starts-with($endValNorm, '${DATE')"/>
                                            <xsl:variable name="lhsRaw" select="replace($endValNorm, '.*\$\{DATE,\s*T,\s*D,\s*([+-]?\d+)\}.*', '$1')"/>
                                            <xsl:variable name="lhsOk" select="$isMacro and string(number($lhsRaw)) != 'NaN'"/>
                                            <xsl:variable name="lhs" select="if ($lhsOk) then xs:integer($lhsRaw) else 0"/>
                                            
                                            <xsl:variable name="cmpTrue" as="xs:boolean">
                                                <xsl:choose>
                                                    <xsl:when test="$pouOp='lt'"><xsl:sequence select="$lhs lt $rhs"/></xsl:when>
                                                    <xsl:when test="$pouOp='le'"><xsl:sequence select="$lhs le $rhs"/></xsl:when>
                                                    <xsl:when test="$pouOp='gt'"><xsl:sequence select="$lhs gt $rhs"/></xsl:when>
                                                    <xsl:when test="$pouOp='ge'"><xsl:sequence select="$lhs ge $rhs"/></xsl:when>
                                                    <xsl:when test="$pouOp='eq'"><xsl:sequence select="$lhs eq $rhs"/></xsl:when>
                                                    <xsl:when test="$pouOp='ne'"><xsl:sequence select="$lhs ne $rhs"/></xsl:when>
                                                    <xsl:otherwise><xsl:sequence select="true()"/></xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:variable>
                                            
                                            <xsl:if test="(not($isMacro)) or ($lhsOk and $cmpTrue)">
                                                <xsl:sequence select="."/>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:sequence select="$adaBouwstenen"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            
                            <!-- Build filtered identifier set and expected count -->
                            <xsl:variable name="idsFiltered" as="xs:string*" select="$bouwstenenFiltered/identificatie/@value"/>
                            <xsl:variable name="expectedCountFiltered" select="count($idsFiltered)"/>
                            
                            <!-- Build allow-list from all possible identifiers (distinct) -->
                            <xsl:variable name="idsAllowDistinct" as="xs:string*"
                                select="distinct-values($adaInstance/medicamenteuze_behandeling/*/identificatie/@value)"/>
                            
                            <!-- Escape single quotes for FHIRPath literals: replace ' -> '' -->
                            <xsl:variable name="idsFilteredEsc" as="xs:string*"
                                select="for $s in $idsFiltered return replace($s, &quot;'&quot;, &quot;''&quot;)"/>
                            <xsl:variable name="idsAllowEsc" as="xs:string*"
                                select="for $s in $idsAllowDistinct return replace($s, &quot;'&quot;, &quot;''&quot;)"/>
                            
                            <!-- Build HAPI-friendly OR chains instead of set literals -->
                            <xsl:variable name="filteredDisjFP" as="xs:string"
                                select="string-join(for $s in $idsFilteredEsc return concat('v = ''', $s, ''''), ' or ')"/>
                            <xsl:variable name="allowDisjFP" as="xs:string"
                                select="string-join(for $s in $idsAllowEsc return concat('v = ''', $s, ''''), ' or ')"/>

                          
                            
                            <!-- Count bounds (tolerate -1 if PoU present) -->
                            <xsl:variable name="minCount" select="if ($hasPou) then max((0, $expectedCountFiltered - 1)) else $expectedCountFiltered"/>
                            <xsl:variable name="maxCount" select="$expectedCountFiltered"/>                                                                                   
                            
                            <action xmlns="http://hl7.org/fhir">
                                <assert>
                                    <description value="{concat('Returned ', $matchResource, ' count is ', $expectedCountFiltered, if ($hasPou) then ' (period-of-use applied)' else '', '.')}"/>
                                    <direction value="response"/>
                                    <expression value="{concat('Bundle.entry.resource.where($this is ', $matchResource, ').count() = ', $expectedCountFiltered)}"/>
                                    <stopTestOnFail value="false"/>
                                    <warningOnly value="false"/>
                                </assert>
                            </action>
                            
                            <action xmlns="http://hl7.org/fhir">
                                <assert>
                                    <description value="{concat(
                                            'Expect exactly ', $expectedCountFiltered, ' ', $matchResource,
                                            ' resource(s) after applying the period-of-use filter.'
                                        )}"/>
                                    <direction value="response"/>
                                    <expression
                                        value="{concat(
                                            'Bundle.entry.resource.where($this is ', $matchResource,
                                            ' and identifier.value.exists(v | ', $filteredDisjFP, '))',
                                            '.count() = ', $expectedCountFiltered
                                        )}"/>
                                    <stopTestOnFail value="false"/>
                                    <warningOnly value="false"/>
                                </assert>
                            </action>

                            <!-- ===== END: filter-aware asserts ===== -->
                        </xsl:when>
                    </xsl:choose>
                </test>
            </TestScript>
        </xsl:result-document>
    </xsl:template>
    
    <!-- ===== Helpers you already had (unchanged) ===== -->
    
    <xsl:function name="nf:system-dir" as="xs:string">
        <xsl:param name="transactionType" as="xs:string?"/>
        <xsl:variable name="t" select="normalize-space(lower-case($transactionType))"/>
        <xsl:choose>
            <xsl:when test="$t = 'retrieve'">Retrieving-System</xsl:when>
            <xsl:when test="$t = 'serve'">Serving-System</xsl:when>
            <xsl:when test="$t = 'receive'">Receiving-System</xsl:when>
            <xsl:when test="$t = 'send'">Sending-System</xsl:when>
            <xsl:otherwise><xsl:value-of select="nf:first-cap($transactionType)"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="nf:normalize-path" as="xs:string?">
        <xsl:param name="in" as="xs:string?"/>
        <xsl:variable name="fixSlashes" select="replace($in, '\\', '/')"/>
        <xsl:variable name="filePrefix">
            <xsl:choose>
                <xsl:when test="starts-with($fixSlashes, 'file:/')">
                    <xsl:value-of select="$fixSlashes"/>
                </xsl:when>
                <xsl:when test="not(starts-with($fixSlashes, 'file:/')) and starts-with($fixSlashes, '/')">
                    <xsl:value-of select="concat('file://', $fixSlashes)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('file:/', $fixSlashes)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="trailingSlash">
            <xsl:choose>
                <xsl:when test="ends-with($filePrefix, '/')"><xsl:value-of select="$filePrefix"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="concat($filePrefix, '/')"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$trailingSlash"/>
    </xsl:function>
    
    <xsl:function name="nf:first-cap" as="xs:string?">
        <xsl:param name="in" as="xs:string?"/>
        <xsl:sequence select="concat(upper-case(substring($in, 1, 1)), substring($in, 2))"/>
    </xsl:function>
    
    <xsl:function name="nf:makeBuildingBlockLong" as="xs:string?">
        <xsl:param name="buildingBlockShort" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="contains($buildingBlockShort, 'MA')">MedicationAgreement</xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MGB')">MedicationUse</xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'TA')">AdministrationAgreement</xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MTD')">MedicationAdministration</xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'WDS')">VariableDosingRegimen</xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'VV')">DispenseRequest</xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MVE')">MedicationDispense</xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="util:logMessage">
                    <xsl:with-param name="level" select="$logFATAL"/>
                    <xsl:with-param name="msg">Could not determine building block: <xsl:value-of select="$buildingBlockShort"/></xsl:with-param>
                    <xsl:with-param name="terminate" select="true()"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="nf:matchCategoryCode" as="xs:string?">
        <xsl:param name="buildingBlockShort" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="contains($buildingBlockShort, 'TA')"><xsl:value-of select="$taCode"/></xsl:when>
            <xsl:when test="$buildingBlockShort = 'VV'"><xsl:value-of select="$vvCode"/></xsl:when>
            <xsl:when test="$buildingBlockShort = 'MTD'"><xsl:value-of select="$mtdCode"/></xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MA')"><xsl:value-of select="$maCodeMP920"/></xsl:when>
            <xsl:when test="$buildingBlockShort = 'MVE'"><xsl:value-of select="$mveCode"/></xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MGB')"><xsl:value-of select="$mgbCode"/></xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'WDS')"><xsl:value-of select="$wdsCode"/></xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="nf:matchResource" as="xs:string?">
        <xsl:param name="buildingBlockShort" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="contains($buildingBlockShort, 'TA') or $buildingBlockShort = 'MVE'"><xsl:value-of select="'MedicationDispense'"/></xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MA') or contains($buildingBlockShort, 'WDS') or $buildingBlockShort = ('VV')"><xsl:value-of select="'MedicationRequest'"/></xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MGB')"><xsl:value-of select="'MedicationStatement'"/></xsl:when>
            <xsl:when test="$buildingBlockShort = 'MTD'"><xsl:value-of select="'MedicationAdministration'"/></xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <!-- copy mode for passthrough -->
    <xsl:template match="@* | node()" mode="copy">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="copy"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>
