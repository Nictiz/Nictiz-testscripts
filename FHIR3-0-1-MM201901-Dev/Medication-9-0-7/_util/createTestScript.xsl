<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:f="http://hl7.org/fhir" exclude-result-prefixes="#all" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Updated on:</xd:b> Jun 11, 2018</xd:p>
            <xd:p><xd:b>Author:</xd:b> Nictiz (AHE, AWE)</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>

    <xsl:output indent="yes" omit-xml-declaration="yes"/>

    <xsl:param name="inputDir1">../_reference</xsl:param>

    <xsl:variable name="ipDir1">
        <xsl:choose>
            <xsl:when test="ends-with($inputDir1, '/')">
                <xsl:value-of select="$inputDir1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($inputDir1, '/')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="/">
        <xsl:variable name="xml1" select="collection(iri-to-uri(concat(resolve-uri($inputDir1), '?select=', '*.xml;recurse=yes')))/f:*"/>
        <xsl:processing-instruction name="xml-model">href="http://hl7.org/fhir/STU3/testscript.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron</xsl:processing-instruction>
        <TestScript xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hl7.org/fhir http://hl7.org/fhir/STU3/fhir-all.xsd" xmlns="http://hl7.org/fhir">
            <id value="Medication-9-0-7-fhir3-0-1-load-resources-createupdate-xml"/>
            <url value="http://nictiz.nl/fhir/fhir3-0-1/TestScript/Medication-9-0-7-fhir3-0-1-load-resources-createupdate-xml"/>
            <name value="NictizMedication-9-0-7 Load Test Resources - Create Update - XML"/>
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
            <description value="Load Medication-9-0-7 test resources using the update (PUT) operation of the target FHIR server for use in Medication-9-0-7 qualification testing. All resource ids are pre-defined. The target XIS FHIR server is expected to support resource create via the update (PUT) operation for client assigned ids."/>
            <copyright value="© Nictiz 2019"/>
            <xsl:for-each select="$xml1">
                <xsl:sort select="lower-case(concat(local-name(), '-', f:id/@value))"/>
                <xsl:variable name="resId" select="concat(local-name(), '-', replace(replace(f:id/@value, 'Bearer ', ''), '\s', ''))"/>
                <xsl:variable name="dn" select="document-uri(ancestor::node())"/>
                <fixture id="{$resId}-fx">
                    <resource>
                        <reference value="../_reference/{replace($dn, '.*/_reference/', '')}"/>
                    </resource>
                </fixture>
            </xsl:for-each>
            <xsl:for-each select="$xml1">
                <xsl:sort select="lower-case(concat(local-name(), '-', f:id/@value))"/>
                <xsl:variable name="resId" select="concat(local-name(), '-', replace(replace(f:id/@value, 'Bearer ', ''), '\s', ''))"/>
                <variable>
                    <name value="{$resId}-id"/>
                    <expression value="{local-name(.)}.id"/>
                    <sourceId value="{$resId}-fx"/>
                </variable>
            </xsl:for-each>

            <!-- No Setup -->
            <test id="Step1-LoadTestResourceCreate">
                <name value="Step1-LoadTestResourceCreate"/>
                <description value="Load Medication test resources using the update (PUT) operation of the target FHIR server for use in Medication qualification testing. All resource ids are pre-defined. The target XIS FHIR server is expected to support resource create via the update (PUT) operation for client assigned ids. "/>
                <xsl:for-each select="$xml1">
                    <xsl:sort select="lower-case(concat(local-name(), '-', f:id/@value))"/>
                    <xsl:variable name="resId" select="concat(local-name(), '-', replace(replace(f:id/@value, 'Bearer ', ''), '\s', ''))"/>
                    <xsl:variable name="dn" select="document-uri(ancestor::node())"/>
                    <!--                    <xsl:comment> Create <xsl:value-of select="$resId"/></xsl:comment>-->
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
                                <value value="Bearer d30f66ca-288d-44ea-aae0-659400d3ff42"/>
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
