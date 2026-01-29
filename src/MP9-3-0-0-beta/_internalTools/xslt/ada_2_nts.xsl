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

    <xsl:variable name="bsnSystem" select="$oidMap[@oid = $oidBurgerservicenummer]/@uri"/>

    <xd:doc>
        <xd:desc>Start template. Handles ada test instances, converts them to nts.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:variable name="adaTransaction" select="adaxml/data/*" as="element()*"/>
        
        <xsl:for-each select="$adaTransaction">
            <!-- find corresponding FHIR fixture based on adaId -->
            <xsl:variable name="adaTransId" select="nf:removeSpecialCharacters(@id)"/>
            
            <xsl:variable name="testGoal">
                <xsl:choose>
                    <xsl:when test="replace($adaTransId,'.+(tst|kwal)-(.+)-v30', '$1') = 'kwal'">Cert</xsl:when>
                    <xsl:otherwise>Test</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="fhirFixture" select="document(concat($mappingsUrl4FhirFixtures, '/', $adaTransId, '.xml'))"/>
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
                    
                    <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                        <id value="{$idString}"/>
                        <version value="r4-mp9-3.0.0-beta"/>
                        <title value="{$testScriptTitle}"/>
                        <description value="{$testScriptDescription}"/>
                        <xsl:choose>
                            <!-- Receive -->
                            <xsl:when test="$ntsScenario = 'server'">
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.{'{$_FORMAT}'}"/>
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
                                            <sourceId value="{$adaTransId}"/>
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
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- assume Send -->
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml" nts:in-targets="Nictiz-intern"/>
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
                                            <responseId value="transaction-response-fixture"/>
                                            <sourceId value="{$adaTransId}" nts:in-targets="Nictiz-intern"/>
                                        </operation>
                                    </action>
                                    <nts:include value="test.client.successfulTransaction" scope="common"/>
                                    <xsl:copy-of select="$includeNumResources"/>
                                </test>
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
                <testscriptstring short="meddata" full="Medication data" wiki="medicatiegegevens"/>
            </xsl:when>
            <xsl:when test="self::sturen_medicatievoorschrift">
                <testscriptstring short="prescr" full="Medication prescription" wiki="voorschrift"/>
            </xsl:when>
            <xsl:when test="self::sturen_afhandeling_medicatievoorschrift">
                <testscriptstring short="prescrproc" full="Prescription processing" wiki="afhandelen_voorschrift"/>
            </xsl:when>
            <xsl:when test="self::sturen_voorstel_medicatieafspraak">
                <testscriptstring short="propma" full="Proposal medication agreement" wiki="vma"/>
            </xsl:when>
            <xsl:when test="self::sturen_antwoord_voorstel_medicatieafspraak">
                <testscriptstring short="reppropma" full="Reply proposal medication agreement" wiki="avma"/>
            </xsl:when>
            <xsl:when test="self::sturen_voorstel_verstrekkingsverzoek">
                <testscriptstring short="propvv" full="Proposal dispense request" wiki="vvv"/>
            </xsl:when>
            <xsl:when test="self::sturen_antwoord_voorstel_verstrekkingsverzoek">
                <testscriptstring short="reppropvv" full="Reply proposal dispense request" wiki="avvv"/>
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
            <xsl:value-of select="concat('mp9-',lower-case($testGoal),'-', normalize-space(lower-case($transactionType)), '-', $short)"/>
            <xsl:if test="$buildingBlockShort = ('VV','MTD','MA','MVE','MGB','TA','WDS') or contains($buildingBlockShort, 'CONS-')">
                <xsl:value-of select="concat('-',$buildingBlockShort)"/>
            </xsl:if>
            <xsl:if test="string-length($theScenario0XHyphen) gt 1">
                <xsl:value-of select="concat('-',$theScenario0XHyphen)"/>
            </xsl:if>
            <xsl:if test="not($buildingBlockShort = ('VV','MTD','MA','MVE','MGB','TA','WDS')) and not(contains($buildingBlockShort, 'CONS-'))">
                <xsl:value-of select="concat('-',$buildingBlockShort)"/>
            </xsl:if>
        </xsl:variable>
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
                <xsl:text>https://informatiestandaarden.nictiz.nl/wiki/mp:V9.3.0_</xsl:text>
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
                <xsl:value-of select="concat('&#xA;',replace(replace(replace($adaDescription,'&lt;div&gt;',''),'&lt;/div&gt;',''),'&lt;br&gt;','&#xA;'))"/>
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

</xsl:stylesheet>
