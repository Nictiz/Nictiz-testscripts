<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:util="urn:hl7:utilities" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <!--Import mp specific constants (and package for underlying imports)-->
    <xsl:import href="https://raw.githubusercontent.com/Nictiz/HL7-mappings/MP920/ada_2_fhir-r4/mp/9.2.0/payload/mp_latest_package.xsl"/>
    <xsl:import href="https://raw.githubusercontent.com/Nictiz/HL7-mappings/MP920/util/mp-functions.xsl"/>
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="*"/>

    <xsl:param name="mappingsUrl4FhirFixtures"/>
    <xsl:param name="transactionType"/>

    <xsl:variable name="bsnSystem" select="$oidMap[@oid = $oidBurgerservicenummer]/@uri"/>

    <xd:doc>
        <xd:desc>Start template. Handles some ada transactions, converts them to nts. Very specific for each transaction.</xd:desc>
    </xd:doc>
    <xsl:template match="/">

        <xsl:variable name="adaTransaction" select="adaxml/data/*" as="element()*"/>

        <xsl:for-each select="$adaTransaction">
            <!-- find corresponding FHIR fixture based on adaId / filename -->
            <xsl:variable name="adaTransId" select="nf:removeSpecialCharacters(@id)"/>
            <xsl:variable name="fhirFixture" select="document(concat($mappingsUrl4FhirFixtures, '/', $adaTransId, '.xml'))"/>
            <xsl:variable name="fixturePatient" select="$fhirFixture//f:Patient[1]"/>

            <xsl:variable name="scenarioset" select="replace(scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$1')"/>
            <xsl:variable name="scenario" select="replace(scenario-nr/@value, '(\d+)\.(\d*[a-z]?)\*?\s?.*', '$2')"/>

            <xsl:variable name="ntsScenario" as="xs:string?">
                <xsl:choose>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = ('RETRIEVE', 'SEND')">client</xsl:when>
                    <xsl:when test="normalize-space(upper-case($transactionType)) = ('SERVE', 'RECEIVE')">server</xsl:when>
                    <xsl:otherwise>unknown</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:choose>
                <!-- pull raadplegen_medicatiegegevens beschikbaarstellen_medicatiegegevens -->
                <xsl:when test="./local-name() = ('beschikbaarstellen_medicatiegegevens') and normalize-space(upper-case($transactionType)) =  ('RETRIEVE', 'SERVE')">
                    <xsl:message terminate="yes">Pull medication data should call a separate XSLT</xsl:message>
                </xsl:when>
            
                <!-- push sturen_medicatiegegevens -->
                <xsl:when test="$adaTransaction/local-name() = ('sturen_medicatiegegevens') and normalize-space(upper-case($transactionType)) =  ('SEND', 'RECEIVE')">
                    <xsl:choose>
                        <!-- Receive -->
                        <xsl:when test="$ntsScenario = 'server'">
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-medicationdata-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} MedicationData"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} MedicationData for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-medicationdata">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} MedicationData in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test server to handle a Bundle of type transaction."/>
                                            <accept value="xml"/>
                                            <contentType value="xml"/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${{UUID}}"/>
                                            </requestHeader>
                                            <requestHeader>
                                                <field value="Prefer"/>
                                                <value value="return=representation"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- assume Send -->
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} MedicationData"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} MedicationData for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-medicationdata">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} MedicationData in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test client to POST a Bundle of type transaction."/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${UUID}"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>                            
                            
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                    
                <xsl:when test="$adaTransaction/self::sturen_medicatievoorschrift">
                    <xsl:choose>
                        <!-- Receive -->
                        <xsl:when test="$ntsScenario = 'server'">
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Prescription"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Prescription for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>

                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-prescription">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Prescription in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test server to handle a Bundle of type transaction."/>
                                            <accept value="xml"/>
                                            <contentType value="xml"/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${{UUID}}"/>
                                            </requestHeader>
                                            <requestHeader>
                                                <field value="Prefer"/>
                                                <value value="return=representation"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>

                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- assume Send -->
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Prescription"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Prescription for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>

                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-prescription">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Prescription in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test client to POST a Bundle of type transaction."/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${UUID}"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>


                        </xsl:otherwise>
                    </xsl:choose>


                </xsl:when>
                <xsl:when test="$adaTransaction/self::sturen_afhandeling_medicatievoorschrift">
                    <xsl:choose>
                        <!-- Receive -->
                        <xsl:when test="$ntsScenario = 'server'">
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-proc-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Prescription Processing"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Prescription Processing for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>

                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-prescription-processing">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Prescription Processing in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test server to handle a Bundle of type transaction."/>
                                            <accept value="xml"/>
                                            <contentType value="xml"/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${{UUID}}"/>
                                            </requestHeader>
                                            <requestHeader>
                                                <field value="Prefer"/>
                                                <value value="return=representation"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>

                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- assume Send -->
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Prescription Processing"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Prescription Processing for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>

                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-prescription-processing">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Prescription Processing in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test client to POST a Bundle of type transaction."/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${UUID}"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>


                        </xsl:otherwise>
                    </xsl:choose>


                </xsl:when>
                <xsl:when test="$adaTransaction/self::sturen_voorstel_medicatieafspraak">
                    <xsl:choose>
                        <!-- Receive -->
                        <xsl:when test="$ntsScenario = 'server'">
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-proc-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Proposal medication agreement"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Proposal medication agreement for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-proposal-ma">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Proposal medication agreement in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test server to handle a Bundle of type transaction."/>
                                            <accept value="xml"/>
                                            <contentType value="xml"/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${{UUID}}"/>
                                            </requestHeader>
                                            <requestHeader>
                                                <field value="Prefer"/>
                                                <value value="return=representation"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- assume Send -->
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Proposal medication agreement"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Proposal medication agreement for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-proposal-ma">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Proposal medication agreement in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test client to POST a Bundle of type transaction."/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${UUID}"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                            
                            
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    
                </xsl:when>
                <xsl:when test="$adaTransaction/self::sturen_antwoord_voorstel_medicatieafspraak">
                    <xsl:choose>
                        <!-- Receive -->
                        <xsl:when test="$ntsScenario = 'server'">
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-proc-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Reply proposal medication agreement"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Reply proposal medication agreement for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-reply-proposal-ma">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Reply proposal medication agreement in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test server to handle a Bundle of type transaction."/>
                                            <accept value="xml"/>
                                            <contentType value="xml"/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${{UUID}}"/>
                                            </requestHeader>
                                            <requestHeader>
                                                <field value="Prefer"/>
                                                <value value="return=representation"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- assume Send -->
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Reply proposal medication agreement"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Reply proposal medication agreement for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-reply-proposal-ma">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Reply proposal medication agreement in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test client to POST a Bundle of type transaction."/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${UUID}"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                            
                            
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    
                </xsl:when>
                <xsl:when test="$adaTransaction/self::sturen_voorstel_verstrekkingsverzoek">
                    <xsl:choose>
                        <!-- Receive -->
                        <xsl:when test="$ntsScenario = 'server'">
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-proc-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Proposal dispense request (verstrekkingsverzoek)"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Proposal dispense request (verstrekkingsverzoek) for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-proposal-vv">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Proposal dispense request (verstrekkingsverzoek) in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test server to handle a Bundle of type transaction."/>
                                            <accept value="xml"/>
                                            <contentType value="xml"/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${{UUID}}"/>
                                            </requestHeader>
                                            <requestHeader>
                                                <field value="Prefer"/>
                                                <value value="return=representation"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- assume Send -->
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Proposal dispense request (verstrekkingsverzoek)"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Proposal dispense request (verstrekkingsverzoek) for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-proposal-vv">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Proposal dispense request (verstrekkingsverzoek) in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test client to POST a Bundle of type transaction."/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${UUID}"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                            
                            
                        </xsl:otherwise>
                    </xsl:choose>
                    
                    
                </xsl:when>
                <xsl:when test="$adaTransaction/self::sturen_antwoord_voorstel_verstrekkingsverzoek">
                    <xsl:choose>
                        <!-- Receive -->
                        <xsl:when test="$ntsScenario = 'server'">
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-proc-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Reply proposal dispense request (verstrekkingsverzoek)"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Reply proposal dispense request (verstrekkingsverzoek) for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-reply-proposal-vv">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Reply proposal dispense request (verstrekkingsverzoek) in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test server to handle a Bundle of type transaction."/>
                                            <accept value="xml"/>
                                            <contentType value="xml"/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${{UUID}}"/>
                                            </requestHeader>
                                            <requestHeader>
                                                <field value="Prefer"/>
                                                <value value="return=representation"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
                            </TestScript>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- assume Send -->
                            <TestScript xmlns="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" nts:scenario="{$ntsScenario}">
                                <id value="mp9-prescr-{normalize-space(lower-case($transactionType))}-{$scenarioset}-{$scenario}"/>
                                <name value="MP9 - {nf:first-cap($ntsScenario)} - Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Reply proposal dispense request (verstrekkingsverzoek)"/>
                                <description value="Scenario {$scenarioset}.{$scenario} - {nf:first-cap($transactionType)} Reply proposal dispense request (verstrekkingsverzoek) for {$fixturePatient/f:name/f:text/@value}."/>
                                <nts:fixture id="{$adaTransId}" href="fixtures/{$adaTransId}.xml"/>
                                <nts:includeDateT value="yes"/>
                                
                                <test id="scenario{$scenarioset}-{$scenario}-{lower-case($transactionType)}-reply-proposal-vv">
                                    <name value="Scenario {$scenarioset}.{$scenario}"/>
                                    <description value="{nf:first-cap($transactionType)} Reply proposal dispense request (verstrekkingsverzoek) in a transaction Bundle"/>
                                    <action>
                                        <operation>
                                            <type>
                                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                                <code value="transaction"/>
                                            </type>
                                            <description value="Test client to POST a Bundle of type transaction."/>
                                            <destination value="1"/>
                                            <origin value="1"/>
                                            <requestHeader>
                                                <field value="MP9-Request-ID"/>
                                                <value value="${UUID}"/>
                                            </requestHeader>
                                            <sourceId value="{$adaTransId}"/>
                                        </operation>
                                    </action>
                                    <xsl:for-each-group select="$fhirFixture/f:Bundle/f:entry/f:resource/f:*" group-by="local-name()">
                                        <nts:include value="assert.request.numResources" scope="common" resource="{current-grouping-key()}" count="{count(current-group())}"/>
                                    </xsl:for-each-group>
                                </test>
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
        <xd:desc>Capitalize first letter of a string</xd:desc>
        <xd:param name="in">The string to be handled</xd:param>
    </xd:doc>
    <xsl:function name="nf:first-cap" as="xs:string?">
        <xsl:param name="in" as="xs:string?"/>
        <xsl:sequence select="concat(upper-case(substring($in, 1, 1)), substring($in, 2))"/>
    </xsl:function>

</xsl:stylesheet>
