<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:f="http://hl7.org/fhir"
    exclude-result-prefixes="#all"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jul 19, 2018</xd:p>
            <xd:p><xd:b>Author:</xd:b> ahenket</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="yes"/>
    
    <xsl:param name="inputDir1">../_reference/resources-query-send</xsl:param>
    <xsl:param name="inputDir2">../_reference/resources-generic</xsl:param>
    
    <xsl:variable name="ipDir1">
        <xsl:choose>
            <xsl:when test="ends-with($inputDir1, '/')"><xsl:value-of select="$inputDir1"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($inputDir1,'/')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ipDir2">
        <xsl:choose>
            <xsl:when test="ends-with($inputDir2, '/')"><xsl:value-of select="$inputDir2"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($inputDir2,'/')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="uriICPCNL1">http://hl7.org/fhir/sid/icpc-1-nl</xsl:variable>
    <xsl:variable name="uriJournaalRegelTypen">http://fhir.nl/fhir/NamingSystem/journaalregeltypen</xsl:variable>
    <xsl:variable name="uriExtensionEpisodeOfCareTitle">http://nictiz.nl/fhir/StructureDefinition/EpisodeOfCare-Title</xsl:variable>
    <xsl:variable name="profileDiagnosticResult">http://nictiz.nl/fhir/StructureDefinition/gp-DiagnosticResult</xsl:variable>
    <xsl:variable name="profileLaboratoryResult">http://nictiz.nl/fhir/StructureDefinition/gp-LaboratoryResult</xsl:variable>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="/">
        <xsl:variable name="xml1" select="collection(iri-to-uri(concat(resolve-uri($inputDir1),'?select=', '*.xml;recurse=no')))/f:*"/>
        <xsl:variable name="xml2" select="collection(iri-to-uri(concat(resolve-uri($inputDir2),'?select=', '*.xml;recurse=no')))/f:*"/>
        
        <xsl:processing-instruction name="xml-model">href="http://hl7.org/fhir/STU3/testscript.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron</xsl:processing-instruction>
        <TestScript xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hl7.org/fhir http://hl7.org/fhir/STU3/fhir-all.xsd" xmlns="http://hl7.org/fhir">
            <id value="medmij-gpdata-fhir3-0-1-load-resources-createupdate-xml"/>
            <url value="http://nictiz.nl/fhir/fhir3-0-1/TestScript/medmij-gpdata-fhir3-0-1-load-resources-createupdate-xml"/>
            <name value="Nictiz MedMij General Practitioner Data - Load Test Resources - Create Update - XML"/>
            <status value="active"/>
            <date value="{current-dateTime()}"/>
            <publisher value="Nictiz"/>
            <contact>
                <name value="Nictiz"/>
                <telecom>
                    <system value="email"/>
                    <value value="kwalificatie@nictiz.nl"/>
                    <use value="work"/>
                </telecom>
            </contact>
            <description value="[OPTIONAL] Load (create) MedMij General Practitioner Data test resources using the update (PUT) operation of the target FHIR server for use in qualification testing. All resource ids are pre-defined. The target XIS FHIR server is expected to support resource create via the update (PUT) operation for client assigned ids."/>
            <copyright value="© Nictiz 2018"/>
            <xsl:for-each select="$xml1 | $xml2">
                <xsl:variable name="resId" select="f:id/@value"/>
                <xsl:variable name="dn" select="document-uri(ancestor::node())"/>
                <fixture id="{$resId}-fx">
                    <resource>
                        <reference value="../_reference/{replace($dn, '.*/_reference/', '')}"/>
                    </resource>
                </fixture>
            </xsl:for-each>
            <fixture id="patient1-token-fixture">
                <resource>
                    <reference value="../_reference/medmij-gpdata-fhir3-0-1-Patient-Token-kwalificatie1.xml"/>
                </resource>
            </fixture>
            <variable>
                <name value="patient1-token-id"/>
                <expression value="Patient.id"/>
                <sourceId value="patient1-token-fixture"/>
            </variable>
            <xsl:for-each select="$xml1 | $xml2">
                <xsl:variable name="resId" select="f:id/@value"/>
                <variable>
                    <name value="{$resId}-id"/>
                    <expression value="{local-name(.)}.id"/>
                    <sourceId value="{$resId}-fx"/>
                </variable>
            </xsl:for-each>
            <!-- No Setup -->
            <test id="Step1-LoadTestResourceCreate">
                <name value="Step1-LoadTestResourceCreate"/>
                <description value="[OPTIONAL] Load (create) MedMij General Practitioner Data test resources using the update (PUT) operation of the target FHIR server for use in qualification testing."/>
                <xsl:for-each select="$xml1 | $xml2">
                    <xsl:variable name="resId" select="f:id/@value"/>
                    <xsl:comment> Create <xsl:value-of select="$resId"/></xsl:comment>
                    <action>
                        <operation>
                            <type>
                                <system value="http://hl7.org/fhir/testscript-operation-codes"/>
                                <code value="updateCreate"/>
                            </type>
                            <resource value="{local-name(.)}"/>
                            <accept value="xml"/>
                            <contentType value="xml"/>
                            <params value="/${{{$resId}-id}}"/>
                            <requestHeader>
                                <!-- 0..* Each operation can have one or more header elements -->
                                <field value="Authorization"/>
                                <!-- 1..1 HTTP header field name: OAuth access token -->
                                <value value="${{patient1-token-id}}"/>
                                <!-- 1..1 HTTP headerfield value: UUID4 -->
                            </requestHeader>
                            <sourceId value="{$resId}-fx"/>
                        </operation>
                    </action>
                    <action>
                        <assert>
                            <description value="Confirm that the returned HTTP status is 200(OK) or 201(Created)."/>
                            <operator value="in"/>
                            <responseCode value="200,201"/>
                        </assert>
                    </action>
                </xsl:for-each>
            </test>
        </TestScript>
    </xsl:template>
</xsl:stylesheet>