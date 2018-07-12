<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:f="http://hl7.org/fhir" exclude-result-prefixes="#all" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jul 11, 2018</xd:p>
            <xd:p><xd:b>Author:</xd:b> ahenket</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc/>
        <xd:param name="bundletype"/>
        <xd:param name="outputid"/>
        <xd:param name="entries"/>
        <xd:param name="outputdir"/>
        <xd:param name="outputfilename"/>
    </xd:doc>
    <xsl:template name="writeBundle">
        <xsl:param name="outputdir" as="xs:string" required="yes"/>
        <xsl:param name="outputfilename" as="xs:string" required="yes"/>
        <xsl:param name="bundletype" as="xs:string" required="yes"/>
        <xsl:param name="outputid" as="xs:string" required="yes"/>
        <xsl:param name="entries" required="yes" as="element()*"/>
        <xsl:message>    Writing FHIR Bundle into <xsl:value-of select="concat($outputdir, $outputfilename)"/>.</xsl:message>
        <xsl:result-document href="{concat($outputdir, $outputfilename)}" indent="yes" method="xml" omit-xml-declaration="yes" exclude-result-prefixes="#all">
            <xsl:comment>Generated at <xsl:value-of select="current-dateTime()"/></xsl:comment>
            <xsl:text>&#10;</xsl:text>
            <xsl:call-template name="createBundle">
                <xsl:with-param name="bundletype" select="$bundletype"/>
                <xsl:with-param name="outputid" select="$outputid"/>
                <xsl:with-param name="entries" select="$entries"/>
            </xsl:call-template>
        </xsl:result-document>
    </xsl:template>
    
    <xd:doc>
        <xd:desc/>
        <xd:param name="bundletype"/>
        <xd:param name="outputid"/>
        <xd:param name="entries"/>
    </xd:doc>
    <xsl:template name="createBundle">
        <xsl:param name="bundletype" as="xs:string" required="yes"/>
        <xsl:param name="outputid" as="xs:string" required="yes"/>
        <xsl:param name="entries" required="yes" as="element()*"/>
        <xsl:message>    Creating FHIR Bundle of type <xsl:value-of select="$bundletype"/> with <xsl:value-of select="count($entries)"/> entries.</xsl:message>
        
        <xsl:variable name="resourceMap" as="element()*">
            <xsl:for-each select="$entries">
                <id type="{local-name()}" id="{f:id/@value}" typeId="{concat(local-name(),'/',f:id/@value)}" urn="urn:oid:2.16.840.1.113883.2.4.3.11.9999.{position()}"/>
            </xsl:for-each>
        </xsl:variable>
        
        <Bundle xmlns="http://hl7.org/fhir">
            <id value="{$outputid}"/>
            <type value="{$bundletype}"/>
            <xsl:if test="$bundletype = ('searchset', 'history')">
                <total value="{count($entries)}"/>
            </xsl:if>
            <xsl:for-each select="$entries">
                <xsl:variable name="resourceType" as="xs:string" select="local-name()"/>
                <xsl:variable name="resourceId" as="xs:string" select="f:id/@value"/>
                
                <xsl:comment><xsl:value-of select="$resourceId"/></xsl:comment>
                <entry>
                    <fullUrl value="{$resourceMap[@type = $resourceType][@id = $resourceId]/@urn}"/>
                    <resource>
                        <xsl:apply-templates select="." mode="rewrite-reference">
                            <xsl:with-param name="resourceMap" select="$resourceMap"/>
                        </xsl:apply-templates>
                    </resource>
                    <xsl:if test="$bundletype = ('batch', 'transaction', 'history')">
                        <request>
                            <!-- create -->
                            <method value="POST"/>
                            <url value="{local-name()}"/>
                            <!--<ifNoneExist value="code={encode-for-uri(concat(f:code/f:coding[1]/f:system/@value,'|',f:code/f:coding[1]/f:code/@value))}&amp;date={encode-for-uri(f:effectiveDateTime/@value)}"/>-->
                        </request>
                    </xsl:if>
                </entry>
            </xsl:for-each>
        </Bundle>
    </xsl:template>
    
    <xd:doc>
        <xd:desc/>
        <xd:param name="resourceMap"/>
    </xd:doc>
    <xsl:template match="f:reference/@value" mode="rewrite-reference">
        <xsl:param name="resourceMap" as="element()*" required="yes"/>
        <xsl:variable name="referenceValue" select="."/>
        <xsl:choose>
            <xsl:when test="$resourceMap[@typeId = $referenceValue]">
                <xsl:attribute name="value" select="$resourceMap[@typeId = $referenceValue]/@urn"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>    WARNING: Found reference with value '<xsl:value-of select="$referenceValue"/>' that we do not have a map value for. Missing Bundle contents?</xsl:message>
                <xsl:copy copy-namespaces="no"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc/>
        <xd:param name="resourceMap"/>
    </xd:doc>
    <xsl:template match="node() | @*" mode="rewrite-reference">
        <xsl:param name="resourceMap" as="element()*" required="yes"/>
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="node() | @*" mode="rewrite-reference">
                <xsl:with-param name="resourceMap" select="$resourceMap"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
