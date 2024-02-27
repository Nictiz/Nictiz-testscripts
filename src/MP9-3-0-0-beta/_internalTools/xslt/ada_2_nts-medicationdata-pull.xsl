<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:util="urn:hl7:utilities" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:import href="https://raw.githubusercontent.com/Nictiz/HL7-mappings/master/ada_2_fhir-r4/fhir/2_fhir_fixtures.xsl"/>
    <xsl:import href="ada_2_nts.xsl"/>

    <xsl:output indent="yes" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="*"/>

    <xsl:param name="transactionType"/>
    <xsl:param name="inputDir"/>
    <xsl:param name="outputDir"/>
    <xsl:param name="testGoal" as="xs:string?">
        <xsl:choose>
            <xsl:when test="contains(upper-case($outputDir), 'CERT')">Cert</xsl:when>
            <xsl:otherwise>Test</xsl:otherwise>
        </xsl:choose>
    </xsl:param>

    <xsl:variable name="transactionTypeNormalized" select="normalize-space(lower-case($transactionType))"/>
    <xsl:variable name="inputDirNormalized" select="nf:normalize-path($inputDir)"/>
    <xsl:variable name="outputDirNormalized" select="nf:normalize-path($outputDir)"/>

    <xd:doc>
        <xd:desc>Start template. Handles some ada transactions, converts them to nts. Very specific for each transaction.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:call-template name="util:logMessage">
            <xsl:with-param name="level" select="$logINFO"/>
            <xsl:with-param name="msg">transactionTypeNormalized: <xsl:value-of select="$transactionTypeNormalized"/> - inputDir: <xsl:value-of select="$inputDirNormalized"/> - outputDir: <xsl:value-of select="$outputDirNormalized"/></xsl:with-param>
        </xsl:call-template>

        <!-- ada files have been prepocessed per building block and scenarioset -->
        <xsl:variable name="fileNamePart" as="xs:string">
            <xsl:choose>
                <xsl:when test="$testGoal = 'Cert'">kwal</xsl:when>
                <xsl:otherwise>tst</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:for-each select="collection(concat($inputDirNormalized, '?select=mg-mp-mg-', $fileNamePart, '-*.xml'))">
            <xsl:call-template name="util:logMessage">
                <xsl:with-param name="level" select="$logINFO"/>
                <xsl:with-param name="msg">handling <xsl:value-of select="./adaxml/data/beschikbaarstellen_medicatiegegevens/@id"/></xsl:with-param>
            </xsl:call-template>
            <xsl:variable name="scenarioset" select="xs:integer(replace(./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$1'))"/>

            <xsl:variable name="buildingBlockShort" select="substring-before(substring-after(./adaxml/data/beschikbaarstellen_medicatiegegevens/@id, concat('mg-mp-mg-', $fileNamePart, '-')), '-')[1]" as="xs:string*"/>
            <xsl:call-template name="util:logMessage">
                <xsl:with-param name="level" select="$logINFO"/>
                <xsl:with-param name="msg">buildingBlockShort:  <xsl:value-of select="$buildingBlockShort"/></xsl:with-param>
            </xsl:call-template>
            <xsl:choose>
                <!-- Special handling for scenarioset 0 -->
                <xsl:when test="$scenarioset = 0">
                    <xsl:choose>
                        <xsl:when test="./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value = '0'">
                            <!-- do nothing, filter scenario's are handled using ada_instance_filter folder, those are 0.x format-->                            
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="handleFilterScenario">
                                <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                                <xsl:with-param name="scenarioset" select="$scenarioset"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>                   
                  </xsl:when>
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
            <xsl:variable name="scenarioset" select="xs:integer(replace(./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$1'))"/>
            <xsl:choose>
                <!-- Do nothing for scenarioset 0, handled by manually maintaining nts due to complexities in generating this -->
                <xsl:when test="$scenarioset = 0"/>
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

    <xd:doc>
        <xd:desc>Creates NTS</xd:desc>
        <xd:param name="buildingBlockShort">The building block abbreviation, such as MA, MGB and the like</xd:param>
        <xd:param name="scenarioset">The scenarioset to be converted into nts format</xd:param>
    </xd:doc>
    <xsl:template name="createNts">
        <xsl:param name="buildingBlockShort"/>
        <xsl:param name="scenarioset"/>

        <xsl:variable name="adaInstance" select="adaxml/data/beschikbaarstellen_medicatiegegevens"/>

        <xsl:variable name="buildingBlockLong" select="nf:makeBuildingBlockLong($buildingBlockShort)"/>
        
        <xsl:variable name="scenario">x</xsl:variable>
        <xsl:variable name="newFilename" select="concat($buildingBlockShort, '-Scenarioset', $scenarioset, '.xml')"/>
        <xsl:call-template name="util:logMessage">
            <xsl:with-param name="level" select="$logINFO"/>
            <xsl:with-param name="msg">processing <xsl:value-of select="$newFilename"/></xsl:with-param>
        </xsl:call-template>

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

        <xsl:variable name="theParamParts">
            <xsl:value-of select="concat('category=http://snomed.info/sct|', $matchCategoryCode, '&amp;_include=', $matchResource, ':medication')"/>
        </xsl:variable>
        <xsl:variable name="theScenarioParams" select="concat('?patient.identifier=', $bsnSystem, '|', $patientBsn, '&amp;', $theParamParts)"/>
        <xsl:variable name="theScenarioParamsMedMij" select="concat('?', $theParamParts)"/>

        <xsl:variable name="returnCount" select="count($adaInstance/medicamenteuze_behandeling/*[not(self::identificatie)])"/>
        <xsl:variable name="returnMedicationCount" select="count($adaInstance/bouwstenen/farmaceutisch_product)"/>
        <xsl:variable name="returnEntryCount" select="$returnCount + $returnMedicationCount"/>
        <xsl:variable name="returnEntryBreakdown">
            <xsl:choose>
                <xsl:when test="$returnEntryCount gt 0">
                    <xsl:value-of select="concat('(Consists of ', $returnCount, ' ', $matchResource, ' and ', $returnMedicationCount, ' Medication resources.)')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>(Consists of no resources.)</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="description" as="xs:string?">
            <xsl:choose>
                <xsl:when test="string-length($adaInstance/@title) gt 0 and string-length($adaInstance/@desc) gt 0">
                    <xsl:value-of select="string-join($adaInstance/@title | $adaInstance/@desc, ' - ')"/>
                </xsl:when>
                <xsl:when test="string-length($adaInstance/@title) gt 0">
                    <xsl:value-of select="$adaInstance/@title"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$adaInstance/@desc"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:call-template name="util:logMessage">
            <xsl:with-param name="level" select="$logINFO"/>
            <xsl:with-param name="msg">outputting <xsl:value-of select="$newFilename"/></xsl:with-param>
        </xsl:call-template>
        <xsl:choose>
            <xsl:when test="$transactionTypeNormalized = ('retrieve', 'serve')">
                <xsl:choose>
                    <!--Only the individual Consolidation ada instances (i.e. CONS-MA, CONS-MGB and CONS-TA) need to be converted to a retrieve test script-->
                    <!--For Consolidation there is no serve use case-->
                    <xsl:when test="($transactionTypeNormalized = 'retrieve' and $buildingBlockShort != 'CONS') or ($transactionTypeNormalized = 'serve' and not(contains($buildingBlockShort, 'CONS')))">
                        <xsl:result-document href="{concat($outputDirNormalized,nf:first-cap($transactionTypeNormalized),'/',$buildingBlockLong,'/',$newFilename)}">
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
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="util:logMessage">
                            <xsl:with-param name="level" select="$logINFO"/>
                            <xsl:with-param name="msg">No test script is generated for transactionTypeNormalized: <xsl:value-of select="$transactionTypeNormalized"/> and buildingBlock <xsl:value-of select="$buildingBlockShort"/></xsl:with-param>
                            <xsl:with-param name="terminate" select="false()"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="util:logMessage">
                    <xsl:with-param name="level" select="$logFATAL"/>
                    <xsl:with-param name="msg">Different xslt should be called for transactionTypeNormalized: <xsl:value-of select="$transactionTypeNormalized"/></xsl:with-param>
                    <xsl:with-param name="terminate" select="true()"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xd:doc>
        <xd:desc>Handle filter scenario</xd:desc>
        <xd:param name="buildingBlockShort"/>
        <xd:param name="scenarioset"/>
    </xd:doc>
    <xsl:template name="handleFilterScenario">
        <xsl:param name="buildingBlockShort"/>
        <xsl:param name="scenarioset"/>
        
        <xsl:variable name="adaInstance" select="adaxml/data/beschikbaarstellen_medicatiegegevens"/>
        
        <!-- Should be 0, but I guess you could use this setup for other non-ADA scenario's. -->
        <xsl:variable name="theScenarioSet" select="$scenarioset"/>
        <xsl:variable name="theScenario" select="$adaInstance/scenario-nr/@value"/>
        <xsl:variable name="theScenarioForTestscript" select="replace(nf:removeSpecialCharacters($theScenario), '\.', '-')"/>
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
        
        <!-- We should change this to something simpler. Building block and transaction type are already in folder names. Leaving it as is for refactoring purposes -->
        <xsl:variable name="newFilename" select="concat($buildingBlockShort, '-Scenario', $theScenarioForTestscript, '.xml')"/>

        <xsl:call-template name="util:logMessage">
            <xsl:with-param name="level" select="$logINFO"/>
            <xsl:with-param name="msg">Processing <xsl:value-of select="$newFilename"/></xsl:with-param>
        </xsl:call-template>
        
        <xsl:variable name="set0config" select="document('set0-config.xml')"/>
        <xsl:variable name="configCurrentScenario" select="$set0config//*[local-name() = $testGoal]/*[local-name() = nf:first-cap($transactionTypeNormalized)]/*[local-name() = $buildingBlockLong]/TestScript[scenarioFullNumber/@value = $theScenario]"/>
        
        <xsl:variable name="additionalScenarioParams" select="$configCurrentScenario/params/@value" as="xs:string?"/>
        <xsl:variable name="theParamParts">
            <xsl:variable name="additionalScenarioParamsNormalized">
                <xsl:choose>
                    <xsl:when test="starts-with($additionalScenarioParams, '&amp;amp;') or string-length($additionalScenarioParams) = 0">
                        <xsl:value-of select="$additionalScenarioParams"/>
                    </xsl:when>
                    <xsl:when test="starts-with($additionalScenarioParams, '&amp;')">
                        <xsl:value-of select="concat('&amp;',substring-after($additionalScenarioParams, '&amp;'))"/>
                    </xsl:when>
                    <xsl:when test="starts-with($additionalScenarioParams, '?')">
                        <xsl:value-of select="concat('&amp;',substring-after($additionalScenarioParams, '?'))"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="concat('category=http://snomed.info/sct|', $matchCategoryCode, replace($additionalScenarioParams, '&amp;', '&amp;'), '&amp;_include=', $matchResource, ':medication')"/>
        </xsl:variable>
        <xsl:variable name="theScenarioParams" select="concat('?patient.identifier=', $bsnSystem, '|', $patientBsn, '&amp;', $theParamParts)"/>
        <xsl:variable name="theScenarioParamsMedMij" select="concat('?', $theParamParts)"/>

        <xsl:variable name="description" as="xs:string?" select="$adaInstance/@desc"/>
        <xsl:variable name="returnCount" select="count($adaInstance/medicamenteuze_behandeling/*[not(self::identificatie)])"/>
        <!-- We add the medication products, since those are in an include in the query -->
        <xsl:variable name="returnEntryCount" select="$returnCount + count($adaInstance/bouwstenen/farmaceutisch_product)"/>
        <xsl:variable name="returnEntryBreakdown">
            <xsl:choose>
                <xsl:when test="$returnEntryCount gt 0">
                    <xsl:value-of select="concat('(Consists of ', $returnCount, ' ', $matchResource, ' and ', count($adaInstance/bouwstenen/farmaceutisch_product), ' Medication resources.)')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>(Consists of no resources.)</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:result-document href="{concat($outputDirNormalized,nf:first-cap($transactionType),'/',$buildingBlockLong,'/',$newFilename)}">
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
                <!-- Currently 'include' is used to inject filter-identifier variable. We just copy, NTS handles correct positioning -->
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
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="util:logMessage">
                                <xsl:with-param name="level" select="$logFATAL"/>
                                <xsl:with-param name="msg">Different xslt should be called for $transactionTypeNormalized: <xsl:value-of select="$transactionTypeNormalized"/></xsl:with-param>
                                <xsl:with-param name="terminate" select="true()"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </test>
            </TestScript>
        </xsl:result-document>

    </xsl:template>

    <xd:doc>
        <xd:desc>Normalize a filepath</xd:desc>
        <xd:param name="in">The string to be handled</xd:param>
    </xd:doc>
    <xsl:function name="nf:normalize-path" as="xs:string?">
        <xsl:param name="in" as="xs:string?"/>
        <xsl:variable name="fixSlashes" select="replace($in, '\\', '/')"/>
        <xsl:variable name="filePrefix">
            <xsl:choose>
                <xsl:when test="starts-with($fixSlashes, 'file:/')">
                    <xsl:value-of select="$fixSlashes"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('file:/', $fixSlashes)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="trailingSlash">
            <xsl:choose>
                <xsl:when test="ends-with($filePrefix, '/')">
                    <xsl:value-of select="$filePrefix"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($filePrefix, '/')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$trailingSlash"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>Make long building block string based on short building block string</xd:desc>
        <xd:param name="buildingBlockShort">short building block string: MA/WDS/VV/TA/MVE/MGB/MTD</xd:param>
    </xd:doc>
    <xsl:function name="nf:makeBuildingBlockLong" as="xs:string?">
        <xsl:param name="buildingBlockShort" as="xs:string?"/>

        <xsl:choose>
            <!-- consolidation buildingBlockShort is a string like "CONS-MA" -->
            <xsl:when test="contains($buildingBlockShort, 'MA')">MedicationAgreement</xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MGB')">MedicationUse</xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'TA')">AdministrationAgreement</xsl:when>
            <xsl:when test="$buildingBlockShort = 'VV'">DispenseRequest</xsl:when>
            <xsl:when test="$buildingBlockShort = 'MTD'">MedicationAdministration</xsl:when>
            <xsl:when test="$buildingBlockShort = 'MVE'">MedicationDispense</xsl:when>
            <xsl:when test="$buildingBlockShort = 'WDS'">VariableDosingRegimen</xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="util:logMessage">
                    <xsl:with-param name="level" select="$logFATAL"/>
                    <xsl:with-param name="msg">Could not determine building block: <xsl:value-of select="$buildingBlockShort"/></xsl:with-param>
                    <xsl:with-param name="terminate" select="true()"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>
    
    <xd:doc>
        <xd:desc>Match FHIR Category code based on short building block string</xd:desc>
        <xd:param name="buildingBlockShort">short building block string: MA/WDS/VV/TA/MVE/MGB/MTD</xd:param>
    </xd:doc>
    <xsl:function name="nf:matchCategoryCode" as="xs:string?">
        <xsl:param name="buildingBlockShort" as="xs:string?"/>
        
        <xsl:choose>
            <xsl:when test="contains($buildingBlockShort, 'TA')">
                <xsl:value-of select="$taCode"/>
            </xsl:when>
            <xsl:when test="$buildingBlockShort = 'VV'">
                <xsl:value-of select="$vvCode"/>
            </xsl:when>
            <xsl:when test="$buildingBlockShort = 'MTD'">
                <xsl:value-of select="$mtdCode"/>
            </xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MA')">
                <xsl:value-of select="$maCodeMP920"/>
            </xsl:when>
            <xsl:when test="$buildingBlockShort = 'MVE'">
                <xsl:value-of select="$mveCode"/>
            </xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MGB')">
                <xsl:value-of select="$mgbCode"/>
            </xsl:when>
            <xsl:when test="$buildingBlockShort = 'WDS'">
                <xsl:value-of select="$wdsCode"/>
            </xsl:when>
        </xsl:choose>
        
    </xsl:function>

    <xd:doc>
        <xd:desc>Match FHIR Resource based on short building block string</xd:desc>
        <xd:param name="buildingBlockShort">short building block string: MA/WDS/VV/TA/MVE/MGB/MTD</xd:param>
    </xd:doc>
    <xsl:function name="nf:matchResource" as="xs:string?">
        <xsl:param name="buildingBlockShort" as="xs:string?"/>
        
        <xsl:choose>
            <xsl:when test="contains($buildingBlockShort, 'TA') or $buildingBlockShort = 'MVE'">
                <xsl:value-of select="'MedicationDispense'"/>
            </xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MA') or $buildingBlockShort = ('VV', 'WDS')">
                <xsl:value-of select="'MedicationRequest'"/>
            </xsl:when>
            <xsl:when test="contains($buildingBlockShort, 'MGB')">
                <xsl:value-of select="'MedicationStatement'"/>
            </xsl:when>
            <xsl:when test="$buildingBlockShort = 'MTD'">
                <xsl:value-of select="'MedicationAdministration'"/>
            </xsl:when>
        </xsl:choose>
        
    </xsl:function>

</xsl:stylesheet>
