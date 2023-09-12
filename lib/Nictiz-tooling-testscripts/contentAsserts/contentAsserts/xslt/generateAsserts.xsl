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
    <xsl:param name="fhirVersion" select="'R4'"/>
    
    <!-- Fixed, but could be dependant on fhirVersion -->
    <xsl:variable name="simpleDataTypes" as="xs:string*">
        <xsl:choose>
            <xsl:when test="lower-case($fhirVersion) = 'stu3'">
                <xsl:sequence select="('boolean','integer','string','decimal','uri','base64Binary','instant','date','dateTime','time','code','oid','id','markdown','unsignedInt','positiveInt')"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- R4 -->
                <xsl:sequence select="('boolean','integer','string','decimal','uri','url','canonical','base64Binary','instant','date','dateTime','time','code','oid','id','markdown','unsignedInt','positiveInt','uuid')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="complexDataTypes" select="('Annotation','Attachment','Coding','CodeableConcept','Quantity','SimpleQuantity','Distance','Age','Count','Duration','Money','Range','Ratio','Period','SampledData','Identifier','HumanName','Address','ContactPoint','Timing','Signature','Reference','Narrative','Meta')"/>
    
    <xsl:variable name="dataTypes" select="($simpleDataTypes, $complexDataTypes)"/>
    <xsl:variable name="dataTypesLower" select="for $i in $dataTypes return lower-case($i)"/>
    <xsl:variable name="simpleDataTypesLower" select="for $i in $simpleDataTypes return lower-case($i)"/>
    
    <xsl:param name="libPath" select="concat(string-join(tokenize(static-base-uri(), '/')[fn:position() lt last() - 1], '/'), '/lib/')"/>
    
    <!-- The main template, which will call the remaining templates. -->
    <xsl:template name="generateAsserts" match="f:TestScript">
        <xsl:if test="not(lower-case($fhirVersion) = ('stu3', 'r4'))">
            <xsl:message terminate="yes">FHIR Version <xsl:value-of select="$fhirVersion"/> not supported or not set.</xsl:message>
        </xsl:if>
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
        
        <!-- Load all fixtures -->
        <xsl:variable name="fixtures">
            <xsl:for-each select="nts:contentAsserts">
                <xsl:variable name="href" select="@href"/>
                <nts:fixture href="{$href}">
                    <xsl:variable name="fixtureUri" select="concat($basePath, '/', $referenceBase, $href)"/>
                    <xsl:copy-of select="document($fixtureUri)"/>
                </nts:fixture>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:for-each select="nts:contentAsserts">
            <xsl:variable name="href" select="@href"/>
            <xsl:variable name="expression" select="@expression"/>
            <xsl:variable name="bundleExpression" select="@bundleExpression"/>
            <xsl:if test="ends-with(translate($expression, ' ', ''), 'count()=1') or ends-with($expression, 'exists()') and not($bundleExpression = 'true')">
                <xsl:message terminate="yes">TOEDIT: Expression shouldn't end in count() or exists() - <xsl:value-of select="$expression"/></xsl:message>
            </xsl:if>
            <xsl:variable name="description" select="@description"/>
            
            <xsl:variable name="fixture" select="$fixtures/nts:fixture[@href = $href]/*"/>
            <xsl:variable name="fixtureId" select="$fixture/f:id/@value"/>
            
            <xsl:variable name="resourceType" select="$fixture/local-name()"/>
            <xsl:variable name="resourceCount" select="count($fixture/parent::nts:fixture/preceding-sibling::nts:fixture[*/local-name() = $resourceType]) + 1"/>
            <xsl:variable name="multipleExist" select="count($fixtures/nts:fixture[*/local-name() = $resourceType]) gt 1"/>
            
            <xsl:variable name="structureDefinition" select="document(concat($libPath, lower-case($fhirVersion), '/StructureDefinition-', $resourceType, '.xml'))"/>
            
            <!-- Would preferably do this in a separate step with Xproc. We'll see what the future brings -->
            <xsl:variable name="fixtureWithMetaData">
                <xsl:apply-templates select="$fixture" mode="addMetaData">
                    <xsl:with-param name="structureDefinition" select="$structureDefinition" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>
            <!-- debug -->
            <!--<xsl:result-document href="test{$resourceCount}.xml"><xsl:copy-of select="$fixtureWithMetaData"/></xsl:result-document>-->
            
            <xsl:variable name="newTestName">
                <xsl:value-of select="concat($testName, ' - Check ', $resourceType)"/>
                <xsl:if test="$multipleExist">
                    <xsl:value-of select="concat(' ', $resourceCount)"/>
                </xsl:if>
            </xsl:variable>
            
            <test>
                <name value="{$newTestName}"/>
                <description value="Check if the previous operation results in a FHIR {$resourceType} that contains the values that are expected following Nictiz' materials (fixture .id: {$fixtureId})"/>
                
                <!-- According to TestScript spec, the last available request/response will be used, so we do not specifically have to add a responseId. Could (should?) be a feature though -->
                <xsl:call-template name="createAssert">
                    <xsl:with-param name="description">
                        <xsl:choose>
                            <xsl:when test="string-length($description) gt 0">
                                <xsl:value-of select="concat('Response Bundle contains exactly 1 ', $resourceType, ' that ', $description)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('Response Bundle contains exactly 1 ', $resourceType)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                    <xsl:with-param name="expression">
                        <xsl:choose>
                            <xsl:when test="$bundleExpression = 'true'">
                                <xsl:value-of select="concat($expression, '.count() = 1')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('Bundle.entry.resource.ofType(', $resourceType, ')', $expression, '.count() = 1')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                    <xsl:with-param name="stopTestOnFail" select="true()"/>
                </xsl:call-template>
                <!-- Add an explicit assert to check Resource.id -->
                <xsl:call-template name="createAssert">
                    <xsl:with-param name="description" select="concat($resourceType, ' resource evaluated in the previous assert contains an .id')"/>
                    <xsl:with-param name="expression">
                        <xsl:choose>
                            <xsl:when test="$bundleExpression = 'true'">
                                <xsl:value-of select="concat($expression, '.id.exists()')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('Bundle.entry.resource.ofType(', $resourceType, ')', $expression, '.id.exists()')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                    <xsl:with-param name="stopTestOnFail" select="true()"/>
                </xsl:call-template>
                
                <!-- If the assert above passes, we know by definition that this variable will be evaluated. TestScripts will fail with an error if a variable cannot be evaluated, but to users it is not really clear what happens. The setup with the asserts above will prevent that hopefully. -->
                <xsl:variable name="idVariable" select="concat($fixtureId,'-id')"/>
                <variable>
                    <name value="{$idVariable}"/>
                    <description value="Resource.id for Observation {$resourceCount}"/>
                    <expression>
                        <xsl:attribute name="value">
                            <xsl:choose>
                                <xsl:when test="$bundleExpression = 'true'">
                                    <xsl:value-of select="concat($expression, '.id')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat('Bundle.entry.resource.ofType(', $resourceType, ')', $expression, '.id')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </expression>
                    <sourceId value="{$responseId}"/>
                </variable>
                
                <!-- After this, we can use the variable in all following asserts -->
                <xsl:apply-templates select="$fixtureWithMetaData/f:*/f:*" mode="generateAsserts">
                    <xsl:with-param name="resourceType" select="$resourceType" tunnel="yes"/>
                    <xsl:with-param name="idVariable" select="$idVariable" tunnel="yes"/>
                    <xsl:with-param name="parentLabel" select="$resourceCount"/>
                </xsl:apply-templates>
            </test>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="f:*" mode="generateAsserts">
        <xsl:param name="resourceType" tunnel="yes"/>
        <xsl:param name="idVariable" tunnel="yes"/>
        <xsl:param name="parentLabel" required="yes"/>
        <xsl:param name="parentElementPath" select="parent::*/@nts:elementPath"/>
        
        <!-- Need to use element/@id or element/path/@value? So far, they are identical in STU3 -->
        <xsl:variable name="elementPath" select="concat($parentElementPath, '.', local-name())"/>
        <xsl:variable name="expressionBase" select="concat('Bundle.entry.resource.ofType(', $resourceType, ').where(id = ''${', $idVariable, '}'')')"/>
        
        <xsl:variable name="dataType" select="@nts:dataType"/>
        
        <!-- Generate (part of) expression based on datatype -->
        <xsl:variable name="expression">
            <xsl:call-template name="createExpression">
                <xsl:with-param name="elementPath" select="$elementPath"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="label">
            <xsl:value-of select="$parentLabel"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="fn:count(preceding-sibling::*[not(self::f:id)]) + (if (@nts:extensionsRemoved and not(@value)) then xs:integer(@nts:extensionsRemoved) else 0) + (if (parent::*/@nts:extensionsRemoved) then xs:integer(parent::*/@nts:extensionsRemoved) else 0) + (if (parent::*/@value) then 2 else 1)"/>
        </xsl:variable>
        
        <xsl:variable name="description">
            <xsl:call-template name="createDescription">
                <xsl:with-param name="elementPath" select="$elementPath"/>
            </xsl:call-template>
            <!-- If there are two hyphens or more in label -->
            <xsl:if test="string-length($label) - string-length(translate($label, '-', '')) ge 2">
                <xsl:value-of select="concat('. This assert checks only one child. Assert ', $parentLabel, ' checks if all children are present in the same parent')"/>
            </xsl:if>
            <xsl:if test="($dataType = ('BackboneElement', 'Extension') and count(*) gt 1) or f:extension or f:modifierExtension">
                <xsl:value-of select="'. This assert checks if all children exist (if applicable with their specific values) and if they are present within one element. Following asserts check if individual children exist to help you debug if this assert fails'"/>
            </xsl:if>
        </xsl:variable>
        
        <xsl:if test="string-length($expression) gt 0">
            <xsl:call-template name="createAssert">
                <xsl:with-param name="description" select="concat('Contains ', $description)"/>
                <xsl:with-param name="expression" select="concat($expressionBase,substring-after($parentElementPath, $resourceType),'.', $expression)"/>
                <xsl:with-param name="label" select="$label"/>
                <xsl:with-param name="warningOnly">
                    <xsl:choose>
                        <!-- Impossible to determine if code-specification is required without accessing ConceptMaps, so putting them all on warningOnly for now -->
                        <xsl:when test="descendant-or-self::f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/code-specification']">
                            <xsl:value-of select="true()"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="false()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$dataType = 'dateTime'">
            <!-- By default, we only check if dateTimes exist. Additionally, there are extra scenario's we can use to check: 
            - If T-dates are used, we can check exact match (warningOnly = false)
            - If multiple dates are used, we can check either:
            - - Exact difference (calculate exact differences between dates and check with assert)
            - - Relative difference (use < and/or > to compare them)
            -->
            <xsl:variable name="expressionPrefix">
                <xsl:value-of select="fn:substring-before(fn:substring-after($elementPath, concat($resourceType, '.')),nf:get-element-base(local-name()))"/>
                <xsl:choose>
                    <xsl:when test="@nts:polymorphic = 'true'">
                        <xsl:value-of select="nf:get-element-base(local-name())"/>
                        <xsl:text>.ofType(</xsl:text>
                        <xsl:value-of select="@nts:dataType"/>
                        <xsl:text>)</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="local-name()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="descriptionPrefix">
                <xsl:choose>
                    <xsl:when test="string-length($parentElementPath) gt 0">
                        <xsl:value-of select="concat(substring-after($elementPath, $parentElementPath), ' ')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat(substring-after($elementPath, $resourceType), ' ')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:choose>
                <!-- T-date -->
                <xsl:when test="matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}')">
                    <xsl:variable name="expression">
                        <xsl:value-of select="$expressionPrefix"/>
                        <xsl:text> ~ @${T} </xsl:text>
                        <xsl:call-template name="analyzeTDate"/>
                    </xsl:variable>
                    <xsl:variable name="description">
                        <xsl:value-of select="$descriptionPrefix"/>
                        <xsl:text>with a value that equals T-date </xsl:text>
                        <xsl:call-template name="analyzeTDate"/>
                    </xsl:variable>
                    
                    <xsl:call-template name="createAssert">
                        <xsl:with-param name="description" select="concat('Contains ', $description)"/>
                        <xsl:with-param name="expression" select="concat($expressionBase,substring-after($parentElementPath, $resourceType),'.', $expression)"/>
                        <xsl:with-param name="label" select="concat($label, '-checkDateTime')"/>
                        <xsl:with-param name="warningOnly" select="true()"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="fn:count(ancestor::*[position()=last()]//*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]) gt 1 and preceding::*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]">
                    <xsl:variable name="dateTime1" select="preceding::*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))][last()]"/>
                    <xsl:variable name="durationAsString" select="xs:string(xs:date(./@value) - xs:date($dateTime1/@value))" />
                    
                    <xsl:variable name="expression">
                        <!-- KT-393 -->
                        <xsl:text>.where(</xsl:text>
                        <!--<xsl:text>exists(</xsl:text>-->
                        <xsl:value-of select="$expressionPrefix"/>
                        <xsl:choose>
                            <xsl:when test="starts-with($durationAsString, '-')"> &lt; </xsl:when>
                            <xsl:otherwise> &gt; </xsl:otherwise>
                        </xsl:choose>
                        <xsl:value-of select="fn:substring-before(fn:substring-after($dateTime1/@nts:elementPath, concat($resourceType, '.')),nf:get-element-base(local-name()))"/>
                        <xsl:choose>
                            <xsl:when test="$dateTime1/@nts:polymorphic = 'true'">
                                <xsl:value-of select="nf:get-element-base($dateTime1/local-name())"/>
                                <xsl:text>.ofType(</xsl:text>
                                <xsl:value-of select="$dateTime1/@nts:dataType"/>
                                <xsl:text>)</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$dateTime1/local-name()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>)</xsl:text>
                        <!-- KT-393 -->
                        <xsl:text>.exists()</xsl:text>
                    </xsl:variable>
                    <xsl:variable name="description">
                        <xsl:value-of select="$descriptionPrefix"/>
                        <xsl:text>which is </xsl:text>
                        <xsl:choose>
                            <xsl:when test="starts-with($durationAsString, '-')">earlier than </xsl:when>
                            <xsl:otherwise>later than .</xsl:otherwise>
                        </xsl:choose>
                        <xsl:value-of select="$dateTime1/local-name()"/>
                    </xsl:variable>
                    
                    <xsl:call-template name="createAssert">
                        <xsl:with-param name="description" select="concat('Contains ', $description)"/>
                        <xsl:with-param name="expression" select="concat($expressionBase, $expression)"/>
                        <xsl:with-param name="label" select="concat($label, '-checkDateTime')"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
            
            <!-- Compare 2 dates -->
            <!--<xsl:when test="$dataType = 'dateTime' and fn:count(ancestor::*[position()=last()]//*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]) gt 1">
                        <!-\- KT-393 -\->
                        <xsl:text>where(</xsl:text>
                        <!-\-<xsl:text>exists(</xsl:text>-\->
                        <xsl:value-of select="$expressionPrefix"/>
                        <!-\- There are multiple dateTimes. We calculate the difference with the first and put that in an assert -\->
                        <xsl:variable name="dateTime1" select="preceding::*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))][last()]"/>
                        <!-\- Duration is in days. When taking into account leap years, I think it is difficult to split up this number in years/months/days -\->
                        <xsl:variable name="duration" select="xs:date(./@value) - xs:date($dateTime1/@value)" />
                        <xsl:text> ~ </xsl:text>
                        <xsl:choose>
                            <xsl:when test="$dateTime1/@nts:polymorphic = 'true'">
                                <xsl:value-of select="nf:get-element-base($dateTime1/local-name())"/>
                                <xsl:text>.ofType(</xsl:text>
                                <xsl:value-of select="$dateTime1/@nts:dataType"/>
                                <xsl:text>)</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$dateTime1/local-name()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text> + </xsl:text>
                        <xsl:value-of select="days-from-duration($duration)"/>
                        <xsl:text> days)</xsl:text>
                        <!-\- KT-393 -\->
                        <xsl:text>.exists()</xsl:text>
                </xsl:choose>
            </xsl:when>-->
        </xsl:if>
            
        <xsl:if test="$dataType = 'Identifier'">
            <!-- System should not contain Nictiz OID or 'example-xis' url -->
        </xsl:if>
        
        <!-- For some elements, we want te create additional asserts -->
        <!-- If one ore more extensions are present (and if not BackboneElement), we would like to create separate asserts for the extension and treat the rest of the element as if the extension wasn't there -->
        <xsl:if test="(f:extension or f:modifierExtension) and not($dataType = 'BackboneElement')">
            <xsl:variable name="simpleElement">
                <xsl:apply-templates select="." mode="copyWithoutExtensions"/>
            </xsl:variable>
            
            <xsl:choose>
                <!-- When there is a value, we would like to assert that first -->
                <xsl:when test="@value">
                    <xsl:apply-templates select="$simpleElement" mode="#current">
                        <xsl:with-param name="parentElementPath" select="$parentElementPath"/>
                        <xsl:with-param name="parentLabel" select="$label"/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="f:extension|f:modifierExtension" mode="#current">
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
                </xsl:when>
                <!-- Otherwise extensions first -->
                <xsl:otherwise>
                    <xsl:apply-templates select="f:extension|f:modifierExtension" mode="#current">
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
                    <!-- Edge case: complex extensions where there are no children other than extensions -->
                    <xsl:if test="*[not(self::f:extension) and not(self::f:modifierExtension)]">
                        <xsl:apply-templates select="$simpleElement" mode="#current">
                            <xsl:with-param name="parentElementPath" select="$parentElementPath"/>
                            <xsl:with-param name="parentLabel" select="$label"/>
                        </xsl:apply-templates>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
                
        <xsl:if test="$dataType = 'BackboneElement' and count(*) gt 1">
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
        
        <xsl:variable name="expressionPrefix">
            <xsl:choose>
                <xsl:when test="@nts:polymorphic = 'true'">
                    <xsl:value-of select="nf:get-element-base(local-name())"/>
                    <xsl:text>.ofType(</xsl:text>
                    <xsl:value-of select="@nts:dataType"/>
                    <xsl:text>)</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="local-name()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="expression">
            <!-- We need to make a separation between element without children (simple data types) and with children (simple data types with extensions and complex data types). Expression for simple data types without children are ... simpler -->
            <xsl:choose>
                <xsl:when test="$dataType = 'id' or ($dataType = 'http://hl7.org/fhirpath/System.String' and self::f:id)">
                    <!-- An assert for Resource.id has been made earlier in the process because it is essential. So here we do nothing -->
                    <!-- For some reason, the official data type of .id in R4 is this System.String thing -->
                </xsl:when>
                <xsl:when test="f:*">
                    <xsl:value-of select="$expressionPrefix"/>
                    <xsl:choose>
                        <!-- When simple data type (may or may not have @value) contains extension -->
                        <xsl:when test="$dataType = $simpleDataTypes and f:extension">
                            <!-- Failing because of KT-393  -->
                            <!--<xsl:choose>
                                <xsl:when test="$topLevel = true()">
                                    <xsl:text>.exists(</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>-->
                            <xsl:text>.where(</xsl:text>
                            <!--</xsl:otherwise>
                            </xsl:choose>-->
                            <xsl:if test="@value">
                                <xsl:text>$this</xsl:text>
                                <xsl:call-template name="createExpressionSimple"/>
                                <xsl:text> and </xsl:text>
                            </xsl:if>
                            <xsl:for-each select="*">
                                <xsl:call-template name="createExpression">
                                    <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                                    <xsl:with-param name="topLevel" select="false()"/>
                                </xsl:call-template>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:text>)</xsl:text>
                            <!-- Temp because of KT-393 -->
                            <xsl:if test="$topLevel = true()">
                                <xsl:text>.exists()</xsl:text>
                            </xsl:if>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Attachment'">
                            <xsl:call-template name="createExpressionExtension">
                                <xsl:with-param name="elementPath" select="$elementPath"/>
                            </xsl:call-template>
                            <xsl:text>.where(</xsl:text>
                            <xsl:for-each select="*[self::f:contentType or self::f:language]">
                                <xsl:call-template name="createExpression">
                                    <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                                    <xsl:with-param name="topLevel" select="false()"/>
                                </xsl:call-template>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:if test="f:data or f:url">
                                <xsl:if test="*[self::f:contentType or self::f:language]">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                                <xsl:if test="*[not(self::f:data) and not(self::f:url)]">
                                    <xsl:text>(</xsl:text>
                                </xsl:if>
                                <xsl:text>data or url</xsl:text>
                                <xsl:if test="*[not(self::f:data) and not(self::f:url)]">
                                    <xsl:text>)</xsl:text>
                                </xsl:if>
                                <xsl:if test="*[not(self::f:contentType) and not(self::f:language) and not(self::f:data) and not(self::f:url)]">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:if>
                            <xsl:for-each select="*[not(self::f:contentType) and not(self::f:language) and not(self::f:data) and not(self::f:url)]">
                                <xsl:call-template name="createExpression">
                                    <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                                    <xsl:with-param name="topLevel" select="false()"/>
                                </xsl:call-template>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:text>).exists()</xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Identifier'">
                            <xsl:if test="f:extension">
                                <xsl:message select="concat('UNHANDLED EXTENSION EXPRESSION: ', $elementPath, ' - ',$dataType)"/>
                            </xsl:if>
                            <!-- KT-393 -->
                            <xsl:text>.where(</xsl:text>
                            <!--<xsl:text>.exists(</xsl:text>-->
                            <xsl:choose>
                                <xsl:when test="f:system">system</xsl:when>
                                <xsl:when test="f:type">type</xsl:when>
                            </xsl:choose>
                            <!-- KT-393 R4 -->
                            <xsl:if test="$fhirVersion = 'R4'">
                                <xsl:text>.exists()</xsl:text>
                            </xsl:if>
                            <xsl:text> and value</xsl:text>
                            <!-- KT-393 R4 -->
                            <xsl:if test="$fhirVersion = 'R4'">
                                <xsl:text>.exists()</xsl:text>
                            </xsl:if>
                            <xsl:text>)</xsl:text>
                            <!-- KT-393 -->
                            <xsl:text>.exists()</xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Reference'">
                            <xsl:call-template name="createExpressionExtension">
                                <xsl:with-param name="elementPath" select="$elementPath"/>
                            </xsl:call-template>
                            <!-- Check if (reference OR identifier) and display exist -->
                            <!-- KT-393 -->
                            <xsl:text>.where((reference</xsl:text>
                            <!-- KT-393 R4 -->
                            <xsl:if test="$fhirVersion = 'R4'">
                                <xsl:text>.exists()</xsl:text>
                            </xsl:if>
                            <xsl:text> or identifier</xsl:text>
                            <!-- KT-393 R4 -->
                            <xsl:if test="$fhirVersion = 'R4'">
                                <xsl:text>.exists()</xsl:text>
                            </xsl:if>
                            <xsl:text>) and display</xsl:text>
                            <!-- KT-393 R4 -->
                            <xsl:if test="$fhirVersion = 'R4'">
                                <xsl:text>.exists()</xsl:text>
                            </xsl:if>
                            <xsl:text>).exists()</xsl:text>
                            <!--<xsl:text>.exists((reference or identifier) and display)</xsl:text>-->
                        </xsl:when>
                        <xsl:when test="$dataType = 'Narrative' and f:status/@value = 'extensions'">
                            <!-- Narrative isn't always present in fixtures. If not present, it is generated at a later stage. We should find a way to always add this assert. -->
                            <xsl:text>.exists()</xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = ('Annotation','BackboneElement','CodeableConcept','Coding','Extension','Meta','Period','Quantity')">
                            <xsl:if test="$dataType = 'Extension'">
                                <xsl:text>('</xsl:text>
                                <xsl:value-of select="@url"/>
                                <xsl:text>')</xsl:text>
                            </xsl:if>
                            <!-- Failing because of KT-393  -->
                            <!--<xsl:choose>
                                <xsl:when test="$topLevel = true()">
                                    <xsl:text>.exists(</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>-->
                                    <xsl:text>.where(</xsl:text>
                                <!--</xsl:otherwise>
                            </xsl:choose>-->
                            <xsl:for-each select="*">
                                <xsl:call-template name="createExpression">
                                    <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                                    <xsl:with-param name="topLevel" select="false()"/>
                                </xsl:call-template>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:text>)</xsl:text>
                            <!-- Temp because of KT-393, always apply in R4 -->
                            <xsl:if test="$topLevel = true() or $fhirVersion = 'R4'">
                                <xsl:text>.exists()</xsl:text>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message select="concat('TODO EXPRESSION: ', $elementPath, ' - ',$dataType)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$expressionPrefix"/>
                    <xsl:call-template name="createExpressionSimple">
                        <xsl:with-param name="topLevel" select="$topLevel"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="string-length($expression) gt 0">
            <xsl:value-of select="$expression"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="createExpressionSimple">
        <xsl:param name="dataType" select="@nts:dataType"/>
        <xsl:param name="parentDataType" select="parent::f:*/@nts:dataType"/>
        <xsl:param name="topLevel" select="true()"/>
        
        <xsl:variable name="expression">
            <xsl:choose>
                <xsl:when test="$parentDataType = 'Attachment'">
                    <!-- In Attachment, there is hardly anything that we can reliably check for more than existance, so we do nothing here. -->
                </xsl:when>
                <xsl:when test="$dataType = ('boolean','decimal')">
                    <xsl:value-of select="concat(' = ', @value)"/>
                </xsl:when>
                <xsl:when test="$dataType = 'string' and $parentDataType = ('Coding','Quantity')">
                    <!-- This is .display (in Coding) or .unit (in Quantity), and by definition not topLevel, so we do not have to do anything -->
                    <!-- KT-393 R4 -->
                    <xsl:if test="$fhirVersion = 'R4'">
                        <xsl:text>.exists()</xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$dataType = 'string'">
                    <!-- '~' (equivalence) ignores case and whitespace. replace('.', '') removes dot and comma (or other characters - hyphens perhaps?). Or should we be allowed to define overrides in our NTS-script? -->
                    <xsl:value-of select="concat('.replace(''.'', '''').replace('','', '''') ~ ''', normalize-space(translate(@value, '.,', '')), '''')"/>
                </xsl:when>
                <xsl:when test="$dataType = 'dateTime'">
                    <!-- For now we only check if dateTime exist -->
                    <!-- KT-393 R4 -->
                    <xsl:if test="$topLevel = true() or $fhirVersion = 'R4'">
                        <xsl:text>.exists()</xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$dataType = 'code' and $parentDataType = 'Quantity'">
                    <!-- .code can contain UCUM parentheses -->
                    <xsl:choose>
                        <xsl:when test="contains(@value, '{') and contains(@value, '}') ">
                            <xsl:text>.matches('^</xsl:text>
                            <xsl:analyze-string select="@value" regex="\{{.*\}}">
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
                            <xsl:value-of select="concat(' = ''', @value, '''')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$dataType = 'code' or ($dataType = 'uri' and $parentDataType = ('Coding','Quantity'))">
                    <!-- For uri's in Coding and Quantity (.system) we want an exact match. I can imagine that in some situations we want to only check for existance. -->
                    <xsl:value-of select="concat(' = ''', @value, '''')"/>
                </xsl:when>
                <xsl:when test="$dataType = ('uri','canonical') and $parentDataType = 'Meta'">
                    <!-- We want an exact match, but because .profile has max cardinality of * we have to use this construction. Just using '=' would mean _all_ .profiles present would have to be @value. -->
                    <!-- KT-393 -->
                    <xsl:text>.where($this = '</xsl:text>
                    <!--<xsl:text>.exists($this = '</xsl:text>-->
                    <xsl:value-of select="@value"/>
                    <xsl:text>')</xsl:text>
                    <!-- KT-393 -->
                    <xsl:text>.exists()</xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = 'uri'">
                    <!-- For other uri's we assume there doesn't have to be an exact match. -->
                    <!-- KT-393 R4 -->
                    <xsl:if test="$topLevel = true() or $fhirVersion = 'R4'">
                        <xsl:text>.exists()</xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="concat('TODO SIMPLE EXPRESSION: ',local-name(), ' - ',$dataType)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:value-of select="$expression"/>
    </xsl:template>
    
    <xsl:template name="createExpressionExtension">
        <xsl:param name="elementPath" required="yes"></xsl:param>
        <xsl:if test="f:extension">
            <xsl:text>.where(</xsl:text>
            <xsl:for-each select="f:extension">
                <xsl:call-template name="createExpression">
                    <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                    <xsl:with-param name="topLevel" select="false()"/>
                </xsl:call-template>
                <xsl:if test="not(position() = last())">
                    <xsl:text> and </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>)</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="createDescription">
        <xsl:param name="elementPath"/>
        <xsl:param name="parentElementPath"/>
        <xsl:param name="dataType" select="@nts:dataType"/>
        <xsl:param name="parentDataType" select="parent::f:*/@nts:dataType"/>
        <xsl:param name="resourceType" tunnel="yes"/>
        
        <xsl:variable name="descriptionPrefix">
            <xsl:choose>
                <xsl:when test="string-length($parentElementPath) gt 0">
                    <xsl:value-of select="substring-after($elementPath, $parentElementPath)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring-after($elementPath, $resourceType)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="description">
            <!-- We need to make a separation between element without children (simple data types) and with children (simple data types with extensions and complex data types). Expression for simple data types without children are ... simpler -->
            <xsl:choose>
                <xsl:when test="$dataType = 'id' or ($dataType = 'http://hl7.org/fhirpath/System.String' and self::f:id)">
                    <!-- An assert for Resource.id has been made earlier in the process because it is essential. So here we do nothing -->
                    <!-- For some reason, the official data type of .id in R4 is this System.String thing -->
                </xsl:when>
                <xsl:when test="f:*">
                    <xsl:choose>
                        <xsl:when test="$dataType = $simpleDataTypes and f:extension and f:extension">
                            <xsl:if test="@value">
                                <xsl:call-template name="createDescriptionSimple"/>
                                <xsl:text> and </xsl:text>
                            </xsl:if>
                            <xsl:text>with </xsl:text>
                            <xsl:for-each select="*">
                                <xsl:call-template name="createDescription">
                                    <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                                    <xsl:with-param name="parentElementPath" select="$elementPath"/>
                                </xsl:call-template>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Attachment'">
                            <xsl:call-template name="createDescriptionExtension">
                                <xsl:with-param name="elementPath" select="$elementPath"/>
                            </xsl:call-template>
                            <xsl:text>with </xsl:text>
                            <xsl:for-each select="*[self::f:contentType or self::f:language]">
                                <xsl:variable name="description">
                                    <xsl:call-template name="createDescription">
                                        <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                                        <xsl:with-param name="parentElementPath" select="$elementPath"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="fn:string-length($description) gt 0">
                                    <xsl:value-of select="$description"/>
                                </xsl:if>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:if test="f:data or f:url">
                                <xsl:if test="*[self::f:contentType or self::f:language]">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                                <xsl:text>with either .data or .url</xsl:text>
                                <xsl:if test="*[not(self::f:contentType) and not(self::f:language) and not(self::f:data) and not(self::f:url)]">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:if>
                            <xsl:for-each select="*[not(self::f:contentType) and not(self::f:language) and not(self::f:data) and not(self::f:url)]">
                                <xsl:variable name="description">
                                    <xsl:call-template name="createDescription">
                                        <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                                        <xsl:with-param name="parentElementPath" select="$elementPath"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="fn:string-length($description) gt 0">
                                    <xsl:value-of select="$description"/>
                                </xsl:if>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Identifier'">
                            <xsl:if test="f:extension">
                                <xsl:message select="concat('UNHANDLED EXTENSION DESCRIPTION: ', $elementPath, ' - ',$dataType)"/>
                            </xsl:if>
                            <xsl:text>with .</xsl:text>
                            <xsl:choose>
                                <xsl:when test="f:system">system</xsl:when>
                                <xsl:when test="f:type">type</xsl:when>
                            </xsl:choose>
                            <xsl:text> and .value</xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Reference'">
                            <xsl:call-template name="createDescriptionExtension">
                                <xsl:with-param name="elementPath" select="$elementPath"/>
                            </xsl:call-template>
                            <xsl:text>with either .reference or .identifier and .display</xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Narrative' and f:status/@value = 'extensions'">
                            <!-- Nothing to add -->
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = ('Annotation','BackboneElement','CodeableConcept','Coding','Extension','Meta','Period','Quantity')">
                            <xsl:if test="$dataType = 'Extension'">
                                <xsl:value-of select="concat('with url ''', @url, ''' ')"/>
                            </xsl:if>
                            <xsl:text>with </xsl:text>
                            <xsl:for-each select="*">
                                <xsl:variable name="description">
                                    <xsl:call-template name="createDescription">
                                        <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                                        <xsl:with-param name="parentElementPath" select="$elementPath"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:if test="fn:string-length($description) gt 0">
                                    <xsl:value-of select="$description"/>
                                </xsl:if>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message select="concat('TODO DESCRIPTION: ', $elementPath, ' - ',$dataType)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="createDescriptionSimple"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="string-length($description) gt 0">
            <xsl:choose>
                <xsl:when test="string-length(normalize-space($description)) gt 0">
                    <xsl:value-of select="concat($descriptionPrefix, ' ',normalize-space($description))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($descriptionPrefix, normalize-space($description))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="createDescriptionSimple">
        <xsl:param name="dataType" select="@nts:dataType"/>
        <xsl:param name="parentDataType" select="parent::f:*/@nts:dataType"/>
        
        <xsl:choose>
            <xsl:when test="$parentDataType = 'Attachment'">
                <!-- In Attachment, there is hardly anything that we can reliably check for more than existance, so we do nothing here. -->
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:when test="$dataType = 'dateTime' or ($dataType = 'string' and $parentDataType = ('Coding','Quantity'))">
                <!-- Nothing to be added, as we only check existance -->
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:when test="$dataType = ('boolean','decimal','string') or ($dataType = ('uri','canonical') and $parentDataType = ('Coding','Meta','Quantity'))">
                <!-- For uri's in Coding and Quantity (.system) or Meta (.profile, uri is canonical in R4), we want an exact match. I can imagine that in some situations we want to only check for existance. -->
                <xsl:value-of select="concat('''', @value, '''')"/>
            </xsl:when>
            <xsl:when test="$dataType = 'uri'">
                <!-- Nothing to be added, as we only check existance -->
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:when test="$dataType = 'code'">
                <xsl:variable name="value" select="@value"/>
                <xsl:choose>
                    <xsl:when test="$parentDataType = 'Quantity' and contains($value, '{') and contains($value, '}') ">
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
                        <xsl:value-of select="concat('''', @value, '''')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="concat('TODO SIMPLE DESCRIPTION: ',$dataType)"/>
                <xsl:value-of select="'with ...'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="createDescriptionExtension">
        <xsl:param name="elementPath" required="yes"/>
        <xsl:if test="f:extension">
            <xsl:text>with </xsl:text>
            <xsl:for-each select="f:extension">
                <xsl:call-template name="createDescription">
                    <xsl:with-param name="elementPath" select="concat($elementPath, '.', local-name())"/>
                    <xsl:with-param name="parentElementPath" select="$elementPath"/>
                </xsl:call-template>
                <xsl:if test="position() = last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
                <xsl:text> and </xsl:text>
            </xsl:for-each>
        </xsl:if>
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
    
    <xsl:template match="f:*" mode="addMetaData">
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
        <xsl:variable name="metaData" as="element(nts:metaData)">
            <xsl:call-template name="getMetaData">
                <xsl:with-param name="elementPath" select="$elementPath"/>
                <xsl:with-param name="parentDataType" select="$parentDataType"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$metaData/@nts:dataType = 'Identifier' and preceding-sibling::*[local-name() = fn:current()/local-name()]">
                <xsl:message>Double Identifier detected: <xsl:value-of select="$elementPath"/> - Please check if this is a specific use case or not. If yes, it should be added to generateAsserts</xsl:message>
            </xsl:when>
            <xsl:otherwise>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:copy-of select="$metaData/@*"/>
            <xsl:apply-templates select="node()" mode="#current">
                <xsl:with-param name="parentElementPath" select="$elementPath"/>
                <xsl:with-param name="parentDataType" select="$metaData/@nts:dataType"/>
            </xsl:apply-templates>
        </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="node()|@*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node()|@*" mode="copyWithoutExtensions" priority="1">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <!-- Count the number of extensions removed to be able to adjust the label count -->
            <xsl:if test="f:extension or f:modifierExtension">
                <xsl:attribute name="nts:extensionsRemoved" select="count(f:extension) + count(f:modifierExtension)"/>
            </xsl:if>
            <xsl:apply-templates select="node()[not(self::f:extension) and not(self::f:modifierExtension)]" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="getMetaData">
        <xsl:param name="resourceType" tunnel="yes"/>
        <xsl:param name="structureDefinition" tunnel="yes"/>
        <xsl:param name="elementPath" required="yes"/>
        <xsl:param name="parentDataType"/>
        
        <xsl:variable name="polymorphicElementPath" select="concat(substring-before($elementPath, local-name()), nf:get-element-base(local-name()), '[x]')"/>
        <xsl:variable name="polymorphicDataType" select="nf:datatype-case(substring-after(local-name(), nf:get-element-base(local-name())))"/>
        
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
        
        <nts:metaData>
            <xsl:choose>
                <xsl:when test="$structureDefinition/f:StructureDefinition/f:snapshot/f:element/@id = $elementPath">
                    <!-- In StructureDefinitions, References have an f:type for each targetProfile. Using distinct-values to filter that (because I still want to know if it outputs multiple hits) -->
                    
                    <xsl:attribute name="nts:dataType">
                        <xsl:value-of select="distinct-values($structureDefinition/f:StructureDefinition/f:snapshot/f:element[@id = $elementPath]/f:type/f:code/@value)"/>
                    </xsl:attribute>
                    <xsl:attribute name="nts:polymorphic" select="'false'"/>
                </xsl:when>
                <xsl:when test="$structureDefinition/f:StructureDefinition/f:snapshot/f:element/@id = $polymorphicElementPath">
                    <!-- Element is polymorphic, lets use its name to guess data type -->
                    <xsl:attribute name="nts:dataType">
                        <xsl:value-of select="distinct-values($structureDefinition/f:StructureDefinition/f:snapshot/f:element[@id = $polymorphicElementPath]/f:type/f:code/@value[lower-case(.) = lower-case($polymorphicDataType)])"/>
                    </xsl:attribute>
                    <xsl:attribute name="nts:polymorphic" select="'true'"/>
                </xsl:when>
                <!-- If extension, datatype is extension. Not present in Snapshot -->
                <xsl:when test="self::f:extension or self::f:modifierExtension">
                    <xsl:attribute name="nts:dataType">Extension</xsl:attribute>
                    <xsl:attribute name="nts:polymorphic" select="'false'"/>
                </xsl:when>
                <!-- If parent is extension, definition of extension isn't in Snapshot - this means datatype is value[x] -->
                <xsl:when test="parent::f:extension or parent::f:modifierExtension">
                    <xsl:attribute name="nts:dataType">
                        <xsl:value-of select="$polymorphicDataType"/>
                    </xsl:attribute>
                    <xsl:attribute name="nts:polymorphic" select="'true'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>Could not find <xsl:value-of select="$elementPath"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <!-- For the greatest flexibility we actually need two attributes: elementPath and fhirPath. They are slightly different when it comes to handling extensions and polymorphic elements. We could probably use a third attribute specifically for the description aswell. -->
            <xsl:attribute name="nts:elementPath">
                <!--<xsl:choose>
                    <xsl:when test="self::f:extension or self::f:modifierExtension">
                        <xsl:value-of select="concat($elementPath,'(''',@url,''')')"/>
                    </xsl:when>
                    <xsl:otherwise>-->
                        <xsl:value-of select="$elementPath"/>
                    <!--</xsl:otherwise>
                </xsl:choose>-->
            </xsl:attribute>
        </nts:metaData>
    </xsl:template>
    
    <xsl:function name="nf:get-element-base" as="xs:string">
        <xsl:param name="localName"/>
        <xsl:variable name="output">
            <xsl:analyze-string select="$localName" regex="^[a-zA-Z][a-z]+(([A-Z][a-z]+)+)">
                <xsl:matching-substring>
                    <xsl:value-of select="substring-before($localName, regex-group(1))"/>
                    <xsl:choose>
                        <xsl:when test="lower-case(regex-group(1)) = $dataTypesLower"/>
                        <xsl:otherwise>
                            <xsl:value-of select="nf:get-element-base(regex-group(1))"/>
                        </xsl:otherwise>
                    </xsl:choose>
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
    
    <xsl:function name="nf:datatype-case" as="xs:string">
        <xsl:param name="dataType"/>
        <xsl:choose>
            <xsl:when test="lower-case($dataType) = $simpleDataTypesLower">
                <xsl:choose>
                    <xsl:when test="lower-case($dataType) = 'datetime'">
                        <xsl:text>dateTime</xsl:text>
                    </xsl:when>
                    <xsl:when test="lower-case($dataType) = 'unsignedint'">
                        <xsl:text>unsignedInt</xsl:text>
                    </xsl:when>
                    <xsl:when test="lower-case($dataType) = 'positiveint'">
                        <xsl:text>positiveInt</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="lower-case($dataType)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$dataType"/>
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
    
    <xsl:template name="analyzeTDate">
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
    </xsl:template>
    
</xsl:stylesheet>