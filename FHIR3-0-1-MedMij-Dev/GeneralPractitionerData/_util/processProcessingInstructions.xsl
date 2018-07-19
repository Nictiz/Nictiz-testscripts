<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:f="http://hl7.org/fhir"
    xmlns:local="urn:nictiz-nl:functions"
    exclude-result-prefixes="#all"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jul 19, 2018</xd:p>
            <xd:p><xd:b>Author:</xd:b> ahenket</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:param name="T" select="substring(string(current-date()), 1, 10)"/>
    <xsl:param name="outputDir">../_reference/resources-query-send</xsl:param>
    
    <xsl:variable name="opDir">
        <xsl:choose>
            <xsl:when test="ends-with($outputDir, '/')"><xsl:value-of select="$outputDir"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($outputDir,'/')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:include href="_include/functions.xsl"/>
    
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>    Processing using <xsl:value-of select="$T"/> as base date</xsl:message>
        <xsl:result-document href="{concat($opDir,tokenize(document-uri(.), '/')[last()])}" indent="yes" omit-xml-declaration="yes" method="xml" exclude-result-prefixes="#all">
            <xsl:comment>Processed using <xsl:value-of select="$T"/> as base date to calculate against.</xsl:comment>
            <xsl:apply-templates/>
        </xsl:result-document>
    </xsl:template>
    
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="processing-instruction()[name() = 'param']">
        <xsl:variable name="period" select="string(.)"/>
        <xsl:variable name="newdate" select="local:calculateDate($T, $period)"/>
        <xsl:choose>
            <xsl:when test="parent::*/namespace-uri() = 'http://www.w3.org/1999/xhtml'">
                <xsl:value-of select="$newdate"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="value" select="$newdate"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="node() | @*">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>