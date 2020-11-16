<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns="http://hl7.org/fhir"
    xmlns:f="http://hl7.org/fhir"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:nts="http://nictiz.nl/xsl/testscript"
    exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="f:TestScript/f:test[@id='08-serve-CarePlan']/f:action/f:assert[f:label/@value='internalCount']">
        <assert>
            <label value="externalCount"/>
            <description value="Confirm that the returned searchset Bundle contains 1 CarePlan resource."/>
            <direction value="response"/>
            <expression value="Bundle.entry.where(resource.is(CarePlan)).count() = 1"/>
        </assert>
    </xsl:template>
    
</xsl:stylesheet>