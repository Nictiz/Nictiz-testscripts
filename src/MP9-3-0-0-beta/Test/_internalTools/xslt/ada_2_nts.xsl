<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:util="urn:hl7:utilities" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <!--Import mp specific constants (and package for underlying imports)-->
    <xsl:import href="https://raw.githubusercontent.com/Nictiz/HL7-mappings/MP9-3-dev/ada_2_fhir-r4/mp/9.3.0/payload/mp9_latest_package.xsl"/>
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="*"/>

    <xsl:param name="mappingsUrl4FhirFixtures">https://raw.githubusercontent.com/Nictiz/HL7-mappings/MP9-3-dev/ada_2_fhir-r4/mp/9.3.0/4TouchstoneMP</xsl:param>

    <!-- Send/Receive/Retrieve/Serve, this param defaults to Send -->
    <xsl:param name="transactionType">Send</xsl:param>

    <xsl:variable name="bsnSystem" select="$oidMap[@oid = $oidBurgerservicenummer]/@uri"/>

    <xd:doc>
        <xd:desc>Start template. Handles ada test instances, converts them to nts.</xd:desc>
    </xd:doc>
    <xsl:template match="/">

        <xsl:variable name="adaTransaction" select="adaxml/data/*" as="element()*"/>

        <xsl:for-each select="$adaTransaction">
            <!-- find corresponding FHIR fixture based on adaId / filename -->
            <xsl:variable name="adaTransId" select="nf:removeSpecialCharacters(@id)"/>
            <xsl:variable name="fhirFixture" select="document(concat($mappingsUrl4FhirFixtures, '/', $adaTransId, '.xml'))"/>
            <xsl:variable name="fixturePatient" select="$fhirFixture//f:Patient[1]"/>

            <xsl:variable name="scenarioset">
                <xsl:choose>
                    <xsl:when test="string-length(scenario-nr/@value) gt 0">
                        <xsl:value-of select="replace(scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$1')"/>
                    </xsl:when>
                    <xsl:when test="string-length(voorstel_gegevens/(voorstel|antwoord)/identificatie/@value) gt 0">
                        <xsl:value-of select="lower-case(nf:assure-logicalid-chars(voorstel_gegevens/(voorstel|antwoord)/identificatie/@value))"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="scenarioSub" select="replace(scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$2')"/>
            <xsl:variable name="scenario">
                <xsl:choose>
                    <xsl:when test="string-length($scenarioSub) gt 0">
                        <xsl:value-of select="$scenarioSub"/>
                    </xsl:when>
                    <xsl:when test="string-length(scenario-nr/@value) gt 0">x</xsl:when>
                </xsl:choose>
            </xsl:variable>

            <xsl:variable name="ntsScenario" as="xs:string?">
                <xsl:choose>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = ('RETRIEVE', 'SEND')">client</xsl:when>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = ('SERVE', 'RECEIVE')">server</xsl:when>
                    <xsl:otherwise>unknown</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:variable name="testScriptString" as="element()*">
                <xsl:choose>
                    <xsl:when test="self::beschikbaarstellen_medicatiegegevens | self::sturen_medicatiegegevens">
                        <testscriptstring short="meddata" long="MedicationData"/>
                    </xsl:when>
                    <xsl:when test="self::sturen_medicatievoorschrift">
                        <testscriptstring short="prescr" long="MedicationPrescription"/>
                    </xsl:when>
                    <xsl:when test="self::sturen_afhandeling_medicatievoorschrift">
                        <testscriptstring short="prescrproc" long="PrescrProcessing"/>
                    </xsl:when>
                    <xsl:when test="self::sturen_voorstel_medicatieafspraak">
                        <testscriptstring short="propma" long="ProposalMA"/>
                    </xsl:when>
                    <xsl:when test="self::sturen_antwoord_voorstel_medicatieafspraak">
                        <testscriptstring short="reppropma" long="ReplyProposalMA"/>
                    </xsl:when>
                    <xsl:when test="self::sturen_voorstel_verstrekkingsverzoek">
                        <testscriptstring short="propvv" long="ProposalVV"/>
                    </xsl:when>
                    <xsl:when test="self::sturen_antwoord_voorstel_verstrekkingsverzoek">
                        <testscriptstring short="reppropvv" long="ReplyProposalVV"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <testscriptstring short="notsupp" long="NotSupported"/>
                        <xsl:call-template name="util:logMessage">
                            <xsl:with-param name="level" select="$logWARN"/>
                            <xsl:with-param name="msg">Ada transaction '<xsl:value-of select="local-name()"/>' with transaction type '<xsl:value-of select="$transactionType"/>' not properly supported yet.</xsl:with-param>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="direction">
                <xsl:choose>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = ('RETRIEVE', 'SEND')">request</xsl:when>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = ('SERVE', 'RECEIVE')">response</xsl:when>
                </xsl:choose>
            </xsl:variable>
            
            <!-- In Send scripts, the request is being validated. In Receive scripts, the response is being validated (mainly because the FHIR spec is not really clear about what servers can or cannot edit before storing a resource). In both these cases, we add an assert to check for each resource that we expect. Next to that, this script is prepared to also add a variable for each resource, so that we can use this variable in the future to add content asserts for each resource -->
            <xsl:variable name="identifyResources" as="element()*">
                <!-- We use fhir as source instead of ada to be able to make the mapping between fhir and fhirpath easier (mainly the handling of PharmaceuticalProduct to FHIR Medication requires this)
                    At the moment, the generated fixture is used. Perhaps it would be better to use ada as input and call ada2fhir dynamically.  -->
                <xsl:variable name="medicationGroup" select="$fhirFixture/f:Bundle/f:entry/f:resource/f:Medication"/>
                <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                    <xsl:choose>
                        <!-- only check the primary resources and Medication, it is not obliged to send along the secondary resources -->
                        <xsl:when test="current-grouping-key() = ('MedicationAdministration','MedicationDispense','MedicationRequest','MedicationStatement')">
                            <xsl:variable name="resourceType" select="current-grouping-key()"/>
                            <!-- We  do not include mpBouwsteenBaseContext because the category code is included in all search queries. This might change though -->
                            <xsl:variable name="mpBouwsteenBaseContext" select="concat('Bundle.entry.select(resource as ', $resourceType, ')')"/>
                            
                            <xsl:for-each-group select="current-group()" group-by="f:category/f:coding/f:code/@value">
                                <xsl:variable name="categoryCode" select="current-grouping-key()"/>
                                <xsl:variable name="allMPBouwstenenOfSameKind" select="current-group()"/>
                                
                                <xsl:for-each select="$allMPBouwstenenOfSameKind">
                                    <xsl:variable name="currentMPBouwsteen" select="."/>
                                    <xsl:variable name="medicationReference" select="$currentMPBouwsteen/f:medicationReference/f:reference/@value"/>
                                    <xsl:variable name="resolvedMedication" select="$fhirFixture/f:Bundle/f:entry[f:fullUrl/@value = $medicationReference]/f:resource/f:Medication"/>
                                    <xsl:variable name="medication-code" select="distinct-values($resolvedMedication/f:code/f:coding/f:code/@value)"/>
                                    <xsl:variable name="ingredient-code" select="distinct-values($resolvedMedication/f:ingredient/f:itemCodeableConcept/f:coding/f:code/@value)"/>
                                    
                                    <!-- TODO: Add exception for 90million -->
                                    <xsl:variable name="mpBouwstenenSameProduct" as="element()*">
                                        <xsl:choose>
                                            <xsl:when test="count($medication-code) = 0">
                                                <xsl:sequence select="$allMPBouwstenenOfSameKind"/>
                                            </xsl:when>
                                            <xsl:when test="count($medication-code) = 1 and $medication-code = 'OTH'">
                                                <xsl:for-each select="$allMPBouwstenenOfSameKind">
                                                    <xsl:variable name="medicationReference" select="f:medicationReference/f:reference/@value"/>
                                                    <xsl:if test="$fhirFixture/f:Bundle/f:entry[f:fullUrl/@value = $medicationReference]/f:resource/f:Medication[f:code/f:coding/f:code/@value = $medication-code and f:ingredient/f:itemCodeableConcept/f:coding/f:code/@value = $ingredient-code]">
                                                        <xsl:sequence select="."/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:for-each select="$allMPBouwstenenOfSameKind">
                                                    <xsl:variable name="medicationReference" select="f:medicationReference/f:reference/@value"/>
                                                    <xsl:if test="$fhirFixture/f:Bundle/f:entry[f:fullUrl/@value = $medicationReference]/f:resource/f:Medication/f:code[every $code in $medication-code satisfies f:coding/f:code/@value = $code]">
                                                        <xsl:sequence select="."/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    
                                    <xsl:variable name="expression">
                                        <xsl:value-of select="$mpBouwsteenBaseContext"/>
                                        <!-- We always add medication (and ingredients if medication is OTH)-->
                                        <xsl:value-of select="'.where(medication.resolve()'"/>
                                        <xsl:choose>
                                            <xsl:when test="count($medication-code) = 1 and $medication-code = 'OTH'">
                                                <xsl:value-of select="'.where(code.where(coding.where(code = ''OTH'')) and '"/>
                                                <xsl:for-each select="$ingredient-code">
                                                    <xsl:value-of select="concat('ingredient.item.where(coding.where(code = ''', ., '''))')"/>
                                                    <xsl:if test="not(position() = last())">
                                                        <xsl:value-of select="' and '"/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="'.code.where('"/>
                                                <xsl:for-each select="$medication-code">
                                                    <xsl:value-of select="concat('coding.where(code = ''', ., ''')')"/>
                                                    <xsl:if test="not(position() = last())">
                                                        <xsl:value-of select="' and '"/>
                                                    </xsl:if>
                                                </xsl:for-each>
                                                <xsl:value-of select="')'"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <xsl:value-of select="')'"/>
                                        <!-- Add building block specific stuff -->
                                        <xsl:call-template name="append-2-context">
                                            <xsl:with-param name="categoryCode" select="$categoryCode"/>
                                            <xsl:with-param name="currentMPBouwsteen" select="$currentMPBouwsteen"/>
                                            <xsl:with-param name="mpBouwstenenSameProduct" select="$mpBouwstenenSameProduct"/>
                                        </xsl:call-template>
                                        <xsl:value-of select="'.count() = 1'"/>
                                    </xsl:variable>
                                    
                                    <action xmlns="http://hl7.org/fhir">
                                        <assert>
                                            <!--<description value="{$description}"/>-->
                                            <expression value="{$expression}"/>
                                            <sourceId value="transaction-{$direction}"/>
                                            <warningOnly value="false"/>
                                        </assert>
                                    </action>
                                </xsl:for-each>
                            </xsl:for-each-group>
                        </xsl:when>
                        <xsl:when test="current-grouping-key() = 'Medication'">
                            <xsl:for-each-group select="current-group()" group-by="concat((f:code/f:coding[f:userSelected/@value = 'true'],f:code/f:coding[1])[1]/f:code/@value, '|', (f:code/f:coding[f:userSelected/@value = 'true'],f:code/f:coding[1])[1]/f:system/@value)">
                                <xsl:variable name="resourceCount" select="count(current-group())"/>
                                
                                <xsl:variable name="medicationCoding" select="(f:code/f:coding[f:userSelected/@value = 'true'],f:code/f:coding[1])[1]"/>
                                <xsl:variable name="medicationCode" select="$medicationCoding/f:code/@value"/>
                                <xsl:variable name="medicationSystem" select="$medicationCoding/f:system/@value"/>
                                <xsl:variable name="medicationDisplay" select="$medicationCoding/f:display/@value"/>
                                <!-- First we check if the userSelected (or if userSelected is absent just the first) coding is unique within the Medication group. If not, we are going to use the complete CodeableConcept to generate an expression -->
                                <xsl:variable name="useUserSelected">
                                    <xsl:variable name="medicationCoding" />
                                    <xsl:choose>
                                        <!-- Exception for OTH for now -->
                                        <xsl:when test="count($medicationGroup/f:code/f:coding[f:code/@value = $medicationCode and f:system/@value = $medicationSystem]) gt 1 and not($medicationCode = 'OTH')">
                                            <xsl:value-of select="false()"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="true()"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                
                                <xsl:variable name="expression">
                                    <xsl:value-of select="'Bundle.entry.select(resource as Medication).where(code'"/>
                                    <xsl:choose>
                                        <xsl:when test="$useUserSelected = true()">
                                            <xsl:value-of select="concat('.coding.where(system = ''', $medicationSystem, ''' and code = ''', $medicationCode, ''')')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="concat('.where(coding.count() = ', count(f:code/f:coding), ' and ')"/>
                                            <xsl:for-each select="f:code/f:coding">
                                                <xsl:value-of select="concat('coding.where(system = ''', f:system/@value, ''' and code = ''', f:code/@value, ''')')"/>
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
                                        <description value="Confirm that the {$direction} Bundle contains {$resourceCount} Medication resource that contains code '{$medicationCode}|{$medicationSystem}' ({$medicationDisplay})"/>
                                        
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
                                    <nts:include value="assert.{$direction}.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                </xsl:when>
                                <!-- but for our own materials we'll check the others aswell just to be sure - for 'legacy reasons' only when receiving, should be also for sending? -->
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

                    <xsl:variable name="idString" select="replace(concat('mp9-', $testScriptString/@short, '-', normalize-space(lower-case($transactionType)), '-', $scenarioset, '-', $scenario), '(.*?)-?(-$)', '$1')"></xsl:variable>
                    <xsl:variable name="testId" select="concat('scenario', $scenarioset, '-', $scenario, '-', lower-case($transactionType), '-', $testScriptString/@short)"/>
                    <xsl:choose>
                        <!-- Receive -->
                        <xsl:when test="$ntsScenario = 'server'">
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="{$idString}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} {$testScriptString/@long}"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} {$testScriptString/@long} for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.{'{$_FORMAT}'}"/>
                                <nts:includeDateT value="yes"/>
                                <!--<xsl:apply-templates select="$deleteStuff/f:variable" mode="Nictiz-intern"/>-->
                                <test id="{$testId}">
                                    <name value="Operation and general checks"/>
                                    <description value="Specifies the query that runs and general checks on the response."/>
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
                                            <xsl:if test="count($identifyResources) gt 0">
                                                <responseId value="transaction-response"/>
                                            </xsl:if>
                                            <!--<responseId value="transaction-response-fixture" nts:in-targets="Nictiz-intern"/>-->
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <nts:include value="assert.response.success" scope="common"/>
                                    <nts:include value="assert.response.bundleContent" scope="common"
                                        bundleType="transaction-response"/>
                                    <xsl:copy-of select="$includeNumResources"/>
                                </test>
                                
                                <xsl:if test="count($identifyResources) gt 0">
                                    <test id="{$testId}-identification">
                                        <name value="Resource identification"/>
                                        <description value="Checks if all resources specified by the scenario can be identified unambiguously."/>
                                        <xsl:copy-of select="$identifyResources"/>
                                    </test>
                                </xsl:if>
                                <!-- teardown receive only needed for Nictiz internal tests -->
                                <!--<teardown nts:in-targets="Nictiz-intern">
                                    <!-\- the individual deletes, so we can also get rid of non-patient related resources, such as PractitionerRole/Practitioner/Organization and the like -\->
                                    <xsl:copy-of select="$deleteStuff/f:action"/>
                                </teardown>-->
                            </TestScript>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- assume Send -->
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="{$idString}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} {$testScriptString/@long}"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} {$testScriptString/@long} for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes" nts:in-targets="Nictiz-intern"/>
                                <!--<xsl:copy-of select="$deleteStuff/f:variable"/>-->
                                <test id="{$testId}">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="Specifies the query to run and general checks on the request."/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://terminology.hl7.org/CodeSystem/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test client to POST a Bundle of type transaction."/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <xsl:if test="count($identifyResources) gt 0">
                                                <requestId value="transaction-request"/>
                                            </xsl:if>
                                            <!--<responseId value="transaction-response-fixture"/>-->
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <nts:include value="test.client.successfulTransaction" scope="common"/>
                                    <xsl:copy-of select="$includeNumResources"/>
                                </test>
                                
                                <xsl:if test="count($identifyResources) gt 0">
                                    <test id="{$testId}-identification">
                                        <name value="Resource identification"/>
                                        <description value="Checks if all resources specified by the scenario can be identified unambiguously."/>
                                        <xsl:copy-of select="$identifyResources"/>
                                    </test>
                                </xsl:if>
                                
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
                            </TestScript>

                        </xsl:otherwise>
                    </xsl:choose>
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
    
    <xsl:template name="append-2-context">
        <xsl:param name="categoryCode"/>
        <xsl:param name="currentMPBouwsteen"/>
        <xsl:param name="mpBouwstenenSameProduct"/>
        
        <xsl:choose>
            <xsl:when test="$categoryCode = $maCodeMP920">
                <xsl:variable name="stopTypeCode" select="$currentMPBouwsteen/f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value"/>
                <xsl:variable name="reasonCode" select="$currentMPBouwsteen/f:reasonCode/f:coding/f:code/@value"/>
                <xsl:variable name="timingExact" select="$currentMPBouwsteen/f:dosageInstruction/f:timing/f:repeat/f:extension[@url = 'http://hl7.org/fhir/StructureDefinition/timing-exact']/f:valueBoolean/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- aanwezigheid stoptype uniek? -->
                    <xsl:when test="$stopTypeCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value = $stopTypeCode]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"/>
                    </xsl:when>
                    <!-- afwezigheid stoptype uniek? -->
                    <xsl:when test="not($stopTypeCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not())')"/>
                    </xsl:when>
                    <!-- aanwezigheid reden... uniek? -->
                    <xsl:when test="$reasonCode and count($mpBouwstenenSameProduct[f:reasonCode/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of select="concat('.where(reasonCode.coding.code = ''', $reasonCode, ''')')"/>
                    </xsl:when>
                    <!-- afwezigheid reden... uniek? -->
                    <xsl:when test="not($reasonCode) and count($mpBouwstenenSameProduct[not(f:reasonCode/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="'.where(reasonCode.exists().not())'"/>
                    </xsl:when>
                    <!-- MA-3: hoeveelheid dosageInstruction-elementen (komt in de basis overeen met hoeveelheid 'dosering'-elementen in ADA) uniek? -->
                    <xsl:when test="count($mpBouwstenenSameProduct[count(f:dosageInstruction) = count(current()/f:dosageInstruction)]) = 1">
                        <xsl:value-of select="concat('.where(dosageInstruction.count() = ', count(f:dosageInstruction), ')')"/>
                    </xsl:when>
                    <!-- MA-6: is_flexibel (exacte timing) uniek?-->
                    <xsl:when test="count($mpBouwstenenSameProduct[f:dosageInstruction/f:timing/f:repeat/f:extension[@url = 'http://hl7.org/fhir/StructureDefinition/timing-exact']/f:valueBoolean/@value = $timingExact]) = 1">
                        <xsl:value-of select="concat('.where(dosageInstruction.timing.repeat.extension.where(url = ''http://hl7.org/fhir/StructureDefinition/timing-exact'').value = ', $timingExact, ')')"/>
                    </xsl:when>
                    <!-- aanwezigheid stoptype en reden... uniek? -->
                    <xsl:when test="$stopTypeCode and $reasonCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value  = $stopTypeCode and f:reasonCode/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"/>
                        <xsl:value-of select="concat('.where(reasonCode.coding.code = ''', $reasonCode, ''')')"/>
                    </xsl:when>
                    <!-- afwezigheid stoptype en reden... uniek? -->
                    <xsl:when test="not($stopTypeCode) and not($reasonCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value) and not(f:reasonCode/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not()).where(reasonCode.exists().not())')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $mgbCode">
                <xsl:variable name="stopTypeCode" select="$currentMPBouwsteen/f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value"/>
                <xsl:variable name="asAgreedIndicator" select="$currentMPBouwsteen/f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value"/>
                <xsl:variable name="timingExact" select="$currentMPBouwsteen/f:dosage/f:timing/f:repeat/f:extension[@url = 'http://hl7.org/fhir/StructureDefinition/timing-exact']/f:valueBoolean/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- aanwezigheid stoptype uniek? -->
                    <xsl:when test="$stopTypeCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value = $stopTypeCode]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"/>
                    </xsl:when>
                    <!-- afwezigheid stoptype uniek? -->
                    <xsl:when test="not($stopTypeCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not())')"/>
                    </xsl:when>
                    <xsl:when test="$asAgreedIndicator and count($mpBouwstenenSameProduct[f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value = $asAgreedIndicator]) = 1">
                        <xsl:value-of select="concat('.where(extension.where(url = ''', $urlExtAsAgreedIndicator, ''').value = ', $asAgreedIndicator, ')')"/>
                    </xsl:when>
                    <xsl:when test="not($asAgreedIndicator) and count($mpBouwstenenSameProduct[not(f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value)]) = 1">
                        <xsl:value-of select="concat('.where(extension.where(url = ''', $urlExtAsAgreedIndicator, ''').exists().not())')"/>
                    </xsl:when>
                    <!-- MGB-6: is_flexibel (exacte timing) uniek?-->
                    <xsl:when test="$timingExact and count($mpBouwstenenSameProduct[f:dosage/f:timing/f:repeat/f:extension[@url = 'http://hl7.org/fhir/StructureDefinition/timing-exact']/f:valueBoolean/@value = $timingExact]) = 1">
                        <xsl:value-of select="concat('.where(dosageInstruction.timing.repeat.extension.where(url = ''http://hl7.org/fhir/StructureDefinition/timing-exact'').value = ', $timingExact, ')')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $mtdCode">
                <xsl:variable name="reasonCode" select="$currentMPBouwsteen/f:extension[@url = $urlExtMedicationAdministration2ReasonForDeviation]/f:valueCodeableConcept/f:coding/f:code/@value"/>
                <xsl:variable name="asAgreedIndicator" select="$currentMPBouwsteen/f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- aanwezigheid reden... uniek? -->
                    <xsl:when test="$reasonCode and count($mpBouwstenenSameProduct[f:extension[@url = $urlExtMedicationAdministration2ReasonForDeviation]/f:valueCodeableConcept/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of select="concat('.where(extension.where(url = ''', $urlExtMedicationAdministration2ReasonForDeviation, ''').value.coding.code = ''', $reasonCode, ''')')"/>
                    </xsl:when>
                    <!-- afwezigheid reden... uniek? -->
                    <xsl:when test="not($reasonCode) and count($mpBouwstenenSameProduct[not(f:extension[@url = $urlExtMedicationAdministration2ReasonForDeviation]/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="concat('.where(extension.where(url = ''', $urlExtMedicationAdministration2ReasonForDeviation, ''').exists().not())')"/>
                    </xsl:when>
                    <xsl:when test="$asAgreedIndicator and count($mpBouwstenenSameProduct[f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value = $asAgreedIndicator]) = 1">
                        <xsl:value-of select="concat('.where(extension.where(url = ''', $urlExtAsAgreedIndicator, ''').value = ', $asAgreedIndicator, ')')"/>
                    </xsl:when>
                    <xsl:when test="not($asAgreedIndicator) and count($mpBouwstenenSameProduct[not(f:extension[@url = $urlExtAsAgreedIndicator]/f:valueBoolean/@value)]) = 1">
                        <xsl:value-of select="concat('.where(extension.where(url = ''', $urlExtAsAgreedIndicator, ''').exists().not())')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $mveCode">
                <xsl:variable name="quantityValue" select="$currentMPBouwsteen/f:quantity/f:value/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- quantity is uniek -->
                    <xsl:when test="$quantityValue and count($mpBouwstenenSameProduct[f:quantity/f:value/@value = $quantityValue]) = 1">
                        <xsl:value-of select="concat('.where(quantity.value = ', $quantityValue, ')')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $taCode">
                <xsl:variable name="stopTypeCode" select="$currentMPBouwsteen/f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value"/>
                <xsl:variable name="reasonCode" select="$currentMPBouwsteen/f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value"/>
                
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <!-- aanwezigheid stoptype uniek? -->
                    <xsl:when test="$stopTypeCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value = $stopTypeCode]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"/>
                    </xsl:when>
                    <!-- afwezigheid stoptype uniek? -->
                    <xsl:when test="not($stopTypeCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not())')"/>
                    </xsl:when>
                    <!-- aanwezigheid reden... uniek? -->
                    <xsl:when test="$reasonCode and count($mpBouwstenenSameProduct[f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of select="concat('.where(extension.where(url = ''', 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation', ''').value.coding.code = ''', $reasonCode, ''')')"/>
                    </xsl:when>
                    <!-- afwezigheid reden... uniek? -->
                    <xsl:when test="not($reasonCode) and count($mpBouwstenenSameProduct[not(f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="concat('.where(extension.where(url = ''', 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation', ''').exists().not())')"/>
                    </xsl:when>
                    
                    <!-- dosageInstruction.timing.repeat.frequency/.when? -->
                    <!-- aanwezigheid stoptype en reden... uniek? -->
                    <xsl:when test="$stopTypeCode and $reasonCode and count($mpBouwstenenSameProduct[f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value  = $stopTypeCode and f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value = $reasonCode]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').value.coding.code = ''', $stopTypeCode, ''')')"/>
                        <xsl:value-of select="concat('.where(extension.where(url = ''', 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation', ''').value.coding.code = ''', $reasonCode, ''')')"/>
                    </xsl:when>
                    <!-- afwezigheid stoptype en reden... uniek? -->
                    <xsl:when test="not($stopTypeCode) and not($reasonCode) and count($mpBouwstenenSameProduct[not(f:modifierExtension[@url = $urlExtStoptype]/f:valueCodeableConcept/f:coding/f:code/@value) and not(f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation']/f:valueCodeableConcept/f:coding/f:code/@value)]) = 1">
                        <xsl:value-of select="concat('.where(modifierExtension.where(url = ''', $urlExtStoptype, ''').exists().not()).where(extension.where(url = ''', 'http://nictiz.nl/fhir/StructureDefinition/ext-AdministrationAgreement.ReasonModificationOrDiscontinuation', ''').exists().not())')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $vvCode">
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$categoryCode = $wdsCode">
                <xsl:choose>
                    <!-- is er één bouwsteen ? dan hoeven we niets toe te voegen-->
                    <xsl:when test="count($mpBouwstenenSameProduct) = 1"/>
                    <xsl:otherwise>
                        <xsl:message>Count 1 not reached: <xsl:value-of select="count($mpBouwstenenSameProduct)"/> - <xsl:value-of select="string-join($mpBouwstenenSameProduct/(f:id/@value, ancestor::f:entry/f:fullUrl/@value)[1], ', ')"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Building block not supported (yet)</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
