<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:util="urn:hl7:utilities" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <!--Import mp specific constants (and package for underlying imports)-->
    <xsl:import href="../../../../../YATC-internal/ada-2-fhir-r4/env/mp/9.3.0/payload/mp9_latest_package.xsl"/>
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
    
    <xsl:strip-space elements="*"/>
    
    <!--    <xsl:param name="mappingsUrl4FhirFixtures">https://raw.githubusercontent.com/Nictiz/HL7-mappings/master/ada_2_fhir-r4/mp/9.3.0/touchstone/test/4touchstone_mp</xsl:param>-->
    <xsl:param name="mappingsUrl4FhirFixtures">../../../../../HL7-mappings/master/ada_2_fhir-r4/mp/9.3.0/touchstone/test/4touchstone_mp</xsl:param>
    
    <!-- Send/Receive/Retrieve/Serve, this param defaults to Send -->
    <xsl:param name="transactionType">Send</xsl:param>
    <xsl:param name="outputDir"/>
    <xsl:variable name="outputDirNormalized" select="nf:normalize-path($outputDir)"/>
    
    <xsl:variable name="bsnSystem" select="$oidMap[@oid = $oidBurgerservicenummer]/@uri"/>
    <xsl:variable name="cleanupVars" as="element()">
        <variable xmlns="http://hl7.org/fhir">
            <name value="patient-id"/>
            <sourceId value="transaction-response"/>
            <expression value="entry.response.location.where($this.startsWith('Patient/')).first().split('/')[1]"/>
        </variable>
    </xsl:variable>
    <xd:doc>
        <xd:desc>Start template. Handles ada test instances, converts them to nts.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:variable name="adaTransaction" select="adaxml/data/*" as="element()*"/>
        
        <xsl:for-each select="$adaTransaction">
            <!-- find corresponding FHIR fixture based on adaId -->
            <xsl:variable name="adaTransId" select="nf:removeSpecialCharacters(@id)"/>
            <xsl:variable name="adaTransIdFile" select="replace($adaTransId, '\.', '-')"/>           
            <!-- extract concise filename so the end user can distinguish between different scripts  -->
            <xsl:variable name="fileName" select="replace($adaTransId,'.+(tst|kwal)-(.+)-v30', '$2')"/>       
            <xsl:variable name="testGoal">
                <xsl:choose>
                    <xsl:when test="replace($adaTransId,'.+(tst|kwal)-(.+)-v30', '$1') = 'kwal'">Cert</xsl:when>
                    <xsl:otherwise>Test</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="fhirFixture" select="document(concat($mappingsUrl4FhirFixtures, '/', $adaTransIdFile, '.xml'))"/>
            <xsl:variable name="fixturePatient" select="$fhirFixture//f:Patient[1]"/>
            
            <xsl:variable name="ntsScenario" as="xs:string?">
                <xsl:choose>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = ('RETRIEVE', 'SEND')">client</xsl:when>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = ('SERVE', 'RECEIVE')">server</xsl:when>
                    <xsl:otherwise>unknown</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="testScriptString" as="element(testscriptstring)*">
                <xsl:call-template name="getTestScriptString"/>
            </xsl:variable>
            <xsl:variable name="scenarioString" as="element(scenarioString)">
                <xsl:call-template name="getScenarioString"/>
            </xsl:variable>
            
            <xsl:variable name="direction">
                <xsl:choose>
                    <xsl:when
                        test="normalize-space(upper-case($transactionType)) = ('RETRIEVE', 'SEND')"
                        >request</xsl:when>
                    <xsl:when
                        test="normalize-space(upper-case($transactionType)) = ('SERVE', 'RECEIVE')"
                        >response</xsl:when>
                </xsl:choose>
            </xsl:variable>
            <!-- In Send scripts, the request is being validated. In Receive scripts, the response is being validated (mainly because the FHIR spec is not really clear about what servers can or cannot edit before storing a resource). In both these cases, we add an assert to check for each resource that we expect. Next to that, this script is prepared to also add a variable for each resource, so that we can use this variable in the future to add content asserts for each resource -->
            <xsl:variable name="identifyResources" as="element()*">
                <!-- We use fhir as source instead of ada to be able to make the mapping between fhir and fhirpath easier (mainly the handling of PharmaceuticalProduct to FHIR Medication requires this)
                     At the moment, the generated fixture is used. Perhaps it would be better to use ada as input and call ada2fhir dynamically.  -->
                <xsl:variable name="medicationGroup"
                    select="$fhirFixture/f:Bundle/f:entry/f:resource/f:Medication"/>
                <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*"
                    group-by="local-name()">
                    <xsl:choose>
                        <!-- only check the primary resources and Medication, it is not obliged to send along the secondary resources -->
                        <xsl:when
                            test="current-grouping-key() = ('MedicationAdministration', 'MedicationDispense', 'MedicationRequest', 'MedicationStatement')">
                            <xsl:variable name="resourceType" select="current-grouping-key()"/>
                            <!-- We  do not include mpBouwsteenBaseContext because the category code is included in all search queries. This might change though -->
                            <xsl:variable name="mpBouwsteenBaseContext"
                                select="concat('Bundle.entry.resource.where($this is ', $resourceType, ')')"/>
                            
                            <xsl:for-each-group select="current-group()"
                                group-by="f:category/f:coding/f:code/@value">
                                <xsl:variable name="categoryCode" select="current-grouping-key()"/>
                                <xsl:variable name="allMPBouwstenenOfSameKind"
                                    select="current-group()"/>
                                
                                <xsl:for-each select="$allMPBouwstenenOfSameKind">
                                    <xsl:variable name="currentMPBouwsteen" select="."/>
                                    <xsl:variable name="medicationReference"
                                        select="$currentMPBouwsteen/f:medicationReference/f:reference/@value"/>
                                    <xsl:variable name="resolvedMedication"
                                        select="$fhirFixture/f:Bundle/f:entry[f:fullUrl/@value = $medicationReference]/f:resource/f:Medication"/>
                                    <xsl:variable name="medication-code"
                                        select="distinct-values($resolvedMedication/f:code/f:coding/f:code/@value)"/>
                                    <xsl:variable name="ingredient-code"
                                        select="distinct-values($resolvedMedication/f:ingredient/f:itemCodeableConcept/f:coding/f:code/@value)"/>
                                    
                                    <!-- TODO: Add exception for 90million -->
                                    <xsl:variable name="mpBouwstenenSameProduct" as="element()*">
                                        <xsl:choose>
                                            <xsl:when test="count($medication-code) = 0">
                                                <xsl:sequence select="$allMPBouwstenenOfSameKind"/>
                                            </xsl:when>
                                            <xsl:when
                                                test="count($medication-code) = 1 and $medication-code = 'OTH'">
                                                <xsl:for-each select="$allMPBouwstenenOfSameKind">
                                                    <xsl:variable name="medicationReference"
                                                        select="f:medicationReference/f:reference/@value"/>
                                                    <xsl:if
                                                        test="$fhirFixture/f:Bundle/f:entry[f:fullUrl/@value = $medicationReference]/f:resource/f:Medication[f:code/f:coding/f:code/@value = $medication-code and f:ingredient/f:itemCodeableConcept/f:coding/f:code/@value = $ingredient-code]">
                                                        <xsl:sequence select="."/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:for-each select="$allMPBouwstenenOfSameKind">
                                                    <xsl:variable name="medicationReference"
                                                        select="f:medicationReference/f:reference/@value"/>
                                                    <xsl:if test="
                                                        $fhirFixture/f:Bundle/f:entry[f:fullUrl/@value = $medicationReference]/f:resource/f:Medication/f:code[every $code in $medication-code
                                                            satisfies f:coding/f:code/@value = $code]">
                                                        <xsl:sequence select="."/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    
                                    <!-- Count how many MedicationRequests in this group point to an OTH Medication -->
                                    <xsl:variable name="othCount"
                                        select="
                                            count(
                                                $allMPBouwstenenOfSameKind[
                                                    let $ref := f:medicationReference/f:reference/@value
                                                    return boolean(
                                                            $fhirFixture/f:Bundle/f:entry[f:fullUrl/@value = $ref]
                                                            /f:resource/f:Medication
                                                            /f:code/f:coding[
                                                                f:system/@value = 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'
                                                                and f:code/@value = 'OTH'
                                                            ]
                                                        )
                                                ]
                                            )
                                        "/>
                                    <xsl:variable name="isOTH" select="count($medication-code) = 1 and $medication-code = 'OTH'"/>
                                    <xsl:variable name="expression">
                                        <xsl:value-of select="$mpBouwsteenBaseContext"/>
                                        <xsl:text>.where(</xsl:text>
                                        
                                        <xsl:choose>
                                            <!-- OTH branch: only check OTH code on medication, no ingredient predicates -->
                                            <xsl:when test="$isOTH">
                                                <xsl:text>((medication.where($this is CodeableConcept).coding | medication.where($this is Reference).resolve().code.coding).exists(system = 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor' and code = 'OTH'))</xsl:text>
                                            </xsl:when>
                                            
                                            <!-- Non-OTH branch: your existing per-code checks -->
                                            <xsl:otherwise>
                                                <xsl:text>(</xsl:text>
                                                <xsl:for-each select="$medication-code">
                                                    <xsl:text>( (medication.where($this is CodeableConcept).coding | medication.where($this is Reference).resolve().code.coding).exists(code = '</xsl:text>
                                                    <xsl:value-of select="."/>
                                                    <xsl:text>') )</xsl:text>
                                                    <xsl:if test="position() != last()">
                                                        <xsl:text> and </xsl:text>
                                                    </xsl:if>
                                                </xsl:for-each>
                                                <xsl:text>)</xsl:text>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        
                                        <xsl:text>)</xsl:text> <!-- close .where( … ) -->
                                        
                                        <!-- Only append disambiguators for non-OTH; for OTH we want the full group -->
                                        <xsl:if test="not($isOTH)">
                                            <xsl:call-template name="append-2-context">
                                                <xsl:with-param name="categoryCode" select="$categoryCode"/>
                                                <xsl:with-param name="currentMPBouwsteen" select="$currentMPBouwsteen"/>
                                                <xsl:with-param name="mpBouwstenenSameProduct" select="$mpBouwstenenSameProduct"/>
                                            </xsl:call-template>
                                        </xsl:if>
                                        
                                        <!-- Compare against the right expected count -->
                                        <xsl:value-of select="
                                            concat('.count() = ',
                                                if ($isOTH)
                                                    then $othCount
                                                else count($mpBouwstenenSameProduct)
                                            )
                                                        "/>
                                    </xsl:variable>
                                    
                                    <action xmlns="http://hl7.org/fhir">
                                        <assert>
                                            <!--<description value="{$description}"/>-->
                                            <direction>
                                                <xsl:attribute name="value">                                                   
                                                    <xsl:value-of select="'request'"/>                                                       
                                                </xsl:attribute>    
                                            </direction>
                                            <expression value="{$expression}"/>
                                            <sourceId value="transaction-{$direction}"/>
                                            <warningOnly value="false"/>
                                        </assert>
                                    </action>
                                </xsl:for-each>
                            </xsl:for-each-group>
                        </xsl:when>
                        <xsl:when test="current-grouping-key() = 'Medication'">
                            <xsl:for-each-group select="current-group()"
                                group-by="concat((f:code/f:coding[f:userSelected/@value = 'true'], f:code/f:coding[1])[1]/f:code/@value, '|', (f:code/f:coding[f:userSelected/@value = 'true'], f:code/f:coding[1])[1]/f:system/@value)">
                                <xsl:variable name="resourceCount" select="count(current-group())"/>
                                
                                <xsl:variable name="medicationCoding"
                                    select="(f:code/f:coding[f:userSelected/@value = 'true'], f:code/f:coding[1])[1]"/>
                                <xsl:variable name="medicationCode"
                                    select="$medicationCoding/f:code/@value"/>
                                <xsl:variable name="medicationSystem"
                                    select="$medicationCoding/f:system/@value"/>
                                <xsl:variable name="medicationDisplay"
                                    select="$medicationCoding/f:display/@value"/>
                                <!-- First we check if the userSelected (or if userSelected is absent just the first) coding is unique within the Medication group. If not, we are going to use the complete CodeableConcept to generate an expression -->
                                <xsl:variable name="useUserSelected">
                                    <xsl:variable name="medicationCoding"/>
                                    <xsl:choose>
                                        <!-- Exception for OTH for now -->
                                        <xsl:when
                                            test="count($medicationGroup/f:code/f:coding[f:code/@value = $medicationCode and f:system/@value = $medicationSystem]) gt 1 and not($medicationCode = 'OTH')">
                                            <xsl:value-of select="false()"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="true()"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                
                                <xsl:variable name="expression">
                                    <xsl:value-of
                                        select="'Bundle.entry.resource.where($this is Medication).where(code'"/>
                                    <xsl:choose>
                                        <xsl:when test="$useUserSelected = true()">
                                            <xsl:value-of
                                                select="concat('.coding.exists(system = ''', $medicationSystem, ''' and code = ''', $medicationCode, ''')')"
                                                />
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of
                                                select="concat('.where(coding.count() = ', count(f:code/f:coding), ' and ')"/>
                                            <xsl:for-each select="f:code/f:coding">
                                                <xsl:value-of
                                                    select="concat('coding.exists(system = ''', f:system/@value, ''' and code = ''', f:code/@value, ''')')"/>
                                                <xsl:if test="not(position() = last())">
                                                    <xsl:value-of select="' and '"/>
                                                </xsl:if>
                                            </xsl:for-each>
                                            <xsl:value-of select="')'"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="concat(').count() = ', $resourceCount)"/>
                                </xsl:variable>
                                
                                <action xmlns="http://hl7.org/fhir">
                                    <assert>
                                        <description
                                            value="Confirm that the {$direction} Bundle contains {$resourceCount} Medication resource that contains code '{$medicationCode}|{$medicationSystem}' ({$medicationDisplay})"/>
                                        <direction>
                                            <xsl:attribute name="value">                                                   
                                                <xsl:value-of select="'request'"/>                                                       
                                            </xsl:attribute>    
                                        </direction>
                                        
                                        <expression value="{$expression}"/>
                                        <sourceId value="transaction-{$direction}"/>
                                        <warningOnly value="false"/>
                                    </assert>
                                </action>
                                <!--<variable>
                                     <name value="{current-grouping-key()}-{position()}"/>
                                     <expression value="Bundle.entry.select(resource as {current-grouping-key()}).where(medication.resolve().code.coding.where(system = '{$medicationSystem}' and code = '{$medicationCode}')).id"/>
                                     <sourceId value="search-response"/>
                                     </variable>-->
                             </xsl:for-each-group>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each-group>
            </xsl:variable>
            <xsl:variable name="fileNamePart" as="xs:string">
                <xsl:choose>
                    <xsl:when test="$testGoal = 'Cert'">kwal</xsl:when>
                    <xsl:otherwise>tst</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <!-- Check if buildingBlockShort really is a building block, if not we catch a bigger part of the filename to account for stuff like 'script1' and 'script1-wijziging' (which may include hyphens)
                 However, sometimes this 'extra stuff' is still preceded by a legit 'scenario-subscenario', so we want to filter that out -->
            <xsl:variable name="buildingBlockShort" as="xs:string*">
                <xsl:variable name="attempt1" select="substring-before(substring-after($adaTransId, concat($fileNamePart, '-')), '-')[1]"/>
                <xsl:variable name="attempt2" select="substring-before(substring-after($adaTransId, concat($fileNamePart, '-', $scenarioString/@theScenarioHyphen,'-')), '-v30')[1]"/>
                <xsl:variable name="attempt3" select="substring-before(substring-after($adaTransId, concat($fileNamePart, '-')), '-v30')[1]"/>
                <xsl:choose>
                    
                    <xsl:when test="$attempt1 = ('VV','MTD','MA','MVE','MGB','TA','WDS')">
                        <xsl:value-of select="$attempt1"/>
                    </xsl:when>
                    <xsl:when test="starts-with($attempt3, concat($scenarioString/@theScenarioHyphen,'-'))">
                        <xsl:value-of select="$attempt2"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$attempt3"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="idString">
                <xsl:call-template name="getIdString">
                    <xsl:with-param name="testGoal" select="$testGoal"/>
                    <xsl:with-param name="short" select="$testScriptString/@short"/>
                    <xsl:with-param name="buildingBlockShort">
                        <xsl:choose>
                            <!-- Filter 'script[digit]' from the id -->
                            <xsl:when test="matches($buildingBlockShort, '^script\d{1,2}(-)?')">
                                <xsl:value-of select="replace($buildingBlockShort,'^script\d{1,2}(-)?','')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$buildingBlockShort"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                    <xsl:with-param name="transactionType" select="$transactionType"/>
                    <xsl:with-param name="theScenario0XHyphen" select="$scenarioString/@theScenario0XHyphen"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:variable name="titleSuffix" as="xs:string?">
                <xsl:if test="not($buildingBlockShort = ('VV','MTD','MA','MVE','MGB','TA','WDS'))">
                    <xsl:choose>
                        <!-- Filter 'script[digit]' from the title -->
                        <xsl:when test="matches($buildingBlockShort, '^script\d{1,2}(-)?')">
                            <xsl:value-of select="replace($buildingBlockShort,'^script\d{1,2}(-)?','')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$buildingBlockShort"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:variable>
            
            <xsl:variable name="testScriptTitle">
                <xsl:call-template name="getTestScriptTitle">
                    <xsl:with-param name="theScenarioX" select="$scenarioString/@theScenarioX"/>
                    <xsl:with-param name="titleSuffix" select="$titleSuffix"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:variable name="testScriptDescription">
                <xsl:call-template name="getTestScriptDescription">
                    <xsl:with-param name="transactionType" select="$transactionType"/>
                    <xsl:with-param name="full" select="$testScriptString/@full"/>
                    <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                    <xsl:with-param name="patient" select="$fixturePatient/f:name/f:text/@value"/>
                    <xsl:with-param name="adaDescription" select="@desc"/>
                    <xsl:with-param name="adaTitle" select="@title"/>
                    <xsl:with-param name="testGoal" select="$testGoal"/>
                    <xsl:with-param name="wiki" select="$testScriptString/@wiki"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:variable name="testName">
                <xsl:call-template name="getTestName">
                    <xsl:with-param name="theScenarioX" select="$scenarioString/@theScenarioX"/>
                    <xsl:with-param name="fallback" select="$buildingBlockShort"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:variable name="testDescription">
                <xsl:call-template name="getTestDescription">
                    <xsl:with-param name="transactionType" select="$transactionType"/>
                    <xsl:with-param name="full" select="$testScriptString/@full"/>
                    <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                </xsl:call-template>
            </xsl:variable>
            
            <xsl:variable name="newFilename" select="concat($idString, '.xml')"/>
            <xsl:call-template name="util:logMessage">
                <xsl:with-param name="level" select="$logINFO"/>
                <xsl:with-param name="msg">processing <xsl:value-of select="$newFilename"/></xsl:with-param>
            </xsl:call-template>
            
            <xsl:choose>
                <!-- pull beschikbaarstellen_medicatiegegevens -->
                <xsl:when test="self::beschikbaarstellen_medicatiegegevens and normalize-space(upper-case($transactionType)) = ('RETRIEVE', 'SERVE')">
                    <xsl:call-template name="util:logMessage">
                        <xsl:with-param name="level" select="$logERROR"/>
                        <xsl:with-param name="msg">Pull medication data should call a separate XSLT</xsl:with-param>
                        <xsl:with-param name="terminate" select="true()"/>
                    </xsl:call-template>
                </xsl:when>
                
                <!-- push all transactions -->
                <xsl:when test="normalize-space(upper-case($transactionType)) = ('SEND', 'RECEIVE')">
                    <!-- variable to prepare TestScript variable and accompanying delete/purge actions for cleanup of push stuff -->
                    <!--<xsl:variable name="deleteStuff" as="element()">
                         <deleteStuff xmlns="http://hl7.org/fhir">
                         <variable>
                         <name value="patient-id"/>
                         <expression value="(Bundle.entry.resource as Patient).id"/>
                         <sourceId value="transaction-response-fixture"/>
                         </variable>
                         <!-\- for each resource type in the request bundle, for each resource from that type 
                         create a variable to store the id from the response Bundle and a corresponding delete action -\->
                         <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/*" group-by="local-name()">
                         <xsl:for-each select="current-group()">
                         <xsl:variable name="varName" select="concat(current-grouping-key(), '-', position())"/>
                         <variable>
                         <name value="{$varName}"/>
                         <expression value="(Bundle.entry.resource as {current-grouping-key()}).id[{position()-1}]"/>
                         <sourceId value="transaction-response-fixture"/>
                         </variable>
                         <action>
                         <operation>
                         <type>
                         <system value="http://terminology.hl7.org/CodeSystem/testscript-operation-codes"/>
                         <code value="delete"/>
                         </type>
                         <resource value="{current-grouping-key()}"/>
                         <encodeRequestUrl value="true"/>
                         <params value="{concat('${', $varName, '}')}"/>
                         </operation>
                         </action>
                         </xsl:for-each>
                         </xsl:for-each-group>
                         </deleteStuff>
                         </xsl:variable>-->
                    
                    <xsl:variable name="includeNumResources" as="element()*">
                        <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                            <xsl:choose>
                                <!-- only count the primary resources and Medication, it is not obliged to send along the secondary resources -->
                                <xsl:when test="current-grouping-key() = ('MedicationRequest', 'MedicationDispense', 'MedicationStatement', 'MedicationAdministration', 'Medication')">
                                    <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                </xsl:when>
                                <!-- but for our own materials we'll check the others as well just to be sure - for 'legacy reasons' only when receiving, should be also for sending? -->
                                <!--<xsl:when test="normalize-space(upper-case($transactionType)) = 'RECEIVE'">
                                     <xsl:choose>
                                     <!-\- Exception for Lab -\->
                                     <xsl:when test="$testScriptString/@short = 'prescr' and $scenarioset = '4' and $scenario = ('2a','2b') and current-grouping-key() = 'Organization'">
                                     <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group()) + 1}" nts:in-targets="Nictiz-intern"/>
                                     </xsl:when>
                                     <xsl:otherwise>
                                     <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}" nts:in-targets="Nictiz-intern"/>
                                     </xsl:otherwise>
                                     </xsl:choose>
                                     </xsl:when>-->
                             </xsl:choose>
                        </xsl:for-each-group>
                    </xsl:variable>
                    
                    <xsl:result-document href="{concat($outputDirNormalized, '/', $newFilename)}">
                        <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                            <id value="{$idString}"/>
                            <version value="r4-mp9-3.0.0"/>
                            <name value="{$idString}"/>
                            <title value="{$testScriptTitle}"/>
                            <description value="{$testScriptDescription}"/>                            
                            <xsl:choose>
                                <!-- Receive -->
                                <xsl:when test="$ntsScenario = 'server'">
                                    <nts:fixture id="{$adaTransIdFile}" href="fixtures/{$adaTransIdFile}.{'{$_FORMAT}'}"/>
                                    <nts:includeDateT value="yes"/>
                                    <!--<xsl:apply-templates select="$deleteStuff/f:variable" mode="Nictiz-intern"/>-->
                                    <test id="{$idString}-01">
                                        <name value="{$testName}"/>
                                        <description value="{$testDescription}"/>
                                        <action>
                                            <operation>
                                                <type>
                                                    <system value="http://terminology.hl7.org/CodeSystem/testscript-operation-codes"/>
                                                    <code value="transaction"/>
                                                </type>
                                                <description value="Test server to handle a Bundle of type transaction."/>
                                                <contentType value="{'{$_FORMAT}'}"/>
                                                <destination value="1"/>
                                                <origin value="1"/>
                                                <requestHeader>
                                                    <field value="Prefer"/>
                                                    <value value="return=representation"/>
                                                </requestHeader>
                                                <!--<responseId value="transaction-response-fixture" nts:in-targets="Nictiz-intern"/>-->
                                                <sourceId value="{$adaTransIdFile}"/>
                                            </operation>
                                        </action>
                                        <nts:include value="assert.response.success" scope="common"/>
                                        <nts:include value="assert.response.bundleContent" scope="common" bundleType="transaction-response"/>
                                        <xsl:copy-of select="$includeNumResources"/>
                                    </test>
                                    <!-- teardown receive only needed for Nictiz internal tests -->
                                    <!--<teardown nts:in-targets="Nictiz-intern">
                                         <!-\- the individual deletes, so we can also get rid of non-patient related resources, such as PractitionerRole/Practitioner/Organization and the like -\->
                                         <xsl:copy-of select="$deleteStuff/f:action"/>
                                         </teardown>-->
                                    <xsl:if test="count($identifyResources) gt 0">
                                        <test id="{$idString}-identification">
                                            <name value="Resource identification"/>
                                            <description
                                                value="Checks if all resources specified by the scenario can be identified unambiguously."/>
                                            <xsl:copy-of select="$identifyResources"/>
                                        </test>
                                    </xsl:if>
                                 </xsl:when>
                                <xsl:otherwise> 
                                    <xsl:copy-of select="$cleanupVars"/>    
                                    <!-- assume Send -->
                                    <!-- 1) Fixture ZONDER in-targets: altijd beschikbaar voor response capture + teardown -->
                                    <nts:fixture id="{concat($adaTransIdFile,'-all')}" href="fixtures/{$adaTransIdFile}.xml"/>
                                    
                                    <!-- 2) Eventueel: behoud je intern-only fixture als je ’m nog nodig hebt -->
                                    <nts:fixture id="{$adaTransIdFile}" href="fixtures/{$adaTransIdFile}.xml" nts:in-targets="Nictiz-intern"/>
                                    
                                    <nts:includeDateT value="yes" nts:in-targets="Nictiz-intern"/>
                                    <!--<xsl:copy-of select="$deleteStuff/f:variable"/>-->
                                    <test id="{$idString}-01">
                                        <name value="{$testName}"/>
                                        <description value="{$testDescription}"/>
                                        <action>
                                            <operation>
                                                <type>
                                                    <system value="http://terminology.hl7.org/CodeSystem/testscript-operation-codes"/>
                                                    <code value="transaction"/>
                                                </type>
                                                <description value="Test client to POST a Bundle of type transaction."/>
                                                <destination value="1"/>
                                                <origin value="1"/>
                                                <responseId value="transaction-response"/>
                                                <sourceId value="{concat($adaTransIdFile,'-all')}"/>
                                            </operation>
                                        </action>
                                        <nts:include value="test.client.successfulTransaction" scope="common"/>
                                        <xsl:copy-of select="$includeNumResources"/>
                                    </test>
                                    <xsl:if test="count($identifyResources) gt 0">
                                        <test id="{$idString}-identification">
                                            <name value="Resource identification"/>
                                            <description
                                                value="Checks if all resources specified by the scenario can be identified unambiguously."/>
                                            <xsl:copy-of select="$identifyResources"/>
                                        </test>
                                    </xsl:if>
                                    <teardown>
                                        <nts:include value="teardown-deletePatient" scope="project"/>
                                    </teardown>
                                    <!--<teardown nts:in-targets="#default">
                                         <!-\- first the individual deletes, so we can also get rid of non-patient related resources, such as PractitionerRole/Practitioner/Organization and the like -\->
                                         <!-\- but not Patient, since we want to do a purge after -\->
                                         <xsl:copy-of select="$deleteStuff/f:action[f:operation/f:resource[@value ne 'Patient']]"/>
                                         <!-\- we do a patient purge for extra certainty, we don't know if whoever sent this Bundle sent the exact same number of resources that we expect 
                                         and this way we will at least get rid of patient related resources which pollute BSN-based query's -\->
                                         <action>
                                         <operation>
                                         <!-\- Purge the created Patient and all its remaining associated resources that have been sent. -\->
                                         <type>
                                         <system value="http://touchstone.com/fhir/extended-operation-codes"/>
                                         <code value="purge"/>
                                         </type>
                                         <resource value="Patient"/>
                                         <encodeRequestUrl value="true"/>
                                         <params>
                                         <xsl:attribute name="value">${patient-id}/$purge</xsl:attribute>
                                         </params>
                                         </operation>
                                         </action>
                                         </teardown>
                                         <teardown nts:in-targets="Nictiz-intern">
                                         <!-\- first the individual deletes, so we can also get rid of non-patient related resources, such as PractitionerRole/Practitioner/Organization and the like -\->
                                         <xsl:copy-of select="$deleteStuff/f:action"/>
                                         <!-\- MP-746 no $purge needed for Nictiz internal scripts -\->
                                         </teardown>-->                                    
                                 </xsl:otherwise>
                            </xsl:choose>
                        </TestScript>
                    </xsl:result-document>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:call-template name="util:logMessage">
                        <xsl:with-param name="level" select="$logWARN"/>
                        <xsl:with-param name="msg">Ada transaction '<xsl:value-of select="local-name()"/>' with transaction type '<xsl:value-of select="$transactionType"/>' not supported yet.</xsl:with-param>
                    </xsl:call-template>
                    
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:for-each>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Add in-target to deleteStuff</xd:desc>
    </xd:doc>
    <xsl:template match="f:action | f:variable" mode="Nictiz-intern">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="nts:in-targets">Nictiz-intern</xsl:attribute>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Default copy template</xd:desc>
    </xd:doc>
    <xsl:template match="@* | node()" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Capitalize first letter of a string</xd:desc>
        <xd:param name="in">The string to be handled</xd:param>
    </xd:doc>
    <xsl:function name="nf:first-cap" as="xs:string?">
        <xsl:param name="in" as="xs:string?"/>
        <xsl:sequence select="concat(upper-case(substring($in, 1, 1)), substring($in, 2))"/>
    </xsl:function>
    
    <xsl:template name="getScenarioString" as="element()*">
        <xsl:variable name="theScenario" select="(.//scenario-nr/@value)[1]"/>
        <xsl:variable name="theScenarioset">
            <xsl:choose>
                <xsl:when test="string-length($theScenario) gt 0">
                    <xsl:value-of select="replace($theScenario, '(\d+[a-zA-Z]?)\.?(\d*[a-zA-Z]?)\*?\s?.*', '$1')"/>
                </xsl:when>
                <!--<xsl:when test="string-length(voorstel_gegevens/(voorstel | antwoord)/identificatie/@value) gt 0">
                     <xsl:value-of select="lower-case(nf:assure-logicalid-chars(voorstel_gegevens/(voorstel | antwoord)/identificatie/@value))"/>
                     </xsl:when>-->
             </xsl:choose>
        </xsl:variable>
        <xsl:variable name="scenarioSub" select="normalize-space(replace(replace($theScenario, '(\d+[a-zA-Z]?)\.?(\d*[a-zA-Z]?\*?\s?.*)', '$2'),'\*',''))"/>
        <xsl:variable name="scenario">
            <xsl:choose>
                <xsl:when test="string-length($scenarioSub) gt 0">
                    <xsl:value-of select="$scenarioSub"/>
                </xsl:when>
                <xsl:when test="string-length($theScenario) gt 0">x</xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="theScenarioX" select="concat($theScenarioset, '.', $scenario)"/>
        
        <!-- Edit the scenarioset to the format 00 with trailing non-digits -->
        <xsl:variable name="scenarioset00">
            <xsl:analyze-string select="xs:string($theScenarioset)" regex="^(\d+)(.*)$">
                <xsl:matching-substring>
                    <xsl:value-of select="format-number(number(regex-group(1)), '00')"/>
                    <xsl:value-of select="regex-group(2)"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        
        <xsl:variable name="theScenario0X" select="concat($scenarioset00, '.', $scenario)"/>
        
        <scenarioString>
            <xsl:attribute name="theScenario" select="$theScenario"/>
            <xsl:attribute name="theScenarioX" select="$theScenarioX"/>
            <xsl:attribute name="theScenarioHyphen" select="replace(nf:removeSpecialCharacters($theScenario), '\.', '-')"/>
            <xsl:attribute name="theScenario0XHyphen" select="replace(nf:removeSpecialCharacters($theScenario0X), '\.', '-')"/>
            <xsl:attribute name="scenarioset" select="$theScenarioset"/>
            <xsl:attribute name="scenarioset00" select="$scenarioset00"/>
            <xsl:attribute name="scenario" select="$scenario"/>
        </scenarioString>
    </xsl:template>
    
    <xsl:template name="getTestScriptString" as="element()*">
        <xsl:choose>
            <xsl:when test="self::beschikbaarstellen_medicatiegegevens | self::sturen_medicatiegegevens">
                <testscriptstring short="mg" full="Medication data" wiki="medicatiegegevens"/>
            </xsl:when>
            <xsl:when test="self::sturen_medicatievoorschrift">
                <testscriptstring short="vs" full="Medication prescription" wiki="voorschrift"/>
            </xsl:when>
            <xsl:when test="self::sturen_afhandeling_medicatievoorschrift">
                <testscriptstring short="avs" full="Prescription processing" wiki="afhandelen_voorschrift"/>
            </xsl:when>
            <xsl:when test="self::sturen_voorstel_medicatieafspraak">
                <testscriptstring short="vma" full="Proposal medication agreement" wiki="vma"/>
            </xsl:when>
            <xsl:when test="self::sturen_antwoord_voorstel_medicatieafspraak">
                <testscriptstring short="avma" full="Reply proposal medication agreement" wiki="avma"/>
            </xsl:when>
            <xsl:when test="self::sturen_voorstel_verstrekkingsverzoek">
                <testscriptstring short="vvv" full="Proposal dispense request" wiki="vvv"/>
            </xsl:when>
            <xsl:when test="self::sturen_antwoord_voorstel_verstrekkingsverzoek">
                <testscriptstring short="avvv" full="Reply proposal dispense request" wiki="avvv"/>
            </xsl:when>
            <xsl:otherwise>
                <testscriptstring short="notsupp" long="NotSupported"/>
                <xsl:call-template name="util:logMessage">
                    <xsl:with-param name="level" select="$logWARN"/>
                    <xsl:with-param name="msg">Ada transaction '<xsl:value-of select="local-name()"/>' with transaction type '<xsl:value-of select="$transactionType"/>' not properly supported yet.</xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getIdString" as="xs:string">
        <xsl:param name="testGoal"/>
        <xsl:param name="short"/>
        <xsl:param name="buildingBlockShort"/>
        <xsl:param name="transactionType"/>
        <xsl:param name="theScenario0XHyphen"/>
        
        <xsl:variable name="buildString">
            <xsl:text>mp9-</xsl:text>
            <xsl:choose>
                <xsl:when test="lower-case($testGoal) = 'cert'">
                    <xsl:text>c</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>t</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>-</xsl:text>
            <xsl:choose>
                <xsl:when test="normalize-space(upper-case($transactionType)) = 'RETRIEVE'">ret</xsl:when>
                <xsl:when test="normalize-space(upper-case($transactionType)) = 'SEND'">sen</xsl:when>
                <xsl:when test="normalize-space(upper-case($transactionType)) = 'SERVE'">ser</xsl:when>
                <xsl:when test="normalize-space(upper-case($transactionType)) = 'RECEIVE'">rec</xsl:when>
                <xsl:otherwise>unknown</xsl:otherwise>
            </xsl:choose>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$short"/>
            <xsl:if test="$buildingBlockShort = ('VV','MTD','MA','MVE','MGB','TA','WDS') or contains($buildingBlockShort, 'CONS-')">
                <xsl:value-of select="concat('-',$buildingBlockShort)"/>
            </xsl:if>
            <xsl:if test="string-length($theScenario0XHyphen) gt 1">
                <xsl:value-of select="concat('-',$theScenario0XHyphen)"/>
            </xsl:if>
            <xsl:if test="not($buildingBlockShort = ('VV','MTD','MA','MVE','MGB','TA','WDS')) and not(contains($buildingBlockShort, 'CONS-')) and string-length($buildingBlockShort) gt 0">
                <xsl:value-of select="concat('-',substring($buildingBlockShort,1,20))"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:if test="string-length(string-join($buildString,'')) gt 64">
            <xsl:call-template name="util:logMessage">
                <xsl:with-param name="level" select="$logWARN"/>
                <xsl:with-param name="msg">Id '<xsl:value-of select="string-join($buildString,'')"/>' is longer than 64 characters. Sorting in the simulator may give unexpected results</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:value-of select="string-join($buildString,'')"/>
    </xsl:template>
    
    <xsl:template name="getTestScriptTitle" as="xs:string">
        <xsl:param name="theScenarioX"/>
        <xsl:param name="titleSuffix"/>
        
        <xsl:variable name="buildString">
            <xsl:value-of select="'Scenario '"/>
            <xsl:if test="not($theScenarioX = '.')">
                <xsl:value-of select="$theScenarioX"/>
            </xsl:if>
            <xsl:if test="string-length($titleSuffix) gt 0">
                <xsl:if test="not($theScenarioX = '.')">
                    <xsl:value-of select="' - '"/>
                </xsl:if>
                <xsl:value-of select="$titleSuffix"/>
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="string-join($buildString,'')"/>
    </xsl:template>
    
    <xsl:template name="getTestScriptDescription" as="xs:string">
        <xsl:param name="transactionType"/>
        <xsl:param name="full"/>
        <xsl:param name="buildingBlockShort"/>
        <xsl:param name="patient"/>
        <xsl:param name="adaDescription"/>
        <xsl:param name="adaTitle"/>
        <xsl:param name="testGoal" required="yes"/>
        <xsl:param name="wiki" required="yes"/>
        
        <xsl:variable name="wikiUrl">
            <xsl:variable name="buildString">
                <xsl:text>https://informatiestandaarden.nictiz.nl/wiki/mp:V3.0.0_</xsl:text>
                <xsl:choose>
                    <xsl:when test="contains($buildingBlockShort, 'CONS-')">
                        <xsl:text>consolidatie</xsl:text>
                    </xsl:when>
                    <xsl:when test="$testGoal = 'Test'">
                        <xsl:text>testgegevens</xsl:text>
                    </xsl:when>
                    <xsl:when test="$testGoal = 'Cert'">
                        <xsl:text>kwalificatie</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>unknown</xsl:otherwise>
                </xsl:choose>
                <xsl:text>_</xsl:text>
                <xsl:value-of select="$wiki"/>
                <xsl:text>_</xsl:text>
                <xsl:choose>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = 'RETRIEVE'">raadplegen</xsl:when>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = 'SEND'">sturen</xsl:when>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = 'SERVE'">beschikbaarstellen</xsl:when>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = 'RECEIVE'">ontvangen</xsl:when>
                    <xsl:otherwise>unknown</xsl:otherwise>
                </xsl:choose>
                <xsl:if test="$buildingBlockShort = ('VV','MTD','MA','MVE','MGB','TA','WDS')">
                    <xsl:text>_</xsl:text>
                    <xsl:value-of select="$buildingBlockShort"/>
                </xsl:if>
            </xsl:variable>
            
            <xsl:value-of select="string-join($buildString, '')"/>
        </xsl:variable>
        
        <xsl:variable name="buildString">
            <xsl:value-of select="concat(nf:first-cap($transactionType), ' ', $full, ' ', $buildingBlockShort, ' building blocks for patient ', $patient)"/>
            <xsl:value-of select="'&#xA;&#xA;For more info:&#xA;'"/>
            <xsl:value-of select="$wikiUrl"/>
            <xsl:if test="string-length($adaDescription) gt 0 or string-length($adaTitle) gt 0">
                <xsl:value-of select="'&#xA;&#xA;Original description:'"/>
            </xsl:if>
            <xsl:if test="string-length($adaTitle) gt 0">
                <xsl:value-of select="concat('&#xA;',$adaTitle)"/>
            </xsl:if>
            <xsl:if test="string-length($adaDescription) gt 0">
                <xsl:value-of select="concat('&#xA;',replace(replace($adaDescription,'&lt;/?(div|span)( style=&quot;.*?&quot;)?&gt;',''),'&lt;br&gt;','&#xA;')),''"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:value-of select="string-join($buildString, '')"/>
    </xsl:template>
    
    <xsl:template name="getTestName" as="xs:string">
        <xsl:param name="theScenarioX"/>
        <xsl:param name="fallback"/>
        
        <xsl:choose>
            <xsl:when test="not($theScenarioX = '.')">
                <xsl:value-of select="concat('Scenario ', $theScenarioX)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('Scenario ', $fallback)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getTestDescription" as="xs:string">
        <xsl:param name="transactionType"/>
        <xsl:param name="full"/>
        <xsl:param name="buildingBlockShort"/>
        
        <xsl:variable name="bundleType">
            <xsl:choose>
                <xsl:when test="normalize-space(upper-case($transactionType)) = ('RECEIVE', 'SEND')">transaction</xsl:when>
                <xsl:when test="normalize-space(upper-case($transactionType)) = ('SERVE', 'RETRIEVE')">searchset</xsl:when>
                <xsl:otherwise>unknown</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat(nf:first-cap($transactionType), ' ', $full, ' ', $buildingBlockShort, ' resources in a ', $bundleType, ' Bundle')"/>
    </xsl:template>
    
    <xsl:template name="append-2-context">
        <xsl:param name="categoryCode"/>
        <xsl:param name="currentMPBouwsteen"/>
        <xsl:param name="mpBouwstenenSameProduct"/>
        
        <xsl:choose>
            <xsl:when test="$categoryCode = $maCodeMP920">
                <xsl:variable name="stopTypeCode"
                    select="$currentMPBouwsteen/f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value"/>
                <xsl:variable name="reasonCode"
                    select="$currentMPBouwsteen/f:reasonCode/f:coding/f:code/@value"/>
                <xsl:variable name="timingExact"
                    select="$currentMPBouwsteen/f:dosageInstruction/f:timing/f:repeat/f:extension[@url = 'http://hl7.org/fhir/StructureDefinition/timing-exact']/f:valueBoolean/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- aanwezigheid stoptype uniek? -->
                    <xsl:when
                        test="$stopTypeCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value = $stopTypeCode]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"
                            />
                    </xsl:when>
                    <!-- afwezigheid stoptype uniek? -->
                    <xsl:when
                        test="not($stopTypeCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not())')"
                            />
                    </xsl:when>
                    <!-- aanwezigheid reden... uniek? -->
                    <xsl:when
                        test="$reasonCode and count($mpBouwstenenSameProduct[f:reasonCode/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of
                            select="concat('.where(reasonCode.coding.code = ''', $reasonCode, ''')')"
                            />
                    </xsl:when>
                    <!-- afwezigheid reden... uniek? -->
                    <xsl:when
                        test="not($reasonCode) and count($mpBouwstenenSameProduct[not(f:reasonCode/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="'.where(reasonCode.exists().not())'"/>
                    </xsl:when>
                    <!-- MA-3: hoeveelheid dosageInstruction-elementen (komt in de basis overeen met hoeveelheid 'dosering'-elementen in ADA) uniek? -->
                    <xsl:when
                        test="count($mpBouwstenenSameProduct[count(f:dosageInstruction) = count(current()/f:dosageInstruction)]) = 1">
                        <xsl:value-of
                            select="concat('.where(dosageInstruction.count() = ', count(f:dosageInstruction), ')')"
                            />
                    </xsl:when>
                    <!-- MA-6: is_flexibel (exacte timing) uniek?-->
                    <xsl:when
                        test="count($mpBouwstenenSameProduct[f:dosageInstruction/f:timing/f:repeat/f:extension[@url = 'http://hl7.org/fhir/StructureDefinition/timing-exact']/f:valueBoolean/@value = $timingExact]) = 1">
                        <xsl:value-of
                            select="concat('.where(dosageInstruction.timing.repeat.extension.where(url = ''http://hl7.org/fhir/StructureDefinition/timing-exact'').value = ', $timingExact, ')')"
                            />
                    </xsl:when>
                    <!-- aanwezigheid stoptype en reden... uniek? -->
                    <xsl:when
                        test="$stopTypeCode and $reasonCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value = $stopTypeCode and f:reasonCode/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"/>
                        <xsl:value-of
                            select="concat('.where(reasonCode.coding.code = ''', $reasonCode, ''')')"
                            />
                    </xsl:when>
                    <!-- afwezigheid stoptype en reden... uniek? -->
                    <xsl:when
                        test="not($stopTypeCode) and not($reasonCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value) and not(f:reasonCode/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not()).where(reasonCode.exists().not())')"
                            />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of
                                select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of
                                select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"
                                /></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $mgbCode">
                <xsl:variable name="stopTypeCode"
                    select="$currentMPBouwsteen/f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value"/>
                <xsl:variable name="asAgreedIndicator"
                    select="$currentMPBouwsteen/f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value"/>
                <xsl:variable name="timingExact"
                    select="$currentMPBouwsteen/f:dosage/f:timing/f:repeat/f:extension[@url = 'http://hl7.org/fhir/StructureDefinition/timing-exact']/f:valueBoolean/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- aanwezigheid stoptype uniek? -->
                    <xsl:when
                        test="$stopTypeCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value = $stopTypeCode]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"
                            />
                    </xsl:when>
                    <!-- afwezigheid stoptype uniek? -->
                    <xsl:when
                        test="not($stopTypeCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not())')"
                            />
                    </xsl:when>
                    <xsl:when
                        test="$asAgreedIndicator and count($mpBouwstenenSameProduct[f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value = $asAgreedIndicator]) = 1">
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', $urlExtAsAgreedIndicator, ''').value = ', $asAgreedIndicator, ')')"
                            />
                    </xsl:when>
                    <xsl:when
                        test="not($asAgreedIndicator) and count($mpBouwstenenSameProduct[not(f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', $urlExtAsAgreedIndicator, ''').exists().not())')"
                            />
                    </xsl:when>
                    <!-- MGB-6: is_flexibel (exacte timing) uniek?-->
                    <xsl:when
                        test="$timingExact and count($mpBouwstenenSameProduct[f:dosage/f:timing/f:repeat/f:extension[@url = 'http://hl7.org/fhir/StructureDefinition/timing-exact']/f:valueBoolean/@value = $timingExact]) = 1">
                        <xsl:value-of
                            select="concat('.where(dosageInstruction.timing.repeat.extension.where(url = ''http://hl7.org/fhir/StructureDefinition/timing-exact'').value = ', $timingExact, ')')"
                            />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of
                                select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of
                                select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"
                                /></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $mtdCode">
                <xsl:variable name="reasonCode"
                    select="$currentMPBouwsteen/f:extension[@url = $urlExtMedicationAdministration2ReasonForDeviation]/f:valueCodeableConcept/f:coding/f:code/@value"/>
                <xsl:variable name="asAgreedIndicator"
                    select="$currentMPBouwsteen/f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- aanwezigheid reden... uniek? -->
                    <xsl:when
                        test="$reasonCode and count($mpBouwstenenSameProduct[f:extension[@url = $urlExtMedicationAdministration2ReasonForDeviation]/f:valueCodeableConcept/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', $urlExtMedicationAdministration2ReasonForDeviation, ''').value.coding.code = ''', $reasonCode, ''')')"
                            />
                    </xsl:when>
                    <!-- afwezigheid reden... uniek? -->
                    <xsl:when
                        test="not($reasonCode) and count($mpBouwstenenSameProduct[not(f:extension[@url = $urlExtMedicationAdministration2ReasonForDeviation]/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', $urlExtMedicationAdministration2ReasonForDeviation, ''').exists().not())')"
                            />
                    </xsl:when>
                    <xsl:when
                        test="$asAgreedIndicator and count($mpBouwstenenSameProduct[f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value = $asAgreedIndicator]) = 1">
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', $urlExtAsAgreedIndicator, ''').value = ', $asAgreedIndicator, ')')"
                            />
                    </xsl:when>
                    <xsl:when
                        test="not($asAgreedIndicator) and count($mpBouwstenenSameProduct[not(f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', $urlExtAsAgreedIndicator, ''').exists().not())')"
                            />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of
                                select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of
                                select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"
                                /></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $mveCode">
                <!-- Verzamel alle distinct quantity.values van dit product -->
                <xsl:variable name="quantities-raw"
                    select="distinct-values($mpBouwstenenSameProduct/f:quantity/f:value/@value)"/>
                
                <!-- Normaliseer naar FHIRPath-compatibele decimalen (puntnotatie, geen trailing nullen) -->
                <xsl:variable name="quantities" as="xs:string*" select="
                    for $q in $quantities-raw
                    return
                        format-number(xs:decimal($q), '0.################')
                                "/>
                
                <!-- Als er tenminste één quantity is, voeg OR-predicate toe: (.where(quantity.value = q1 or q2 ...)) -->
                <xsl:if test="exists($quantities)">
                    <xsl:value-of select="'.where('"/>
                    <xsl:value-of select="'('"/>
                    <xsl:for-each select="$quantities">
                        <xsl:value-of select="concat('quantity.value = ', .)"/>
                        <xsl:if test="position() ne last()">
                            <xsl:value-of select="' or '"/>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>)</xsl:text>
                    <!-- sluit de ( ... ) -->
                    <xsl:text>)</xsl:text>
                    <!-- sluit .where(...) -->
                </xsl:if>
            </xsl:when>
            <xsl:when test="$categoryCode = $taCode">
                <xsl:variable name="stopTypeCode"
                    select="$currentMPBouwsteen/f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value"/>
                <xsl:variable name="reasonCode"
                    select="$currentMPBouwsteen/f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- aanwezigheid stoptype uniek? -->
                    <xsl:when
                        test="$stopTypeCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value = $stopTypeCode]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"
                            />
                    </xsl:when>
                    <!-- afwezigheid stoptype uniek? -->
                    <xsl:when
                        test="not($stopTypeCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not())')"
                            />
                    </xsl:when>
                    <!-- aanwezigheid reden... uniek? -->
                    <xsl:when
                        test="$reasonCode and count($mpBouwstenenSameProduct[f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation', ''').value.coding.code = ''', $reasonCode, ''')')"
                            />
                    </xsl:when>
                    <!-- afwezigheid reden... uniek? -->
                    <xsl:when
                        test="not($reasonCode) and count($mpBouwstenenSameProduct[not(f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation', ''').exists().not())')"
                            />
                    </xsl:when>
                    
                    <!-- dosageInstruction.timing.repeat.frequency/.when? -->
                    <!-- aanwezigheid stoptype en reden... uniek? -->
                    <xsl:when
                        test="$stopTypeCode and $reasonCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value = $stopTypeCode and f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"/>
                        <xsl:value-of
                            select="concat('.where(extension.where(url = ''', 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation', ''').value.coding.code = ''', $reasonCode, ''')')"
                            />
                    </xsl:when>
                    <!-- afwezigheid stoptype en reden... uniek? -->
                    <xsl:when
                        test="not($stopTypeCode) and not($reasonCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value) and not(f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of
                            select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not()).where(extension.where(url = ''', 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation', ''').exists().not())')"
                            />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of
                                select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of
                                select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"
                                /></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $vvCode">
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of
                                select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of
                                select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"
                                /></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $wdsCode">
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of
                                select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of
                                select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"
                                /></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Building block not supported (yet)</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
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
    
</xsl:stylesheet>