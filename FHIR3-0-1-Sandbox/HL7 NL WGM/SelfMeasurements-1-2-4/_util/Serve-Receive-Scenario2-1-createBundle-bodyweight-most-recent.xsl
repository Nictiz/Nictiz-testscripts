<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:f="http://hl7.org/fhir" exclude-result-prefixes="#all" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jul 11, 2018</xd:p>
            <xd:p><xd:b>Author:</xd:b> ahenket</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    
    <xsl:include href="_include/createBundle.xsl"/>
    
    <xsl:param name="bundletype">batch</xsl:param>
    <xsl:param name="inputdir" select="'../_reference/resources-serve-receive/'"/>
    <xsl:param name="outputdir" select="'../_reference/resources-serve-receive/'"/>
    
    <xsl:variable name="outputid">medmij-selfmeasurements-fhir3-0-1-scenario-2-1-bundle</xsl:variable>
    <xsl:variable name="outputfilename" select="concat($outputid, '.xml')"/>
    <xsl:variable name="patient-fixtures" as="xs:string+">
        <xsl:text>../_reference/resources-generic/medmij-selfmeasurements-fhir3-0-1-Patient-kwalificatie1.xml</xsl:text>
    </xsl:variable>
    <xsl:variable name="practitioner-fixtures" as="xs:string+">
        <xsl:text>../_reference/resources-generic/medmij-selfmeasurements-fhir3-0-1-Practitioner-kwalificatie1.xml</xsl:text>
    </xsl:variable>
    <xsl:variable name="observation-fixtures" as="xs:string+">
        <xsl:text>medmij-selfmeasurements-fhir3-0-1-BloodGlucose-kwalificatie1.xml</xsl:text>
        <xsl:text>medmij-selfmeasurements-fhir3-0-1-BloodGlucose-kwalificatie2.xml</xsl:text>
        <xsl:text>medmij-selfmeasurements-fhir3-0-1-BloodGlucose-kwalificatie3.xml</xsl:text>
        <xsl:text>medmij-selfmeasurements-fhir3-0-1-BloodPressure-kwalificatie1.xml</xsl:text>
        <xsl:text>medmij-selfmeasurements-fhir3-0-1-BloodPressure-kwalificatie2.xml</xsl:text>
        <xsl:text>medmij-selfmeasurements-fhir3-0-1-BodyWeight-kwalificatie1.xml</xsl:text>
        <xsl:text>medmij-selfmeasurements-fhir3-0-1-BodyWeight-kwalificatie2.xml</xsl:text>
    </xsl:variable>
    <xsl:variable name="allentries" as="element()*">
        <xsl:for-each select="$observation-fixtures">
            <xsl:variable name="file" select="concat($inputdir, .)"/>
            <xsl:variable name="xml" select="doc($file)/*" as="element()"/>
            <xsl:if test="$xml[self::f:Observation]/f:code/f:coding[f:system/@value = 'http://loinc.org'][f:code/@value = '29463-7']">
                <xsl:element name="{local-name($xml)}" namespace="http://hl7.org/fhir">
                    <xsl:copy-of select="$xml/*" copy-namespaces="no"/>
                </xsl:element>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="entries" as="element(f:Observation)*">
        <xsl:copy-of select="$allentries[f:effectiveDateTime/xs:date(substring(@value, 1, 10)) = max($allentries/f:effectiveDateTime/xs:date(substring(@value, 1, 10)))]"/>
    </xsl:variable>
    <xsl:variable name="allotherentries" as="element()*">
        <xsl:for-each select="$patient-fixtures, $practitioner-fixtures">
            <xsl:variable name="file" select="."/>
            <xsl:variable name="xml" select="doc($file)/*" as="element()"/>
            <xsl:if test="$xml[self::f:Patient | self::f:Practitioner]">
                <xsl:element name="{local-name($xml)}" namespace="http://hl7.org/fhir">
                    <xsl:copy-of select="$xml/*" copy-namespaces="no"/>
                </xsl:element>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="/">
        <xsl:call-template name="writeBundle">
            <xsl:with-param name="outputdir" select="$outputdir"/>
            <xsl:with-param name="outputfilename" select="$outputfilename"/>
            <xsl:with-param name="bundletype" select="$bundletype"/>
            <xsl:with-param name="outputid" select="$outputid"/>
            <xsl:with-param name="entries" select="$allotherentries | $entries"/>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
