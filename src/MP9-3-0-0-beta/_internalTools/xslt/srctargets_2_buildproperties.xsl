<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns="http://hl7.org/fhir"
    xmlns:f="http://hl7.org/fhir"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:nts="http://nictiz.nl/xsl/testscript"
    xmlns:nf="http://www.nictiz.nl/functions"
    exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <!--
        This file contains the machinery to update the targets in a Nictiz NTS build properties file.
        If a build.properties is found in the folder supplied, the following parameters are created or updated based on the contents of the NTS-src-files present in its child folders:
        - targets.additional (update if present, create if targets is not present and if there are multiple targets defined in the src-files)
        - targets (update if present, never created)
        - targets.adminOnly (update or create if 'Nictiz-intern' targets are present in the src-files, additional targets already present are left alone)
    -->
    <xsl:param name="baseDirUrl"/>
    
    <xsl:param name="buildPropertiesDir"/>
    
    <!-- Either `default`, which updates `targets.additional` and `targets.adminOnly`, or 'MedMij', which updates `targets` -->
    <xsl:param name="mode"/>
    
    <xsl:template match="/">
        <!-- Get a comma separated list of all unique targets (combination of path and target name) in the specified $baseDirUrl folder -->
        <xsl:variable name="targets" as="xs:string*">
            <!-- All TestScripts, recursively, that contain @nts:in-targets -->
            <xsl:variable name="targetTestScripts" select="collection(iri-to-uri(concat($baseDirUrl, '?select=', '*.xml;recurse=yes')))//f:TestScript[//@nts:in-targets]"/>
            <xsl:for-each-group select="$targetTestScripts" group-by="replace(base-uri(.), '/[^/]+$', '')">
                <xsl:variable name="atts" as="attribute()*" select="current-group()//@nts:in-targets"/>
                <xsl:variable name="tokens" as="xs:string*" select="tokenize(string-join($atts ! string(.), ' '), '\s*,\s*|\s+')"/>
                <xsl:variable name="relPath" select="substring-after(current-grouping-key(),concat($baseDirUrl,'/'))"/>

                <xsl:for-each select="distinct-values($tokens)[. != '']">
                    <xsl:value-of select="concat($relPath,'-',.)"/>
                </xsl:for-each>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="targetsAdditionalString" select="string-join($targets[not(ends-with(., '#default')) and not(ends-with(., 'MedMij'))],',')"/>
        <xsl:variable name="targetsAdminOnlyString"  select="string-join($targets[ends-with(., 'Nictiz-intern')],',')"/>
        <xsl:variable name="targetsMedMijString" select="string-join($targets[ends-with(., 'MedMij')],',')"/>

        <xsl:variable name="propFile" as="xs:string" select="iri-to-uri(concat($buildPropertiesDir,'/build.properties'))"/>
        
        <!-- Parse the build.properties per line -->
        <xsl:variable name="text" as="xs:string" select="unparsed-text($propFile)"/>
        <xsl:variable name="lines" as="xs:string*" select="tokenize($text, '\r?\n', 's')"/>
        
        <!-- Define which properties to update per mode -->       
        <xsl:variable name="updateKeys" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$mode = 'default'">
                    <xsl:sequence select="('targets.additional','targets.adminOnly')"/>
                </xsl:when>
                <xsl:when test="$mode = 'MedMij'">
                    <xsl:sequence select="('targets')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- And the values with which to update them -->
        <xsl:variable name="updateValues" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$mode = 'default'">
                    <xsl:sequence select="($targetsAdditionalString,$targetsAdminOnlyString)"/>
                </xsl:when>
                <xsl:when test="$mode = 'MedMij'">
                    <xsl:sequence select="($targetsMedMijString)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Preserve all old lines, replace only the ones we want -->
        <xsl:variable name="updatedLines" as="xs:string*">
            <xsl:iterate select="1 to count($updateKeys)">
                <xsl:param name="acc" as="xs:string*" select="$lines"/>
                <xsl:variable name="i" as="xs:integer" select="."/>
                <xsl:on-completion select="$acc"/>
                <xsl:next-iteration>
                    <xsl:with-param name="acc"
                        select="nf:setLine($acc, $updateKeys[$i], $updateValues[$i])"/>
                </xsl:next-iteration>
            </xsl:iterate>
        </xsl:variable>
        
        <xsl:result-document href="{$propFile}" method="text" omit-xml-declaration="yes">
            <xsl:for-each select="$updatedLines">
                <xsl:value-of select="."/>
                <xsl:if test="position() ne last()">
                    <xsl:text>&#10;</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:result-document>

        <!-- TODO:
             - What if build.properties is missing?
        -->
    </xsl:template>
    
    <!-- Set a new property value in the collection of lines from the original build.properties -->
    <xsl:function name="nf:setLine" as="xs:string*">
        <xsl:param name="lines" as="xs:string*"/>
        <xsl:param name="name"  as="xs:string"/>
        <xsl:param name="value" as="xs:string"/>
        <xsl:variable name="pos" as="xs:integer?"
            select="(for $j in 1 to count($lines)
                    return if (nf:getKey($lines[$j]) = $name) then $j else ())[1]"/>
        
        <xsl:variable name="replacement" select="concat($name, ' = ', $value)"/>
        
        <xsl:sequence select="
            if ($pos)
                then ( $lines[position() lt $pos],
                    $replacement,
                    $lines[position() gt $pos] )
            else ( $lines, $replacement )
                        "/>
    </xsl:function>
    
    <!-- Get the key (part before '=') from a property line -->
    <xsl:function name="nf:getKey" as="xs:string?">
        <xsl:param name="line" as="xs:string"/>
        <xsl:sequence select="
            if (matches($line, '^\s*[^#][^=]*=')) then normalize-space(replace($line, '^\s*([^=]+)=.*$', '$1')) else ()"/>
    </xsl:function>
    
    <!-- Checks if a property exists in the build.properties -->
    <xsl:function name="nf:propertyExists" as="xs:boolean">
        <xsl:param name="line" as="xs:string"/>
        <xsl:sequence select="matches($line, '^\s*[^#][^=]*=')"/>
    </xsl:function>

</xsl:stylesheet>