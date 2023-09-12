<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output indent="yes"/>
    
    <!-- r3 or r4 -->
    <!--<xsl:param name="fhirVersion" select="'r3'"/>-->
    <xsl:param name="fhirVersion" select="'r4'"/>
    
    <xsl:template match="/">
        <xsl:variable name="packagePage">
            <xsl:choose>
                <xsl:when test="$fhirVersion = 'r3'">
                    <xsl:copy-of select="document('hl7.fhir.r3.core_3.0.2_files-table.xml')"/>
                </xsl:when>
                <xsl:when test="$fhirVersion = 'r4'">
                    <xsl:copy-of select="document('hl7.fhir.r4.core_4.0.1_files-table.xml')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:for-each select="$packagePage/table/tbody/tr">
            <xsl:variable name="title" select="td[1]/@title"/>
            <xsl:if test="td[4][normalize-space(string-join(text())) = 'Profile on']/b/text() = $title">
                <xsl:variable name="fileName" select="substring-after(td[2]/@title, 'http://hl7.org/fhir/StructureDefinition/')"/>
                <xsl:variable name="fileId">
                    <xsl:choose>
                        <xsl:when test="$fhirVersion = 'r3'">
                            <xsl:value-of select="substring-after(td[1]/a/@href, '/packages/hl7.fhir.r3.core/3.0.2/files/')"/>
                        </xsl:when>
                        <xsl:when test="$fhirVersion = 'r4'">
                            <xsl:value-of select="substring-after(td[1]/a/@href, '/packages/hl7.fhir.r4.core/4.0.1/files/')"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="href">
                    <xsl:choose>
                        <xsl:when test="$fhirVersion = 'r3'">
                            <xsl:value-of select="concat('../stu3/', $fileName, '.xml')"/>
                        </xsl:when>
                        <xsl:when test="$fhirVersion = 'r4'">
                            <xsl:value-of select="concat('../r4/', $fileName, '.xml')"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:result-document href="{$href}">
                    <xsl:copy-of select="document(concat('https://simplifier.net/ui/packagefile/downloadsnapshotas?packageFileId=', $fileId, '&amp;format=xml'))"/>
                </xsl:result-document>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>