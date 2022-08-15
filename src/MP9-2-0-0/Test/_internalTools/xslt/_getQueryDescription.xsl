<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nf="http://www.nictiz.nl/functions" xmlns:nts="http://nictiz.nl/xsl/testscript" xmlns:f="http://hl7.org/fhir"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:import href="ada_2_nts-medicationdata-pull.xsl"/>
    
    <xsl:param name="inputDirR" select="'C:\Users\144189-ADM\Documents\Git\Nictiz-testscripts\src\MP9-2-0-0\Test\MedicationData\Retrieve'"/>
    <xsl:variable name="inputDirRNormalized" select="nf:normalize-path($inputDirR)"/>
    
    <xsl:param name="inputDirS" select="'C:\Users\144189-ADM\Documents\Git\Nictiz-testscripts\src\MP9-2-0-0\Test\MedicationData\Serve'"/>
    <xsl:variable name="inputDirSNormalized" select="nf:normalize-path($inputDirS)"/>
    
    <xsl:template match="/">
        <!--<xsl:call-template name="util:logMessage">
            <xsl:with-param name="level" select="$logINFO"/>
            <xsl:with-param name="msg">transactionType: <xsl:value-of select="$transactionTypeNormalized"/> - inputDir: <xsl:value-of select="$inputDirNormalized"/> - outputDir: <xsl:value-of select="$outputDirNormalized"/></xsl:with-param>
        </xsl:call-template>-->
        
        <!-- Multiple steps of sorting:
            1. By building block
            2. By scenarioset
            3. By scenario -->
        <Output>
            <Retrieve input="{$inputDirRNormalized}">
                <xsl:for-each select="collection(concat($inputDirRNormalized, '?select=*.xml;recurse=yes'))">
                    <xsl:variable name="documentUri" select="document-uri(.)"/>
                    <xsl:variable name="buildingBlock" select="tokenize($documentUri,'/')[last()-1]"/>
                    <xsl:variable name="fileName" select="tokenize($documentUri,'/')[last()]"/>
                    
                    <xsl:variable name="description">
                        <xsl:variable name="value" select="./f:TestScript/(nts:include/nts:with-parameter[@name = 'scenarioDescription']/@value,f:description/@value)[1]"/>
                        <xsl:choose>
                            <xsl:when test="string-length($value) gt 0">
                                <xsl:value-of select="$value"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message terminate="yes">Please sort this <xsl:value-of select="$fileName"/></xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:variable name="params">
                        <xsl:variable name="value" select="./f:TestScript/(nts:include/nts:with-parameter[@name = 'scenarioParams']/@value,f:test/nts:include[@value = 'operation-search']/nts:with-parameter[@name = 'params']/@value)[1]"/>
                        <xsl:choose>
                            <xsl:when test="string-length($value) gt 0">
                                <xsl:value-of select="$value"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message terminate="yes">Please sort this <xsl:value-of select="$fileName"/></xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <TestScript buildingBlock="{$buildingBlock}" fileName="{$fileName}" description="{$description}" params="{$params}"/>
                </xsl:for-each>
            </Retrieve>
            <Serve>
                <xsl:for-each select="collection(concat($inputDirSNormalized, '?select=*.xml;recurse=yes'))">
                    <xsl:variable name="documentUri" select="document-uri(.)"/>
                    <xsl:variable name="buildingBlock" select="tokenize($documentUri,'/')[last()-1]"/>
                    <xsl:variable name="fileName" select="tokenize($documentUri,'/')[last()]"/>
                    
                    <xsl:variable name="description">
                        <xsl:variable name="value" select="./f:TestScript/(nts:include/nts:with-parameter[@name = 'scenarioDescription']/@value,f:description/@value)[1]"/>
                        <xsl:choose>
                            <xsl:when test="string-length($value) gt 0">
                                <xsl:value-of select="$value"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message terminate="yes">Please sort this <xsl:value-of select="$fileName"/></xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:variable name="params">
                        <xsl:variable name="value" select="./f:TestScript/(nts:include/nts:with-parameter[@name = 'scenarioParams']/@value,f:test/nts:include/nts:with-parameter[@name = 'params']/@value)[1]"/>
                        <xsl:choose>
                            <xsl:when test="string-length($value) gt 0">
                                <xsl:value-of select="$value"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message terminate="yes">Please sort this <xsl:value-of select="$fileName"/></xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <TestScript buildingBlock="{$buildingBlock}" fileName="{$fileName}" description="{$description}" params="{$params}"/>
                </xsl:for-each>
            </Serve>
        </Output>
        
        <!--<xsl:for-each select="collection(concat($inputDirNormalized, '?select=*.xml'))" group-by="substring-before(substring-after(./adaxml/data/beschikbaarstellen_medicatiegegevens/@id, 'mg-mp-mg-tst-'), '-Scenarioset')">
            <xsl:variable name="buildingBlockShort" select="current-grouping-key()"/>
            <xsl:for-each-group select="current-group()" group-by="replace(./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$1')">
                <xsl:variable name="scenarioset" select="xs:integer(current-grouping-key())"/>
                <xsl:choose>
                    <xsl:when test="$scenarioset = 0 and $transactionTypeNormalized = 'retrieve'">
                        <xsl:for-each-group select="current-group()" group-by="replace(./adaxml/data/beschikbaarstellen_medicatiegegevens/scenario-nr/@value, '(\d+)\.?(\d*[a-z]?)\*?\s?.*', '$2')">
                            <xsl:call-template name="createNts">
                                <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                                <xsl:with-param name="scenarioset" select="$scenarioset"/>
                            </xsl:call-template>
                        </xsl:for-each-group>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="createNts">
                            <xsl:with-param name="buildingBlockShort" select="$buildingBlockShort"/>
                            <xsl:with-param name="scenarioset" select="$scenarioset"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:for-each>-->
    </xsl:template>
    
</xsl:stylesheet>