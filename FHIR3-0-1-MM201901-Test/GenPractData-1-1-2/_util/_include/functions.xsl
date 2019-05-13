<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
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
    
    <xd:doc>
        <xd:desc>Returns subtraction of <xd:ref name="duration" type="parameter"/> from <xd:ref name="offset" type="parameter"/></xd:desc>
        <xd:param name="offset">yyyy-mm-dd</xd:param>
        <xd:param name="duration">PnnD</xd:param>
    </xd:doc>
    <xsl:function name="local:calculateDate">
        <xsl:param name="offset" as="xs:string"/>
        <xsl:param name="duration" as="xs:string"/>
        
        <xsl:value-of select="xs:date($offset) - xs:dayTimeDuration($duration)"/>
    </xsl:function>
</xsl:stylesheet>