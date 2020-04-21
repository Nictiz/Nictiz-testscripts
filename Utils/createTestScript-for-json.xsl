<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:f="http://hl7.org/fhir" exclude-result-prefixes="#all" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Updated on:</xd:b> 2020-19-04</xd:p>
            <xd:p><xd:b>Author:</xd:b> Nictiz (AT, JD)</xd:p>
            <xd:p><xd:b>Description:</xd:b>Stylesheet is used to transform XIS TestScripts to allow JSON testing. This stylesheet copies the testscript and replaces xml|XML keywords at specific places.</xd:p>/>
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="yes" omit-xml-declaration="yes"/>
        
    <!--identity transformation-->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- replace all accept headers with json -->
    <xsl:template match="/f:TestScript/f:test/f:action/f:operation/f:accept/@value">
        <xsl:attribute name="value">
            <xsl:text>json</xsl:text>
        </xsl:attribute>
    </xsl:template>
    
    <!-- find and replace xml or XML with json/JSOn in the following elements:
    1.   .id
    2.   .url
    3.   .name
    4.   .description
    5.   .test.description
    6.   .test.action.operation.description
    -->
    
    <!-- 1. .id -->
    <xsl:template match="/f:TestScript/f:id/@value">
        <xsl:choose>
            <xsl:when test="matches(.,'xml')">
                <xsl:attribute name="value">
                    <xsl:value-of select="replace(.,'xml', 'json')"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- 2. .url -->
    <xsl:template match="/f:TestScript/f:url/@value">
        <xsl:choose>
            <xsl:when test="matches(.,'xml')">
                <xsl:attribute name="value">
                    <xsl:value-of select="replace(.,'xml', 'json')"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- 3. .name -->
    <xsl:template match="/f:TestScript/f:name/@value">
        <xsl:choose>
            <xsl:when test="matches(.,'(xml|XML)')">
                <xsl:attribute name="value">
                    <xsl:value-of select="replace(.,'(xml|XML)','JSON')"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- 4. .description -->
    <xsl:template match="/f:TestScript/f:description/@value">
        <xsl:choose>
            <xsl:when test="matches(.,'(xml|XML)')">
                <xsl:attribute name="value">
                    <xsl:value-of select="replace(.,'(xml|XML)','JSON')"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- 5. .test.description -->
    <xsl:template match="/f:TestScript/f:test/f:description/@value">
        <xsl:choose>
            <xsl:when test="matches(.,'(xml|XML)')">
                <xsl:attribute name="value">
                    <xsl:value-of select="replace(.,'(xml|XML)','JSON')"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
      
    <!-- 6. .test.action.operation.description -->
    <xsl:template match="/f:TestScript/f:test/f:action/f:operation/f:description/@value">
        <xsl:choose>
            <xsl:when test="matches(.,'(xml|XML)')">
                <xsl:attribute name="value">
                    <xsl:value-of select="replace(.,'(xml|XML)','JSON')"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>