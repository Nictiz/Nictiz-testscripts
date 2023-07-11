<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
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
        
    <!-- The path to the base folder of fixtures, relative to the output. Defaults to '../_reference'. -->
    <xsl:param name="referenceBase" select="'../_reference/'"/>
    
    <!-- FHIR version to be able to retrieve the correct FHIR core resource type StructureDefinition -->
    <xsl:param name="fhirVersion" select="'STU3'"/>
    
    <xsl:param name="libPath" select="concat(string-join(tokenize(static-base-uri(), '/')[fn:position() lt last() - 1], '/'), '/lib/')"/>
    
    <!-- The main template, which will call the remaining templates. -->
    <xsl:template name="generateAsserts" match="f:TestScript">
        <xsl:variable name="includeDateT">
            <xsl:choose>
                <xsl:when test="nts:includeDateT/@value = 'yes'">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- Copy everything blindly except test elements -->
            <xsl:apply-templates select="*[not(self::f:test) and not(self::f:teardown)]"/>
            <xsl:apply-templates select="f:test">
                <xsl:with-param name="includeDateT" select="$includeDateT" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="f:teardown"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="f:test[nts:contentAsserts]">
        <!-- copy test and its contents -->
        <xsl:next-match/>
        
        <xsl:variable name="basePath">
            <xsl:variable name="tokenize" select="tokenize(base-uri(), '/')"/>
            <xsl:value-of select="string-join($tokenize[position() lt last()], '/')"/>
        </xsl:variable>
        
        <xsl:for-each select="nts:contentAsserts">
            <xsl:variable name="href" select="@href"/>
            <xsl:variable name="expression" select="@expression"/>
            <xsl:variable name="description" select="@description"/>
            
            <xsl:variable name="fixtureUri" select="concat($basePath, '/', $referenceBase, $href)"/>
            <xsl:variable name="fixture" select="document($fixtureUri)"/>
            <xsl:variable name="fixtureId" select="$fixture/f:*/f:id/@value"/>
            <test>
                <name value="check-{$fixtureId}"/>
                <!--<description value=""/>-->
                
                <xsl:variable name="resourceType" select="$fixture/f:*/local-name()"/>
                <xsl:variable name="structureDefinition" select="document(concat($libPath, lower-case($fhirVersion), '/StructureDefinition-', $resourceType, '.xml'))"/>
                
                <!-- According to TestScript spec, the last available request/response will be used, so we do not specifically have to add a responseId. Could (should?) be a feature though -->
                <xsl:call-template name="createAssert">
                    <xsl:with-param name="description" select="concat('Response Bundle ', $description)"/>
                    <xsl:with-param name="expression" select="concat('Bundle.entry.resource.ofType(', $resourceType, ')', $expression, '.count() = 1')"/>
                    <xsl:with-param name="stopTestOnFail" select="true()"/>
                </xsl:call-template>
                <!-- Add an explicit assert to check Resource.id -->
                <xsl:call-template name="createAssert">
                    <xsl:with-param name="description" select="concat($resourceType, ' resource evaluated in the previous assert contains an .id')"/>
                    <xsl:with-param name="expression" select="concat('Bundle.entry.resource.ofType(', $resourceType, ')', $expression, '.id.exists()')"/>
                    <xsl:with-param name="stopTestOnFail" select="true()"/>
                </xsl:call-template>
                
                <!-- If the assert above passes, we know by definition that this variable will be evaluated. TestScripts will fail with an error if a variable cannot be evaluated, but to users it is not really clear what happens. The setup with the asserts above will prevent that hopefully. -->
                <xsl:variable name="idVariable" select="concat($fixtureId,'-id')"/>
                <variable>
                    <name value="{$idVariable}"/>
                    <description value="Resource.id for Observation X"/>
                    <expression value="{concat('Bundle.entry.resource.ofType(', $resourceType, ')', $expression, '.id')}"/>
                </variable>
                
                <!-- After this, we can use the variable in all following asserts -->
                <xsl:apply-templates select="$fixture/f:*/f:*" mode="generateAsserts">
                    <xsl:with-param name="resourceType" select="$fixture/f:*/local-name()"/>
                    <xsl:with-param name="structureDefinition" select="$structureDefinition"/>
                    <xsl:with-param name="idVariable" select="$idVariable"/>
                </xsl:apply-templates>
            </test>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="f:*" mode="generateAsserts">
        <xsl:param name="resourceType"/>
        <xsl:param name="structureDefinition"/>
        <xsl:param name="idVariable"/>
        
        <!-- Need to use element/@id or element/path/@value? So far, they are identical in STU3 -->
        <xsl:variable name="elementPath" select="concat($resourceType, '.', local-name())"/>
        <xsl:variable name="elementNameBase">
            <xsl:analyze-string select="local-name()" regex="^[a-z]+">
                <xsl:matching-substring>
                    <xsl:value-of select="."/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="polymorphic" select="concat($resourceType, '.', $elementNameBase, '[x]')"/>
        <xsl:variable name="polymorphicDataType" select="substring-after(local-name(), $elementNameBase)"/>
        <xsl:variable name="dataType">
            <xsl:choose>
                <xsl:when test="$structureDefinition/f:StructureDefinition/f:snapshot/f:element/@id = $elementPath">
                    <!-- In StructureDefinitions, References have an f:type for each targetProfile. Using distinct-values to filter that (because I still want to know if it outputs multiple hits) -->
                    <xsl:value-of select="distinct-values($structureDefinition/f:StructureDefinition/f:snapshot/f:element[@id = $elementPath]/f:type/f:code/@value)"/>
                </xsl:when>
                <xsl:when test="$structureDefinition/f:StructureDefinition/f:snapshot/f:element/@id = $polymorphic">
                    <!-- Element is polymorphic, lets use its name to guess data type -->
                    <xsl:value-of select="$structureDefinition/f:StructureDefinition/f:snapshot/f:element[@id = $polymorphic]/f:type/f:code/@value[lower-case(.) = lower-case($polymorphicDataType)]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>Could not find <xsl:value-of select="$elementNameBase"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="expressionBase" select="concat('Bundle.entry.resource.ofType(', $resourceType, ').where(id = ''${', $idVariable, '}'').', $elementNameBase)"/>
        
        <xsl:variable name="hasValue" select="string-length(normalize-space(@value)) gt 0"/>
        
        <!-- Add reminder here. For every element, a scenario with extension present should be considered -->
        <xsl:if test="f:extension">
            <!-- for each extension apply template createExpressionExtension -->
            <xsl:message>Element contains an unhandles Extension!</xsl:message>
        </xsl:if>
        
        <!-- Generate (part of) expression based on datatype -->
        <xsl:variable name="expression">
            <xsl:choose>
                <xsl:when test="$dataType = 'dateTime' and $hasValue = true()">
                    <xsl:choose>
                        <xsl:when test="matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}')">
                            <xsl:text> ~ </xsl:text>
                            <xsl:analyze-string select="@value" regex="\$\{{DATE, T, (Y|M|D), ([-]?)(\d+)\}}">
                                <xsl:matching-substring>
                                    <xsl:text>@${T} </xsl:text>
                                    <xsl:choose>
                                        <xsl:when test="regex-group(2) = '-'">- </xsl:when>
                                        <xsl:otherwise>+ </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="regex-group(3)"/>
                                    <xsl:text> </xsl:text>
                                    <xsl:choose>
                                        <xsl:when test="regex-group(1) = 'Y'">years</xsl:when>
                                        <xsl:when test="regex-group(1) = 'M'">months</xsl:when>
                                        <xsl:when test="regex-group(1) = 'D'">days</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:message>Unkown T-date symbol: <xsl:value-of select="regex-group(1)"/></xsl:message>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                            <!-- If time is added to T-date, it should be added to the assert -->
                            <!--<xsl:if test=""></xsl:if>-->
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$dataType = 'code' and $hasValue = true()">
                    <xsl:value-of select="concat(' = ''', @value, '''')"/>
                </xsl:when>
                <xsl:when test="$dataType = 'id'">
                    <!-- An assert for Resource.id has been made earlier in the process because it is essential. So here we do nothing -->
                </xsl:when>
                <xsl:when test="$dataType = 'CodeableConcept'">
                    <!-- How to handle .text? We hardly use it ourselves -->
                    <xsl:text>.where(</xsl:text>
                    <xsl:for-each select="f:coding">
                        <xsl:text>coding</xsl:text>
                        <xsl:call-template name="createExpressionCoding">
                            <xsl:with-param name="in" select="."/>
                        </xsl:call-template>
                        <xsl:if test="not(position() = last())">
                            <xsl:text> and </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>).exists()</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = 'Quantity'">
                    <xsl:text>.where(</xsl:text>
                    <xsl:if test="f:value">
                        <xsl:text>value = </xsl:text>
                        <xsl:value-of select="f:value/@value"/>
                        <xsl:if test="f:unit or f:system or f:code"> and </xsl:if>
                    </xsl:if>
                    <!-- Do nothing with f:comparator -->
                    <xsl:if test="f:unit">
                        <xsl:text>unit.exists()</xsl:text>
                        <xsl:if test="f:system or f:code"> and </xsl:if>
                    </xsl:if>
                    <xsl:if test="f:system">
                        <xsl:text>system = '</xsl:text>
                        <xsl:value-of select="f:system/@value"/>
                        <xsl:text>'</xsl:text>
                        <xsl:if test="f:code"> and </xsl:if>
                    </xsl:if>
                    <xsl:if test="f:code">
                        <xsl:variable name="value" select="f:code/@value"/>
                        <xsl:text>code</xsl:text>
                        <xsl:choose>
                            <xsl:when test="contains($value, '{') and contains($value, '}') ">
                                <xsl:text>.matches('^</xsl:text>
                                <xsl:analyze-string select="$value" regex="\{{\w*\}}">
                                    <xsl:matching-substring>
                                        <xsl:text>\\{.+\\}</xsl:text>
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:value-of select="."/>
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                                <xsl:text>$')</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text> = '</xsl:text>
                                <xsl:value-of select="f:code/@value"/>
                                <xsl:text>'</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    <xsl:text>).exists()</xsl:text>
                </xsl:when>
                <!--<xsl:when test="$dataType = 'Meta'">
                <!-\- Is a general assert to check for Meta.profile. Move it to here for more specific debugging. If the resource contains more fields in Meta (for example meta.tag in MP?) I guess there should be an assert to check it -\->
            </xsl:when>-->
                <xsl:when test="$dataType = 'Identifier'">
                    <xsl:text>.where(</xsl:text>
                    <xsl:choose>
                        <xsl:when test="f:system">system</xsl:when>
                        <xsl:when test="f:type">type</xsl:when>
                    </xsl:choose>
                    <xsl:text>.exists() and value.exists())</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = 'Reference'">
                    <xsl:text>.where(</xsl:text>
                    <!-- Check if (reference OR identifier) and display exist -->
                    <!-- Check reference -->
                    <xsl:text>(reference.where( startsWith('http://') or startsWith('https://') or startsWith('#') or matches('^urn:oid:[0-2](\\.(0|[1-9]\\d*))*$') or matches('^urn:uuid:[A-Fa-f\\d]{8}-[A-Fa-f\\d]{4}-[A-Fa-f\\d]{4}-[A-Fa-f\\d]{4}-[A-Fa-f\\d]{12}$') or (startsWith('urn:').not() and startsWith('#').not() and matches('^[A-Za-z]{3,}/[^/]+$')) ).exists() or </xsl:text>
                    <!-- Check identifier reference -->
                    <xsl:text>identifier.exists()) and </xsl:text>
                    <!-- dislay should exist -->
                    <xsl:text>display.exists()</xsl:text>
                    <xsl:text>).exists()</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = 'BackboneElement'">
                    <!-- Basically a container. Problem is expressions get very complicated very quickly. But that doesn't mean we can start from there (as long as it's automatically generated -->
                    <xsl:text>.where(</xsl:text>
                    
                    <xsl:text>).exists()</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="concat('TODO EXPRESSION: ',$dataType)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="description">
            <xsl:choose>
                <xsl:when test="$dataType = 'code' and $hasValue = true()">
                    <xsl:value-of select="concat('with value ''', @value, '''')"/>
                </xsl:when>
                <xsl:when test="$dataType = 'id'">
                    <!-- An assert for Resource.id has been made earlier in the process because it is essential. So here we do nothing -->
                </xsl:when>
                <xsl:when test="$dataType = 'Identifier'">
                    <xsl:text>with .</xsl:text>
                    <xsl:choose>
                        <xsl:when test="f:system">system</xsl:when>
                        <xsl:when test="f:type">type</xsl:when>
                    </xsl:choose>
                    <xsl:text> and .value</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="concat('TODO DESCRIPTION: ',$dataType)"/>
                    <xsl:value-of select="'with ...'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="string-length($expression) gt 0">
            <xsl:call-template name="createAssert">
                <xsl:with-param name="description" select="concat($resourceType, ' X contains .', local-name(), ' ', $description)"/>
                <xsl:with-param name="expression" select="concat($expressionBase, $expression)"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="createAssert">
        <xsl:param name="description" required="yes"/>
        <xsl:param name="expression" required="yes"/>
        <xsl:param name="warningOnly" select="false()"/>
        <xsl:param name="stopTestOnFail" select="false()"/>
        
        <action>
            <assert>
                <!-- False is the default of the NTS process, so we do not have to add anything in that case -->
                <xsl:if test="$stopTestOnFail = true()">
                    <xsl:attribute name="nts:stopTestOnFail">true</xsl:attribute>
                </xsl:if>
                <!-- We can also do something with label here -->
                <!--<label value=""/>-->
                <description value="{$description}"/>
                <!-- Should be edited based on scenario probably, leaving it fixed on 'response' for now -->
                <direction value="response"/>
                <expression value="{$expression}"/>
                <!-- False is the default of the NTS process, so we do not have to add anything in that case -->
                <xsl:if test="$warningOnly = true()">
                    <warningOnly value="true"/>
                </xsl:if>
            </assert>
        </action>
    </xsl:template>
    
    <xsl:template name="createExpressionCoding">
        <xsl:param name="in" as="element(f:coding)"/>
        
        <!-- Extension? -->
        <xsl:text>.where(</xsl:text>
        <xsl:if test="f:system">
            <xsl:text>system = '</xsl:text>
            <xsl:value-of select="f:system/@value"/>
            <xsl:text>'</xsl:text>
            <xsl:if test="f:code or f:display"> and </xsl:if>
        </xsl:if>
        <!-- Do nothing with f:version -->
        <xsl:if test="f:code">
            <xsl:text>code = '</xsl:text>
            <xsl:value-of select="f:code/@value"/>
            <xsl:text>'</xsl:text>
            <xsl:if test="f:display"> and </xsl:if>
        </xsl:if>
        <xsl:if test="f:display">
            <xsl:text>display.exists()</xsl:text>
        </xsl:if>
        <xsl:text>)</xsl:text>
        <!-- Do nothing with f:userSelected -->
    </xsl:template>
    
    <xsl:template match="nts:contentAsserts"/>
    
    <xsl:template match="node()|@*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>