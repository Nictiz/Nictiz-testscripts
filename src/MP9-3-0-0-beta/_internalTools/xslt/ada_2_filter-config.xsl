<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns="" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:util="urn:hl7:utilities" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="*"/>

    <xsl:param name="adaDir" as="xs:string?" select="'../../../../../art_decor/adarefs2ada/mp/9.3.0/raadplegen_medicatiegegevens/ada_instance'"/>
    <!-- parameters from ant are one string  -->
    <xsl:param name="antTestGoal" as="xs:string?" select="'test,cert'"/>
    
    <xsl:variable name="testGoal" as="xs:string*">
        <xsl:choose>
            <xsl:when test="string-length($antTestGoal) gt 0"><xsl:sequence select="tokenize(normalize-space(lower-case($antTestGoal)), ',')"/></xsl:when>
            <xsl:otherwise><xsl:sequence select="('test', 'cert')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="adaFiles" as="node()*">
        <xsl:sequence select="collection($adaDir || '?select=*.xml')"/>
    </xsl:variable>

    <xsl:variable name="mapBouwsteenConfig" as="element(map)*">
        <map bouwsteenType="Medicatieafspraak" elementName="MedicationAgreement" oidPart="16076005"/>
        <map bouwsteenType="Medicatiegebruik" elementName="MedicationUse" oidPart="6"/>
        <map bouwsteenType="Medicatietoediening" elementName="MedicationAdministration" oidPart="18629005"/>
        <map bouwsteenType="Medicatieverstrekking" elementName="MedicationDispense" oidPart="373784005"/>
        <map bouwsteenType="Toedieningsafspraak" elementName="AdministrationAgreement" oidPart="422037009"/>
        <map bouwsteenType="Verstrekkingsverzoek" elementName="DispenseRequest" oidPart="52711000146108"/>
        <map bouwsteenType="WisselendDoseerschema" elementName="VariableDosingRegimen" oidPart="632"/>
    </xsl:variable>

    <xsl:template match="/">

        <ScenarioSet0or10>
            
            <xsl:if test="$testGoal = 'test'">
                <Test>
                    <xsl:call-template name="makeFilterConfig">
                        <xsl:with-param name="adaFiles" select="$adaFiles//raadplegen_medicatiegegevens[contains(@id, '-tst-')]"/>
                    </xsl:call-template>
                </Test>
            </xsl:if>

            <xsl:if test="$testGoal = 'cert'">
                <Cert>
                    <xsl:call-template name="makeFilterConfig">
                        <xsl:with-param name="adaFiles" select="$adaFiles//raadplegen_medicatiegegevens[contains(@id, '-kwal-')]"/>
                    </xsl:call-template>
                </Cert>
            </xsl:if>
            
        </ScenarioSet0or10>
    </xsl:template>

    <xsl:template name="makeFilterConfig">
        <xsl:param name="adaFiles" as="element()*"/>

        <Retrieve>
            <xsl:for-each-group select="$adaFiles" group-by="type/@value">

                <xsl:variable name="fhirParamString" as="xs:string?"/>

                <xsl:element name="{$mapBouwsteenConfig[@bouwsteenType = current-grouping-key()]/@elementName}">
                    <xsl:for-each select="current-group()/subscenario">

                        <TestScript>
                            <scenarioFullNumber value="{scenario-nr/@value}"/>
                            <params value="{string-join(nf:makeFhirParam(query_parameters, current-grouping-key()), '')}"/>
                        </TestScript>
                    </xsl:for-each>
                </xsl:element>

            </xsl:for-each-group>
        </Retrieve>
        <Serve>
            <xsl:for-each-group select="$adaFiles" group-by="type/@value">

                <xsl:variable name="fhirParamString" as="xs:string?"/>
                <xsl:variable name="elName" select="$mapBouwsteenConfig[@bouwsteenType = current-grouping-key()]/@elementName"/>

                <xsl:element name="{$elName}">
                    <xsl:for-each select="current-group()/subscenario">

                        <TestScript>
                            <scenarioFullNumber value="{scenario-nr/@value}"/>

                            <xsl:choose>
                                <xsl:when test="query_parameters/identificatie_517">
                                    <params value="&amp;identifier=${{filter-identifier}}"/>
                                    <include>
                                        <f:variable>
                                            <f:name value="filter-identifier"/>
                                            <f:defaultValue value="{concat('urn:oid:2.16.840.1.113883.2.4.3.11.999.77.', $mapBouwsteenConfig[@bouwsteenType = current-grouping-key()]/@oidPart ,'.1|', query_parameters/identificatie_517/@value)}"/>
                                            <f:description value="{concat('Filter on specific ', $elName, ' identifier')}"/>
                                        </f:variable>
                                    </include>
                                </xsl:when>
                                <xsl:when test="query_parameters/identificatie_mbh">
                                    <params value="&amp;pharmaceutical-treatment-identifier=${{filter-identifier}}"/>
                                    <include>
                                        <f:variable>
                                            <f:name value="filter-identifier"/>
                                            <f:defaultValue value="{concat('urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|', query_parameters/identificatie_mbh/@value)}"/>
                                            <f:description value="Filter on specific pharmaceutical treatment identifier"/>
                                        </f:variable>
                                    </include>
                                </xsl:when>
                                <xsl:otherwise>
                                    <params value="{string-join(nf:makeFhirParam(query_parameters, current-grouping-key()), '')}"/>
                                </xsl:otherwise>
                            </xsl:choose>

                        </TestScript>
                    </xsl:for-each>
                </xsl:element>

            </xsl:for-each-group>
        </Serve>

    </xsl:template>

    <xsl:function name="nf:makeFhirParam" as="xs:string*">
        <xsl:param name="inAda" as="element()?"/>
        <xsl:param name="bouwsteenType" as="xs:string?"/>


        <xsl:for-each select="$inAda/identificatie_517">
            <xsl:value-of select="concat('&amp;identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.', $mapBouwsteenConfig[@bouwsteenType = $bouwsteenType]/@oidPart ,'.1|', @value)"/>
        </xsl:for-each>

        <xsl:for-each select="$inAda/product_code">
            <xsl:value-of select="concat('&amp;medication.code=urn:oid:', @codeSystem, '|', @code)"/>
        </xsl:for-each>

        <xsl:for-each select="$inAda/gebruiksperiode[*]">
            <xsl:variable name="periodParam" as="node()*">
                <xsl:choose>
                    <xsl:when test="ingangsdatum[@value] and einddatum[@value]">
                        <periodParam operator="ge" dateDays="{substring-before(substring-after(ingangsdatum/@value, 'T'), 'D')}"/>
                        <periodParam operator="le" dateDays="{substring-before(substring-after(einddatum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                    <xsl:when test="ingangsdatum[@value]">
                        <periodParam operator="ge" dateDays="{substring-before(substring-after(ingangsdatum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                    <xsl:when test="einddatum[@value]">
                        <periodParam operator="le" dateDays="{substring-before(substring-after(einddatum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>

            <xsl:for-each select="$periodParam">
                <xsl:value-of select="concat('&amp;period-of-use=', @operator, '${DATE, T, D,', @dateDays,'}')"/>
            </xsl:for-each>
        </xsl:for-each>

        <xsl:for-each select="$inAda/toedieningsperiode[*]">
            <xsl:variable name="periodParam" as="node()*">
                <xsl:choose>
                    <xsl:when test="begin_datum[@value] and eind_datum[@value]">
                        <periodParam operator="ge" dateDays="{substring-before(substring-after(begin_datum/@value, 'T'), 'D')}"/>
                        <periodParam operator="le" dateDays="{substring-before(substring-after(eind_datum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                    <xsl:when test="begin_datum[@value]">
                        <periodParam operator="ge" dateDays="{substring-before(substring-after(begin_datum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                    <xsl:when test="eind_datum[@value]">
                        <periodParam operator="le" dateDays="{substring-before(substring-after(eind_datum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>

            <xsl:for-each select="$periodParam">
                <xsl:value-of select="concat('&amp;effective-time=', @operator, '${DATE, T, D,', @dateDays,'}')"/>
            </xsl:for-each>
        </xsl:for-each>

        <xsl:for-each select="$inAda/verstrekkingsperiode[*]">
            <xsl:variable name="periodParam" as="node()*">
                <xsl:choose>
                    <xsl:when test="begindatum[@value] and einddatum[@value]">
                        <periodParam operator="ge" dateDays="{substring-before(substring-after(begindatum/@value, 'T'), 'D')}"/>
                        <periodParam operator="le" dateDays="{substring-before(substring-after(einddatum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                    <xsl:when test="begindatum[@value]">
                        <periodParam operator="ge" dateDays="{substring-before(substring-after(begindatum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                    <xsl:when test="einddatum[@value]">
                        <periodParam operator="lt" dateDays="{substring-before(substring-after(einddatum/@value, 'T'), 'D')}"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>

            <xsl:for-each select="$periodParam">
                <xsl:value-of select="concat('&amp;whenhandedover=', @operator, '${DATE, T, D,', @dateDays,'}')"/>
            </xsl:for-each>
        </xsl:for-each>


        <xsl:for-each select="$inAda/identificatie_mbh">
            <xsl:value-of select="concat('&amp;pharmaceutical-treatment-identifier=urn:oid:2.16.840.1.113883.2.4.3.11.999.77.1.1|', @value)"/>
        </xsl:for-each>


    </xsl:function>




</xsl:stylesheet>
