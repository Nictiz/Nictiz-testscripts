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
    
    <!-- Fixed, but could be dependant on fhirVersion -->
    <xsl:variable name="complexDataTypes" select="('Annotation','CodeableConcept','Coding','Meta','Reference','Identifier','Narrative')"/>
    
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
        <xsl:variable name="responseId">
            <xsl:choose>
                <xsl:when test="nts:include[@value = 'medmij/test.xis.successfulSearch']/@responseId">
                    <xsl:value-of select="nts:include[@value = 'medmij/test.xis.successfulSearch']/@responseId"/>
                </xsl:when>
                <xsl:when test="fn:string-length(@id) gt 0">
                    <xsl:value-of select="concat('fixture-',@id)"/>
                </xsl:when>
                <xsl:when test="count(parent::f:TestScript/f:test) = 1">
                    <xsl:text>fixture-response</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>TOCHECK: responseId and test/@id not found, reverting to default.</xsl:message>
                    <xsl:value-of select="generate-id()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="testName" select="f:name/@value"/>
        <!-- copy test and its contents, we do add responseId if not present -->
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="modifyNts">
                <xsl:with-param name="responseId" select="$responseId" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:copy>
        
        <xsl:variable name="basePath">
            <xsl:variable name="tokenize" select="tokenize(base-uri(), '/')"/>
            <xsl:value-of select="string-join($tokenize[position() lt last()], '/')"/>
        </xsl:variable>
        
        <xsl:for-each select="nts:contentAsserts">
            <xsl:variable name="href" select="@href"/>
            <xsl:variable name="expression" select="@expression"/>
            <xsl:if test="ends-with(translate($expression, ' ', ''), 'count()=1') or ends-with($expression, 'exists()')">
                <xsl:message terminate="yes">TOEDIT: Expression shouldn't end in count() or exists() - <xsl:value-of select="$expression"/></xsl:message>
            </xsl:if>
            <xsl:variable name="description" select="@description"/>
            
            <!-- We use @resourceType to present a nice count to users  -->
            <xsl:variable name="resourceType" select="@resourceType"/>
            <xsl:variable name="resourceCount" select="count(preceding-sibling::nts:contentAsserts[@resourceType = $resourceType]) + 1"/>
            
            <xsl:variable name="fixtureUri" select="concat($basePath, '/', $referenceBase, $href)"/>
            <xsl:variable name="fixture" select="document($fixtureUri)"/>
            <xsl:variable name="fixtureId" select="$fixture/f:*/f:id/@value"/>
            
            <!-- Sanity check -->
            <xsl:if test="not($resourceType = $fixture/f:*/local-name())">
                <xsl:message terminate="yes">nts:contentAsserts[@href = '<xsl:value-of select="$href"/>']/@resourceType is absent or does not match the actual resource type of the fixture</xsl:message>
            </xsl:if>
            <xsl:variable name="structureDefinition" select="document(concat($libPath, lower-case($fhirVersion), '/StructureDefinition-', $resourceType, '.xml'))"/>
            
            <!-- Would preferably do this in a separate step with Xproc. We'll see what the future brings -->
            <xsl:variable name="fixtureWithDataTypes">
                <xsl:apply-templates select="$fixture" mode="addDataTypes">
                    <xsl:with-param name="structureDefinition" select="$structureDefinition" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>
            <!-- debug -->
            <!--<xsl:result-document href="test.xml"><xsl:copy-of select="$fixtureWithDataTypes"/></xsl:result-document>-->
            
            <test>
                <name value="{$testName} - Check {$resourceType} {$resourceCount}"/>
                <description value="Check if the previous operation results in a FHIR {$resourceType} that contains the values that are expected following Nictiz' materials (fixture .id: {$fixtureId})"/>
                
                <!-- According to TestScript spec, the last available request/response will be used, so we do not specifically have to add a responseId. Could (should?) be a feature though -->
                <xsl:call-template name="createAssert">
                    <xsl:with-param name="description">
                        <xsl:choose>
                            <xsl:when test="string-length($description) gt 0">
                                <xsl:value-of select="concat('Response Bundle contains exactly 1 ', $description)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>Response Bundle contains exactly 1 resource with specific contents</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
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
                    <description value="Resource.id for Observation {$resourceCount}"/>
                    <expression value="{concat('Bundle.entry.resource.ofType(', $resourceType, ')', $expression, '.id')}"/>
                    <sourceId value="{$responseId}"/>
                </variable>
                
                <!-- After this, we can use the variable in all following asserts -->
                <xsl:apply-templates select="$fixtureWithDataTypes/f:*/f:*" mode="generateAsserts">
                    <xsl:with-param name="resourceType" select="$resourceType" tunnel="yes"/>
                    <xsl:with-param name="resourceCount" select="$resourceCount" tunnel="yes"/>
                    <xsl:with-param name="idVariable" select="$idVariable" tunnel="yes"/>
                    <xsl:with-param name="parentElementPath" select="$resourceType"/>
                    <xsl:with-param name="parentLabel" select="$resourceCount"/>
                </xsl:apply-templates>
            </test>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="f:*" mode="generateAsserts">
        <xsl:param name="resourceType" tunnel="yes"/>
        <xsl:param name="resourceCount" tunnel="yes"/>
        <xsl:param name="idVariable" tunnel="yes"/>
        <xsl:param name="parentElementPath" required="yes"/>
        <xsl:param name="parentLabel" required="yes"/>
        
        <!-- Need to use element/@id or element/path/@value? So far, they are identical in STU3 -->
        <xsl:variable name="elementPath" select="concat($parentElementPath, '.', local-name())"/>
        <xsl:variable name="expressionBase" select="concat('Bundle.entry.resource.ofType(', $resourceType, ').where(id = ''${', $idVariable, '}'')',substring-after($parentElementPath, $resourceType),'.')"/>
        
        <xsl:variable name="hasValue" select="string-length(normalize-space(@value)) gt 0"/>
        
        <!-- Generate (part of) expression based on datatype -->
        <xsl:variable name="expression">
            <xsl:call-template name="createExpression">
                <xsl:with-param name="elementPath" select="$elementPath"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="label">
            <xsl:value-of select="$parentLabel"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="fn:count(preceding-sibling::*[not(self::f:id)])+1"/>
        </xsl:variable>
        
        <xsl:variable name="description">
            <xsl:call-template name="createDescription">
                <xsl:with-param name="elementPath" select="$elementPath"/>
            </xsl:call-template>
            <!-- If there are two hyphens or more in label -->
            <xsl:if test="string-length($label) - string-length(translate($label, '-', '')) ge 2">
                <xsl:value-of select="concat('. This assert checks only one child. Assert ', $parentLabel, ' checks if all children are present in the same parent')"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:if test="string-length($expression) gt 0">
            <xsl:call-template name="createAssert">
                <xsl:with-param name="description" select="concat($resourceType, ' ', $resourceCount, ' contains ', substring-after($elementPath, $resourceType), ' ', $description)"/>
                <xsl:with-param name="expression" select="concat($expressionBase, $expression)"/>
                <xsl:with-param name="label" select="$label"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:variable name="dataType" select="@nts:dataType"/>
        <xsl:if test="($dataType = ('BackboneElement', 'Extension') and count(*) gt 1) or f:extension">
            <xsl:apply-templates select="*" mode="#current">
                <xsl:with-param name="parentElementPath">
                    <xsl:choose>
                        <xsl:when test="$dataType = 'Extension'">
                            <xsl:value-of select="concat($elementPath,'(''',@url,''')')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$elementPath"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="parentLabel" select="$label"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="getDataType">
        <xsl:param name="resourceType" tunnel="yes"/>
        <xsl:param name="structureDefinition" tunnel="yes"/>
        <xsl:param name="elementPath" required="yes"/>
        <xsl:param name="parentDataType"/>
        
        <xsl:variable name="polymorphic" select="concat(substring-before($elementPath, local-name()), nf:get-element-base(local-name()), '[x]')"/>
        <xsl:variable name="polymorphicDataType" select="substring-after(local-name(), nf:get-element-base(local-name()))"/>
        
        <!-- If datatype, overrule elementPath and structureDefinition -->
        <xsl:variable name="structureDefinition">
            <xsl:choose>
                <xsl:when test="$parentDataType = $complexDataTypes">
                    <xsl:copy-of select="document(concat($libPath, lower-case($fhirVersion), '/dataTypes/StructureDefinition-', $parentDataType, '.xml'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$structureDefinition"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="elementPath">
            <xsl:choose>
                <xsl:when test="$parentDataType = $complexDataTypes">
                    <xsl:variable name="head">
                        <xsl:call-template name="substring-before-last">
                            <xsl:with-param name="input" select="$elementPath"/>
                            <xsl:with-param name="substr" select="'.'"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:value-of select="replace($elementPath, $head, $parentDataType)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$elementPath"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$structureDefinition/f:StructureDefinition/f:snapshot/f:element/@id = $elementPath">
                <!-- In StructureDefinitions, References have an f:type for each targetProfile. Using distinct-values to filter that (because I still want to know if it outputs multiple hits) -->
                <xsl:value-of select="distinct-values($structureDefinition/f:StructureDefinition/f:snapshot/f:element[@id = $elementPath]/f:type/f:code/@value)"/>
            </xsl:when>
            <xsl:when test="$structureDefinition/f:StructureDefinition/f:snapshot/f:element/@id = $polymorphic">
                <!-- Element is polymorphic, lets use its name to guess data type -->
                <xsl:value-of select="$structureDefinition/f:StructureDefinition/f:snapshot/f:element[@id = $polymorphic]/f:type/f:code/@value[lower-case(.) = lower-case($polymorphicDataType)]"/>
            </xsl:when>
            <!-- If extension, datatype is extension. Not present in Snapshot -->
            <xsl:when test="self::f:extension">Extension</xsl:when>
            <!-- If parent is extension, definition of extension isn't in Snapshot - this means datatype is either Extension or some value[x] -->
            <xsl:when test="parent::f:extension">
                <xsl:value-of select="$polymorphicDataType"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>Could not find <xsl:value-of select="$elementPath"/></xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="createAssert">
        <xsl:param name="description" required="yes"/>
        <xsl:param name="expression" required="yes"/>
        <xsl:param name="label"/>
        <xsl:param name="warningOnly" select="false()"/>
        <xsl:param name="stopTestOnFail" select="false()"/>
        
        <action>
            <assert>
                <!-- False is the default of the NTS process, so we do not have to add anything in that case -->
                <xsl:if test="$stopTestOnFail = true()">
                    <xsl:attribute name="nts:stopTestOnFail">true</xsl:attribute>
                </xsl:if>
                <xsl:if test="fn:string-length($label) gt 0">
                    <label value="{$label}"/>
                </xsl:if>
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
    
    <xsl:template name="createExpression">
        <xsl:param name="elementPath"/>
        <xsl:param name="dataType" select="@nts:dataType"/>
        <xsl:param name="parentDataType" select="parent::f:*/@nts:dataType"/>
        <!-- Only top level asserts need a .exists() function -->
        <xsl:param name="topLevel" select="true()"/>
        
        <xsl:variable name="expression">
            <xsl:choose>
                <xsl:when test="$dataType = 'Boolean'">
                    <xsl:value-of select="concat(' = ', @value)"/>
                </xsl:when>
                <xsl:when test="$dataType = 'string' and $parentDataType = 'Coding'">
                    <!-- This is .display, and by definition not topLevel , so we do not have to do anything -->
                    <xsl:text>.exists()</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = 'string'">
                    <!-- '~' (equivalence) ignores case and whitespace. replace('.', '') removes dots (or other characters - hyphens perhaps?). Or should we be allowed to define overrides in our NTS-script? -->
                    <xsl:value-of select="concat('.replace(''.'', '''') ~ ''', normalize-space(translate(@value, '.', '')), '''')"/>
                </xsl:when>
                <xsl:when test="$dataType = 'dateTime' and (matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}') or fn:count(ancestor::*[position()=last()]//*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]) = 1)">
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
                        <xsl:when test="fn:count(ancestor::*[position()=last()]//*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]) = 1">
                            <!-- There is only 1 dateTime, so the only thing we can do is check it exists -->
                            <xsl:text>.exists()</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$dataType = 'code' or ($dataType = 'uri' and $parentDataType = 'Coding')">
                    <xsl:value-of select="concat(' = ''', @value, '''')"/>
                </xsl:when>
                <xsl:when test="$dataType = 'id'">
                    <!-- An assert for Resource.id has been made earlier in the process because it is essential. So here we do nothing -->
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
                <xsl:when test="$dataType = 'Identifier'">
                    <xsl:text>.exists(</xsl:text>
                    <xsl:choose>
                        <xsl:when test="f:system">system</xsl:when>
                        <xsl:when test="f:type">type</xsl:when>
                    </xsl:choose>
                    <xsl:text> and value)</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = 'Reference'">
                    <!-- Check if (reference OR identifier) and display exist -->
                    <xsl:text>.exists((reference or identifier) and display)</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = 'Meta'">
                    <!-- There is a general assert to check for Meta.profile, which can be removed if this specific check is applied. -->
                    <xsl:text>.exists(</xsl:text>
                    <xsl:for-each select="f:profile">
                        <xsl:text>profile.exists($this = '</xsl:text>
                        <xsl:value-of select="@value"/>
                        <xsl:text>')</xsl:text>
                    </xsl:for-each>
                    <xsl:text>)</xsl:text>
                    <!-- Not compatible with other elements being present - e.g. f:tag -->
                    <xsl:if test="*[not(self::f:profile)]">
                        <xsl:message select="concat('TODO EXTENSION: ',$dataType)"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$dataType = 'Narrative' and f:status/@value = 'extensions'">
                    <!-- Narrative isn't always present in fixtures. If not present, it is generated at a later stage. We should find a way to always add this assert. -->
                    <xsl:text>.exists()</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = 'Extension'">
                    <xsl:text>('</xsl:text>
                    <xsl:value-of select="@url"/>
                    <xsl:text>').where(</xsl:text>
                    <xsl:for-each select="*">
                        <xsl:call-template name="createExpression">
                            <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                        </xsl:call-template>
                        <xsl:if test="not(position() = last())">
                            <xsl:text> and </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>).exists()</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = ('BackboneElement','CodeableConcept','Coding')">
                    <!-- Basically a container. Problem is expressions get very complicated very quickly. But that doesn't mean we can start from there (as long as it's automatically generated -->
                    <xsl:text>.where(</xsl:text>
                    <xsl:for-each select="*">
                        <xsl:call-template name="createExpression">
                            <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                            <xsl:with-param name="topLevel">
                                <xsl:choose>
                                    <xsl:when test="$dataType = 'CodeableConcept'">
                                        <xsl:value-of select="false()"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="true()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:with-param>
                        </xsl:call-template>
                        <xsl:if test="not(position() = last())">
                            <xsl:text> and </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                    <xsl:text>)</xsl:text>
                    <xsl:if test="$topLevel = true()">
                        <xsl:text>.exists()</xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="concat('TODO EXPRESSION: ', $elementPath, ' - ',$dataType)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="string-length($expression) gt 0">
            <xsl:value-of select="concat(nf:get-element-base(local-name()), $expression)"/>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template name="createDescription">
        <xsl:param name="elementPath"/>
        <xsl:param name="dataType" select="@nts:dataType"/>

        <xsl:variable name="hasValue" select="string-length(normalize-space(@value)) gt 0"/>
        
        <xsl:choose>
            <xsl:when test="$dataType = 'Boolean'">
                <xsl:value-of select="concat('''', @value, '''')"/>
            </xsl:when>
            <xsl:when test="$dataType = 'string'">
                <xsl:value-of select="concat('''', @value, '''')"/>
            </xsl:when>
            <xsl:when test="$dataType = 'dateTime' and $hasValue = true() and (matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}') or fn:count(ancestor::*[position()=last()]//*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]) = 1)">
                <xsl:choose>
                    <xsl:when test="matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}')">
                        <xsl:text>with a value that equals T-date </xsl:text>
                        <xsl:analyze-string select="@value" regex="\$\{{DATE, T, (Y|M|D), ([-]?)(\d+)\}}">
                            <xsl:matching-substring>
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
                    <xsl:when test="fn:count(ancestor::*[position()=last()]//*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]) = 1">
                        <!-- Nothing to be added, as we only check existance -->
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$dataType = 'code' and $hasValue = true()">
                <xsl:value-of select="concat('''', @value, '''')"/>
            </xsl:when>
            <xsl:when test="$dataType = 'id'">
                <!-- An assert for Resource.id has been made earlier in the process because it is essential. So here we do nothing -->
            </xsl:when>
            <xsl:when test="$dataType = 'Coding'">
                <xsl:text>with </xsl:text>
                <xsl:if test="f:system">
                    <xsl:text>.system '</xsl:text>
                    <xsl:value-of select="f:system/@value"/>
                    <xsl:text>'</xsl:text>
                    <xsl:if test="f:code or f:display"> and </xsl:if>
                </xsl:if>
                <!-- Do nothing with f:version -->
                <xsl:if test="f:code">
                    <xsl:text>.code '</xsl:text>
                    <xsl:value-of select="f:code/@value"/>
                    <xsl:text>'</xsl:text>
                    <xsl:if test="f:display"> and </xsl:if>
                </xsl:if>
                <xsl:if test="f:display">
                    <xsl:text>.display</xsl:text>
                </xsl:if>
                <xsl:text>)</xsl:text>
                <!-- Do nothing with f:userSelected -->
            </xsl:when>
            <xsl:when test="$dataType = 'CodeableConcept'">
                <xsl:text>with </xsl:text>
                <xsl:for-each select="f:coding">
                    <xsl:text>.coding </xsl:text>
                    <xsl:call-template name="createDescription">
                        <xsl:with-param name="dataType" select="'Coding'"/>
                    </xsl:call-template>
                    <xsl:if test="not(position() = last())">
                        <xsl:text> and </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$dataType = 'Quantity'">
                <xsl:text>with </xsl:text>
                <xsl:if test="f:value">
                    <xsl:text>.value '</xsl:text>
                    <xsl:value-of select="f:value/@value"/>
                    <xsl:text>'</xsl:text>
                    <xsl:if test="f:unit or f:system or f:code"> and </xsl:if>
                </xsl:if>
                <!-- Do nothing with f:comparator -->
                <xsl:if test="f:unit">
                    <xsl:text>.unit</xsl:text>
                    <xsl:if test="f:system or f:code"> and </xsl:if>
                </xsl:if>
                <xsl:if test="f:system">
                    <xsl:text>.system '</xsl:text>
                    <xsl:value-of select="f:system/@value"/>
                    <xsl:text>'</xsl:text>
                    <xsl:if test="f:code"> and </xsl:if>
                </xsl:if>
                <xsl:if test="f:code">
                    <xsl:variable name="value" select="f:code/@value"/>
                    <xsl:text>.code </xsl:text>
                    <xsl:choose>
                        <xsl:when test="contains($value, '{') and contains($value, '}') ">
                            <xsl:text>matching regex '^</xsl:text>
                            <xsl:analyze-string select="$value" regex="\{{\w*\}}">
                                <xsl:matching-substring>
                                    <xsl:text>\\{.+\\}</xsl:text>
                                </xsl:matching-substring>
                                <xsl:non-matching-substring>
                                    <xsl:value-of select="."/>
                                </xsl:non-matching-substring>
                            </xsl:analyze-string>
                            <xsl:text>$'</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>'</xsl:text>
                            <xsl:value-of select="f:code/@value"/>
                            <xsl:text>'</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$dataType = 'Identifier'">
                <xsl:text>with .</xsl:text>
                <xsl:choose>
                    <xsl:when test="f:system">system</xsl:when>
                    <xsl:when test="f:type">type</xsl:when>
                </xsl:choose>
                <xsl:text> and .value</xsl:text>
            </xsl:when>
            <xsl:when test="$dataType = 'Reference'">
                <xsl:text>with either .reference or .identifier and .display</xsl:text>
            </xsl:when>
            <xsl:when test="$dataType = 'Meta'">
                <xsl:text>with </xsl:text>
                <xsl:for-each select="f:profile">
                    <xsl:value-of select="concat('.profile ''', @value, '''')"/>
                    <xsl:if test="not(position() = last())">
                        <xsl:text> and </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$dataType = 'Narrative' and f:status/@value = 'extensions'">
                <!-- Nothing to add -->
            </xsl:when>
            <xsl:when test="$dataType = 'Extension'">
                <xsl:value-of select="concat('with url ''', @url, ''' ')"/>
                <xsl:for-each select="*">
                    <xsl:text>with </xsl:text>
                    <xsl:value-of select="local-name()"/>
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="createDescription">
                        <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                    </xsl:call-template>
                    <xsl:if test="not(position() = last())">
                        <xsl:text> and </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$dataType = 'BackboneElement'">
                <xsl:text>with specific contents. This asserts checks if all children exist (if applicable with their specific values) and if they are present within one element. Following asserts check if individual children exist to help you debug if this assert fails</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="concat('TODO DESCRIPTION: ',$dataType)"/>
                <xsl:value-of select="'with ...'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="nts:contentAsserts" mode="modifyNts"/>
    
    <xsl:template match="nts:include[@value = 'medmij/test.xis.successfulSearch']" mode="modifyNts">
        <xsl:param name="responseId" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:if test="not(@responseId)">
                <xsl:attribute name="responseId" select="$responseId"/>
            </xsl:if>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="f:*" mode="addDataTypes">
        <xsl:param name="parentElementPath"/>
        <xsl:param name="parentDataType"/>
        <xsl:variable name="elementPath">
            <xsl:choose>
                <xsl:when test="string-length($parentElementPath) gt 0">
                    <xsl:value-of select="concat($parentElementPath, '.', local-name())"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="local-name()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dataType">
            <xsl:call-template name="getDataType">
                <xsl:with-param name="elementPath" select="$elementPath"/>
                <xsl:with-param name="parentDataType" select="$parentDataType"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="nts:dataType" select="$dataType"/>
            <xsl:apply-templates select="node()" mode="#current">
                <xsl:with-param name="parentElementPath" select="$elementPath"/>
                <xsl:with-param name="parentDataType" select="$dataType"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node()|@*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:function name="nf:get-element-base" as="xs:string">
        <xsl:param name="localName"/>
        <xsl:variable name="output">
            <xsl:analyze-string select="$localName" regex="^[a-z]+">
                <xsl:matching-substring>
                    <xsl:value-of select="."/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        
        <!-- Always return _something_ -->
        <xsl:choose>
            <xsl:when test="string-length($output) gt 0">
                <xsl:value-of select="$output"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$localName"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template name="substring-before-last">
        <xsl:param name="input" />
        <xsl:param name="substr" />
        <xsl:if test="$substr and contains($input, $substr)">
            <xsl:variable name="temp" select="substring-after($input, $substr)" />
            <xsl:value-of select="substring-before($input, $substr)" />
            <xsl:if test="contains($temp, $substr)">
                <xsl:value-of select="$substr" />
                <xsl:call-template name="substring-before-last">
                    <xsl:with-param name="input" select="$temp" />
                    <xsl:with-param name="substr" select="$substr" />
                </xsl:call-template>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>