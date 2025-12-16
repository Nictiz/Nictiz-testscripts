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
        This file contains the machinery to write a ConformanceLab properties file.
    -->
    <xsl:param name="baseDirUrl"/>

    <xsl:template match="/">
        <xsl:for-each select="nts:findFolders(fn:false())">
            <xsl:call-template name="generatePropertiesFile">
                <xsl:with-param name="relFolderPath" select="."/>
                <xsl:with-param name="loadscriptFolder" select="fn:false()"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Return all relative paths of folder with TestScripts in them.
         - loadscriptFolders: If false, find non-loadscript folders only. If true, find loadscript folders only.
    -->
    <xsl:function name="nts:findFolders" as="xs:string*">
        <xsl:param name="loadscriptFolders" as="xs:boolean"/>
        <!--
            We need to place property files in all folders containing files, but not in the folders in between or in
            empty folders (and excluding everything starting with an underscore). Getting only the folders with files
            is not trivial in XSLT (or in ANT) unfortunately.
            The approach is to loop over all TestScript content in folders and nested folders using collection(),
            extract the uri of the TestScript using base-uri(), and than extract the relative path beneath baseDirUrl
            from that. Once we have the collection, we can de-duplicate it.
            The assumption is that at least, by working with file uri's, we can assume that the path separator is
            always a backslash, so we don't need to worry about *that*.
        -->
        <xsl:variable name="path" select="replace($baseDirUrl, 'file:/*', '')"/>
        <xsl:variable name="unfiltered" as="xs:string*">
            <xsl:for-each select="collection(iri-to-uri(concat($baseDirUrl, '?select=', '*.xml;recurse=yes')))//f:TestScript">
                <!-- One would assume that working with file uri's we have a stable 'base part' with scheme,
                     slashes, etc. so we can strip that from the file uri and be left with the relative path.
                     But nonono, that would be simple. So base-uri() returns (at this time and place at least) a
                     file uri with a single slash instead of three slashes. Our replace strategy now has to account
                     for any number of forward slashes following the 'file:' part.
                -->
                <xsl:variable name="relative" select="replace(base-uri(.), concat('file:/+', $path), '')"/>
                <xsl:choose>
                    <xsl:when test="not($loadscriptFolders) and not(starts-with($relative, '/_'))">
                        <!-- Filter out folders starting with an underscore in 'normal' mode -->
                        <xsl:value-of select="replace($relative, '/(.*)/.*?\.xml', '$1')"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:copy-of select="distinct-values($unfiltered)"/>
    </xsl:function>
    
    <!-- Generate a property file for the specified folder.
         - relFolderPath: the relative path to the folder.
         - loadscriptFolder: boolean to indicate if this is a loadscript folder, to which not all property's apply.
    -->
    <xsl:template name="generatePropertiesFile">
        <xsl:param name="relFolderPath" as="xs:string" required="yes"/>
        <xsl:param name="loadscriptFolder" as="xs:boolean" required="yes"/>

        <!-- Create an XML representation of the desired JSON structure, which can be written as JSON using xml-to-json. --> 
        <xsl:variable name="properties">
            <map xmlns="http://www.w3.org/2005/xpath-functions">
                <string key="goal">
                    <xsl:value-of select="'${goal}'"/>
                </string>
                <string key="fhirVersion">
                    <xsl:value-of select="'${fhir.version}'"/>
                </string>
                <string key="informationStandard">
                    <xsl:value-of select="'${informationStandard}'"/>
                </string>
                <string key="usecase">
                    <xsl:value-of select="'${usecase}'"/>
                </string>
                <xsl:if test="not($loadscriptFolder)">
                    <xsl:variable name="subfolders" as="xs:string*">
                        <xsl:for-each select="tokenize($relFolderPath, '/')">
                            <xsl:if test="string-length(normalize-space(.)) &gt; 0">
                                <xsl:value-of select="."/>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable> 
                
                    <map key="role">
                        <xsl:variable name="clRole">
                            <xsl:choose>
                                <xsl:when test="contains($subfolders[3], 'Receiving')">Receiving System</xsl:when>
                                <xsl:when test="contains($subfolders[3], 'Retrieving')">Retrieving System</xsl:when>
                                <xsl:when test="contains($subfolders[3], 'Sending')">Sending System</xsl:when>
                                <xsl:when test="contains($subfolders[3], 'Serving')">Serving System</xsl:when>
                                <xsl:otherwise>
                                    <xsl:message terminate="yes">Could not determine clRole: <xsl:value-of select="$subfolders[3]"/></xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:value-of select="' (MP-'"/>
                            <xsl:value-of select="substring-after($subfolders[3],'-')"/>
                            <xsl:value-of select="')'"/>
                        </xsl:variable>
                        <string key="name">
                             <xsl:value-of select="$clRole"/>
                            <xsl:message select="$clRole"/>
                        </string>
                        <xsl:variable name="clRoleDescConfig" select="document('role-description-config.xml')"/>
                        <xsl:variable name="clRoleDesc" select="$clRoleDescConfig//role[name/text() = $clRole]/description/text()"/>
                        <xsl:if test="not(empty($clRoleDesc))">
                            <string key="description">
                                <xsl:value-of select="$clRoleDesc"/>
                            </string>
                        </xsl:if>
                    </map>

                    <xsl:if test="$subfolders[1]">
                        <xsl:variable name="clCategory">
                            <xsl:choose>
                                <xsl:when test="contains($subfolders[1], 'Cons')">Consolidatie</xsl:when>
                                <xsl:when test="contains($subfolders[1], 'Step-3')">Stap 3</xsl:when>
                                <xsl:when test="contains($subfolders[1], 'Step-4')">Stap 4</xsl:when>
                                <xsl:when test="contains($subfolders[1], 'Step-5')">Stap 5</xsl:when>
                                <xsl:when test="contains($subfolders[1], 'Step-6')">Stap 6</xsl:when>
                                <xsl:otherwise>
                                    <xsl:message terminate="yes">Could not determine clCategory: <xsl:value-of select="$subfolders[1]"/></xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <string key="category">
                            <xsl:value-of select="$clCategory"/>
                        </string>
                    </xsl:if>
                    <xsl:if test="$subfolders[2]">
                        <xsl:variable name="clSubcategory">
                            <xsl:choose>
                                <xsl:when test="contains($subfolders[2], 'MA-VV')">Voorschrift</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'TA-MVE')">VoorschriftAfhandeling</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'AVMA')">Antwoord Voorstel MedicatieAfspraak (AVMA)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'AVVV')">Antwoord Voorstel VerstrekkingsVerzoek (AVVV)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'MA')">MedicatieAfspraak (MA)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'MGB')">MedicatieGebruik (MGB)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'MTD')">MedicatieToediening (MTD)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'MVE')">MedicatieVerstrekking (MVE)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'TA')">ToedieningsAfspraak (TA)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'VMA')">Voorstel MedicatieAfspraak (VMA)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'VVV')">Voorstel VerstrekkingsVerzoek (VVV)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'VV')">VerstrekkingsVerzoek (VV)</xsl:when>
                                <xsl:when test="contains($subfolders[2], 'WDS')">Wisselend DoseerSchema (WDS)</xsl:when>
                                <xsl:otherwise>
                                    <xsl:message terminate="yes">Could not determine clSubcategory: <xsl:value-of select="$subfolders[2]"/></xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <string key="subcategory">
                            <xsl:value-of select="$clSubcategory"/>
                        </string>
                    </xsl:if>

                    <string key="serverAlias">
                        <xsl:value-of select="'${serverAlias}'"/>
                    </string>
                </xsl:if>
            </map>
        </xsl:variable>
        <xsl:result-document href="{concat($baseDirUrl, '/', $relFolderPath, '/src-properties.json')}" method="text" indent="no">
            <xsl:value-of select="xml-to-json($properties, map {'indent': true()})"/>
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>