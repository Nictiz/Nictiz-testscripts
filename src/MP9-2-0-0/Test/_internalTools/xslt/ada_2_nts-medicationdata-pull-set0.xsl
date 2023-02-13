<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:util="urn:hl7:utilities" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:import href="ada_2_nts-medicationdata-pull.xsl"/>
    
    <xsl:output indent="yes" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="outputDir"/>
    
    <xsl:variable name="outputDirNormalized" select="nf:normalize-path($outputDir)"/>
    
    <xd:doc>
        <xd:desc>Start template. Converts a very specific input file (set0-config.xml) that is maintained manually to nts.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:call-template name="util:logMessage">
            <xsl:with-param name="level" select="$logINFO"/>
            <xsl:with-param name="msg">Processing ScenarioSet0</xsl:with-param>
        </xsl:call-template>
        
        <!-- We only support this patient at the moment -->
        <xsl:variable name="patientBsn" select="'999901084'"/>
        <!-- Used for MedMij token file -->
        <xsl:variable name="patientName" select="'R-vanXXX-Sonnenberg'"/>
        
        <!-- Transaction Type (Retrieve/Serve) -->
        <xsl:for-each select="ScenarioSet0/*">
            <xsl:variable name="transactionType" select="lower-case(local-name())"/>
            <xsl:variable name="ntsScenario" as="xs:string?">
                <xsl:choose>
                    <xsl:when test="$transactionType = ('retrieve')">client</xsl:when>
                    <xsl:when test="$transactionType = ('serve')">server</xsl:when>
                    <xsl:otherwise>
                        <xsl:message terminate="yes">Unknown transactionType</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:call-template name="util:logMessage">
                <xsl:with-param name="level" select="$logINFO"/>
                <xsl:with-param name="msg">Processing transactionType '<xsl:value-of select="$transactionType"/>'</xsl:with-param>
            </xsl:call-template>
            
            <!-- Building Block -->
            <xsl:for-each select="*">
                <xsl:variable name="buildingBlockLong" select="local-name()"/>
                <xsl:variable name="buildingBlockShort">
                    <xsl:choose>
                        <xsl:when test="$buildingBlockLong = 'MedicationAgreement'">MA</xsl:when>
                        <xsl:when test="$buildingBlockLong = 'MedicationUse'">MGB</xsl:when>
                        <xsl:when test="$buildingBlockLong = 'AdministrationAgreement'">TA</xsl:when>
                        <xsl:when test="$buildingBlockLong = 'DispenseRequest'">VV</xsl:when>
                        <xsl:when test="$buildingBlockLong = 'MedicationAdministration'">MTD</xsl:when>
                        <xsl:when test="$buildingBlockLong = 'MedicationDispense'">MVE</xsl:when>
                        <xsl:when test="$buildingBlockLong = 'VariableDosingRegimen'">WDS</xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="util:logMessage">
                                <xsl:with-param name="level" select="$logFATAL"/>
                                <xsl:with-param name="msg">Could not determine building block: <xsl:value-of select="$buildingBlockLong"/></xsl:with-param>
                                <xsl:with-param name="terminate" select="true()"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="matchResource">
                    <xsl:choose>
                        <xsl:when test="$buildingBlockShort = ('TA', 'MVE')">
                            <xsl:value-of select="'MedicationDispense'"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = ('VV', 'MA', 'WDS')">
                            <xsl:value-of select="'MedicationRequest'"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = 'MGB'">
                            <xsl:value-of select="'MedicationStatement'"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = 'MTD'">
                            <xsl:value-of select="'MedicationAdministration'"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="matchCategoryCode">
                    <xsl:choose>
                        <xsl:when test="$buildingBlockShort = 'TA'">
                            <xsl:value-of select="$taCode"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = 'VV'">
                            <xsl:value-of select="$vvCode"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = 'MTD'">
                            <xsl:value-of select="$mtdCode"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = 'MA'">
                            <xsl:value-of select="$maCodeMP920"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = 'MVE'">
                            <xsl:value-of select="$mveCode"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = 'MGB'">
                            <xsl:value-of select="$mgbCode"/>
                        </xsl:when>
                        <xsl:when test="$buildingBlockShort = 'WDS'">
                            <xsl:value-of select="$wdsCode"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:call-template name="util:logMessage">
                    <xsl:with-param name="level" select="$logINFO"/>
                    <xsl:with-param name="msg">Processing buildingBlock '<xsl:value-of select="$buildingBlockLong"/>'</xsl:with-param>
                </xsl:call-template>
                
                <xsl:for-each select="TestScript">
                    
                    <!-- Should be 0, but I guess you could use this setup for other non-ADA scenario's. -->
                    <xsl:variable name="scenarioset" select="scenarioSet/@value"/>
                    <xsl:variable name="scenario" select="scenario/@value"/>
                    
                    <!-- We should change this to something simpler. Building block and transaction type are already in folder names. Leaving it as is for refactoring purposes -->
                    <xsl:variable name="newFilename" select="concat($buildingBlockShort, '-Scenario', $scenarioset, '-', $scenario, '.xml')"/>
                    
                    <xsl:call-template name="util:logMessage">
                        <xsl:with-param name="level" select="$logINFO"/>
                        <xsl:with-param name="msg">Processing <xsl:value-of select="$newFilename"/></xsl:with-param>
                    </xsl:call-template>
                    
                    <xsl:variable name="additionalScenarioParams" select="params/@value"/>
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
                    
                    <xsl:variable name="description" as="xs:string?" select="description/@value"/>
                    <xsl:variable name="returnCount" select="xs:integer(returnCount/@value)"/>
                    <!-- Huge assumption here, but it seems correct for current scenario's -->
                    <xsl:variable name="returnEntryCount" select="$returnCount * 2"/>
                    <xsl:variable name="returnEntryBreakdown">
                        <xsl:choose>
                            <xsl:when test="$returnEntryCount gt 0">
                                <xsl:value-of select="concat('(Consists of ', $returnCount, ' ', $matchResource, ' and ', $returnCount, ' Medication resources.)')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>(Consists of no resources.)</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:result-document href="{concat($outputDirNormalized,nf:first-cap($transactionType),'/',$buildingBlockLong,'/',$newFilename)}">
                        <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript"  nts:scenario="{$ntsScenario}">
                            <!-- Currently 'include' is used to inject filter-identifier variable. We just copy, NTS handles correct positioning -->
                            <xsl:if test="include/*">
                                <xsl:apply-templates select="include/*" mode="copy"/>
                            </xsl:if>
                            
                            <id value="mp9-{lower-case($buildingBlockShort)}-{$transactionType}-{$scenarioset}-{$scenario}"/>
                            <version value="r4-mp9-2.0.0"/>
                            <name value="Medication Process 9 2.0.0  - {$buildingBlockLong} - {nf:first-cap($transactionType)} - Scenario {$scenarioset}.{$scenario}"/>
                            <description value="Scenario {$scenarioset}.{$scenario} - {$description}"/>
                            <nts:authToken patientResourceId="nl-core-Patient-mp9-{$patientName}" nts:in-targets="MedMij"/>
                            <xsl:if test="contains($additionalScenarioParams, '${DATE, T,')">
                                <nts:includeDateT value="yes"/>
                            </xsl:if>
                            
                            <test id="Scenario-{$scenarioset}-{$scenario}">
                                <name value="Scenario {$scenarioset}.{$scenario}"/>
                                <description value="{$description}"/>
                                <xsl:choose>
                                    <xsl:when test="$transactionType = 'retrieve'">
                                        
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
                                    <xsl:when test="$transactionType = 'serve'">
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
                                            <xsl:with-param name="msg">Different xslt should be called for transactionType: <xsl:value-of select="$transactionType"/></xsl:with-param>
                                            <xsl:with-param name="terminate" select="true()"/>
                                        </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </test>
                        </TestScript>
                    </xsl:result-document>
                </xsl:for-each>
            </xsl:for-each>
            
        </xsl:for-each>
    </xsl:template>
    
    <!-- Remove 'f:' namespace prefix -->
    <xsl:template match="f:*" mode="copy">
        <xsl:element name="{local-name()}" namespace="http://hl7.org/fhir">
            <xsl:apply-templates select="@*|*" mode="#current"/>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>
