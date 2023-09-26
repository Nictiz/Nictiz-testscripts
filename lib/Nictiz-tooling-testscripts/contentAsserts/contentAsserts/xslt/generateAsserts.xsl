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
            
            <xsl:variable name="structureDefinition" select="document(concat($libPath, lower-case($fhirVersion), '/', $resourceType, '.xml'))"/>
            
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
        <xsl:param name="skipExtensions" select="false()"/>
        
        <xsl:variable name="parentFhirPath" select="parent::*/@nts:fhirPath"/>
        <xsl:variable name="fhirPath" select="@nts:fhirPath"/>
        
        <xsl:variable name="expressionBase" select="concat('Bundle.entry.resource.ofType(', $resourceType, ').where(id = ''${', $idVariable, '}'')')"/>
        
        <xsl:variable name="dataType" select="@nts:dataType"/>
        
        <!-- Generate (part of) expression based on datatype -->
        <xsl:variable name="expression">
            <xsl:call-template name="createExpression">
                <xsl:with-param name="focusFhirPath" select="$parentFhirPath"/>
                <xsl:with-param name="skipExtensions" select="$skipExtensions"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="label">
            <xsl:value-of select="$parentLabel"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="(if ($skipExtensions = false()) then count(preceding-sibling::*[not(self::f:id)]) else count(f:extension|f:modifierExtension)) + (if (parent::*/@value) then 2 else 1)"/>
        </xsl:variable>
        
        <!--<xsl:message>===</xsl:message>
        <xsl:message select="$label"/>-->
        
        <xsl:variable name="description">
            <xsl:call-template name="createDescription">
                <xsl:with-param name="resourceTypeFocus" select="true()"/>
                <xsl:with-param name="skipExtensions" select="$skipExtensions"/>
            </xsl:call-template>
            <!-- If there are two hyphens or more in label -->
            <xsl:if test="string-length($label) - string-length(translate($label, '-', '')) ge 2">
                <xsl:value-of select="concat('. This assert checks only one child. Assert ', $parentLabel, ' checks if all children are present in the same parent')"/>
            </xsl:if>
            <xsl:if test="($dataType = ('BackboneElement', 'Extension') and count(*) gt 1) or ((f:extension or f:modifierExtension) and $skipExtensions = false())">
                <xsl:value-of select="'. This assert checks if all children exist (if applicable with their specific values) and if they are present within one element. Following asserts check if individual children exist to help you debug if this assert fails'"/>
            </xsl:if>
        </xsl:variable>
        
        <!--<xsl:message>===</xsl:message>
        <xsl:message>
            <xsl:value-of select="$parentFhirPath"/>
        </xsl:message>
        <xsl:message select="$expression"/>
        <xsl:message>
            <xsl:choose>
                <xsl:when test="contains($parentFhirPath, '{$_EXPR}')">
                    <xsl:value-of select="concat($expressionBase,substring-after(replace($parentFhirPath, '{$_EXPR}', normalize-space($expression), 'q'), $resourceType),'.exists()')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($expressionBase,substring-after($parentFhirPath, $resourceType), '.', $expression)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:message>-->
        
        <xsl:if test="string-length($expression) gt 0">
            <xsl:call-template name="createAssert">
                <xsl:with-param name="description" select="concat('Contains ', $description)"/>
                <xsl:with-param name="expression">
                    <xsl:choose>
                        <xsl:when test="contains($parentFhirPath, '{$_EXPR}')">
                            <xsl:value-of select="concat($expressionBase,substring-after(replace($parentFhirPath, '{$_EXPR}', normalize-space($expression), 'q'), $resourceType),'.exists()')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($expressionBase,substring-after($parentFhirPath, $resourceType), '.', $expression)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="label" select="$label"/>
                <xsl:with-param name="warningOnly">
                    <xsl:choose>
                        <!-- Impossible to determine if code-specification is required without accessing ConceptMaps, so putting them all on warningOnly for now -->
                        <xsl:when test="descendant-or-self::f:extension[@url = 'http://nictiz.nl/fhir/StructureDefinition/code-specification'] and $skipExtensions = false()">
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
                <xsl:choose>
                    <xsl:when test="string-length(substring-after($fhirPath, $parentFhirPath)) gt 0">
                        <xsl:choose>
                            <xsl:when test="@nts:max = '*'">
                                <xsl:value-of select="concat(substring-after($fhirPath, concat($parentFhirPath, '.')), '.where({$_EXPR})')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="substring-after($fhirPath, concat($parentFhirPath, '.'))"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="not($parentFhirPath = $fhirPath) and contains($parentFhirPath, '{$_EXPR}')">
                        <xsl:variable name="escapeChars" select="replace($parentFhirPath, '([.()\\])', '\\$1')"/>
                        <xsl:variable name="regex" select="replace($escapeChars, '{$_EXPR}', '(.+)', 'q')"/>
                        <xsl:value-of select="replace($fhirPath, $regex, '$1')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$fhirPath"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="descriptionPrefix">
                <xsl:variable name="descriptionPath" select="@nts:descriptionPath"/>
                <xsl:value-of select="concat(substring-after($descriptionPath, $resourceType), ' ')"/>
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
                        <xsl:with-param name="expression" select="concat($expressionBase,substring-after($parentFhirPath, $resourceType),'.', $expression)"/>
                        <xsl:with-param name="label" select="concat($label, '-checkDateTime')"/>
                        <xsl:with-param name="warningOnly" select="true()"/>
                    </xsl:call-template>
                </xsl:when>
                <!--<xsl:when test="fn:count(ancestor::*[position()=last()]//*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]) gt 1 and preceding::*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))]">
                    <xsl:variable name="dateTime1" select="preceding::*[@nts:dataType = 'dateTime'][not(matches(@value, '\$\{DATE, T, (Y|M|D), ([-]?\d+)\}'))][last()]"/>
                    <xsl:variable name="durationAsString" select="xs:string(xs:date(./@value) - xs:date($dateTime1/@value))" />
                    
                    <xsl:variable name="expression">
                        <!-\- KT-393 -\->
                        <xsl:text>.where(</xsl:text>
                        <!-\-<xsl:text>exists(</xsl:text>-\->
                        <xsl:value-of select="$expressionPrefix"/>
                        <xsl:choose>
                            <xsl:when test="starts-with($durationAsString, '-')"> &lt; </xsl:when>
                            <xsl:otherwise> &gt; </xsl:otherwise>
                        </xsl:choose>
                        <xsl:value-of select="substring-after($dateTime1/@nts:fhirPath, concat($resourceType, '.'))"/>
                        <xsl:text>)</xsl:text>
                        <!-\- KT-393 -\->
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
                </xsl:when>-->
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
        
        <!-- This list of dataTypes is kind of arbitrary. I guess you can say that types like Reference or Quantity are somewhat compact (like max. 4 or 5 children?) that convey meaning _together_. The dataTypes below are more like bundles of elements that contain multiple individual pieces of information -->
        <xsl:variable name="containerTypes" select="('Address','BackboneElement','ContactPoint','HumanName')"/>
        
        <xsl:if test="$dataType = $containerTypes and count(*) gt 1 or ((f:extension or f:modifierExtension) and $skipExtensions = false())">
            <xsl:if test="@value">
                <xsl:variable name="expression">
                    <xsl:call-template name="createExpression">
                        <xsl:with-param name="focusFhirPath" select="$parentFhirPath"/>
                        <xsl:with-param name="valueOnly" select="true()"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="description">
                    <xsl:value-of select="substring-after(@nts:descriptionPath, $resourceType)"/>
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="createDescriptionSimple"/>
<xsl:value-of select="concat('. This assert checks only one child. Assert ', $label, ' checks if all children are present in the same parent')"/>
                </xsl:variable>
                <xsl:call-template name="createAssert">
                    <xsl:with-param name="description" select="concat('Contains ', $description)"/>
                    <xsl:with-param name="expression">
                        <xsl:choose>
                            <xsl:when test="contains($parentFhirPath, '{$_EXPR}')">
                                <xsl:value-of select="concat($expressionBase,substring-after(replace($parentFhirPath, '{$_EXPR}', normalize-space($expression), 'q'), $resourceType),'.exists()')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat($expressionBase,substring-after($parentFhirPath, $resourceType), '.', $expression)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                    <xsl:with-param name="label" select="concat($label,'-1')"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:if test="$skipExtensions = false() and ((not(@value) and count(f:*) gt 1) or @value and f:*)">
                <xsl:apply-templates select="f:extension|f:modifierExtension" mode="#current">
                    <xsl:with-param name="parentLabel" select="$label"/>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$dataType = $containerTypes">
                    <xsl:apply-templates select="*[not(self::f:extension) and not(self::f:modifierExtension)]" mode="#current">
                        <xsl:with-param name="parentLabel" select="$label"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$skipExtensions = true()"/>
                <xsl:when test="not(*[not(self::f:extension) and not(self::f:modifierExtension)])"/>
                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="#current">
                        <xsl:with-param name="parentLabel" select="$label"/>
                        <xsl:with-param name="skipExtensions" select="true()"/>
                    </xsl:apply-templates>
                </xsl:otherwise>
            </xsl:choose>
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
        <!-- Only top level asserts need a .exists() function -->
        <xsl:param name="topLevel" select="true()"/>
        <xsl:param name="focusFhirPath" required="yes"/>
        <xsl:param name="skipExtensions" select="false()"/>
        <xsl:param name="valueOnly" select="false()"/>
        
        <xsl:variable name="fhirPath" select="@nts:fhirPath"/>
        <xsl:variable name="dataType" select="@nts:dataType"/>
        <xsl:variable name="parentDataType" select="parent::f:*/@nts:dataType"/>
        
        <xsl:variable name="expressionPrefix">
            <xsl:choose>
                <xsl:when test="string-length(substring-after($fhirPath, $focusFhirPath)) gt 0">
                    <!--<xsl:choose>
                        <xsl:when test="@nts:max = '*'">
                            <xsl:value-of select="concat(substring-after($fhirPath, concat($focusFhirPath, '.')), '.where({$_EXPR})')"/>
                        </xsl:when>
                        <xsl:otherwise>-->
                            <xsl:value-of select="substring-after($fhirPath, concat($focusFhirPath, '.'))"/>
                        <!--</xsl:otherwise>
                    </xsl:choose>-->
                </xsl:when>
                <xsl:when test="not($focusFhirPath = $fhirPath) and contains($focusFhirPath, '{$_EXPR}')">
                    <xsl:variable name="escapeChars" select="replace($focusFhirPath, '([.()\\])', '\\$1')"/>
                    <xsl:variable name="regex" select="replace($escapeChars, '{$_EXPR}', '(.+)', 'q')"/>
                    <xsl:value-of select="replace($fhirPath, $regex, '$1')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$fhirPath"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="addition">
            <!-- We need to make a separation between element without children (simple data types) and with children (simple data types with extensions and complex data types). Expression for simple data types without children are ... simpler -->
            <xsl:choose>
                <xsl:when test="$dataType = 'id' or ($dataType = 'http://hl7.org/fhirpath/System.String' and self::f:id)">
                    <!-- An assert for Resource.id has been made earlier in the process because it is essential. So here we do nothing -->
                    <!-- For some reason, the official data type of .id in R4 is this System.String thing -->
                </xsl:when>
                <xsl:when test="(($skipExtensions = false() and f:*) or ($skipExtensions = true() and f:*[not(self::f:extension) and not(self::f:modifierExtension)])) and $valueOnly = false()">
                    <xsl:choose>
                        <!-- When simple data type (may or may not have @value) contains extension -->
                        <xsl:when test="$dataType = $simpleDataTypes and f:extension and $skipExtensions = false()">
                            <!-- Failing because of KT-393  -->
                            <!--<xsl:choose>
                                <xsl:when test="$topLevel = true()">
                                    <xsl:text>.exists(</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>-->
                            <xsl:if test="not(@nts:max = '*')">
                                <xsl:text>.where(</xsl:text>
                            </xsl:if>
                            <!--</xsl:otherwise>
                            </xsl:choose>-->
                            <xsl:if test="@value">
                                <xsl:call-template name="createExpressionSimple">
                                    <!--<xsl:with-param name="topLevel" select="false()"/>-->
                                    <xsl:with-param name="includeThis" select="true()"/>
                                </xsl:call-template>
                                <xsl:text> and </xsl:text>
                            </xsl:if>
                            <xsl:for-each select="*">
                                <xsl:call-template name="createExpression">
                                    <xsl:with-param name="topLevel" select="false()"/>
                                    <xsl:with-param name="focusFhirPath" select="parent::f:*/@nts:fhirPath"/>
                                </xsl:call-template>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:if test="not(@nts:max = '*')">
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                            <!-- Temp because of KT-393 -->
                            <!--<xsl:if test="$topLevel = true()">
                                <xsl:text>.exists()</xsl:text>
                            </xsl:if>-->
                        </xsl:when>
                        <xsl:when test="$dataType = 'Attachment'">
                            <xsl:if test="$skipExtensions = false()">
                                <xsl:call-template name="createExpressionExtension">
                                    <xsl:with-param name="fhirPath" select="$fhirPath"/>
                                </xsl:call-template>
                            </xsl:if>
                            <xsl:text>.where(</xsl:text>
                            <xsl:for-each select="*[self::f:contentType or self::f:language]">
                                <xsl:call-template name="createExpression">
                                    <xsl:with-param name="topLevel" select="false()"/>
                                    <xsl:with-param name="focusFhirPath" select="parent::f:*/@nts:fhirPath"/>
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
                                    <xsl:with-param name="topLevel" select="false()"/>
                                    <xsl:with-param name="focusFhirPath" select="parent::f:*/@nts:fhirPath"/>
                                </xsl:call-template>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:text>)</xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Identifier'">
                            <xsl:if test="f:extension">
                                <xsl:message select="concat('UNHANDLED EXTENSION EXPRESSION: ', $fhirPath, ' - ',$dataType)"/>
                            </xsl:if>
                            <xsl:if test="not(@nts:max = '*')">
                                <xsl:text>.where(</xsl:text>
                            </xsl:if>
                            <!-- KT-393 -->
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
                            <xsl:if test="not(@nts:max = '*')">
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                            <!-- KT-393 -->
                            <!--<xsl:text>.exists()</xsl:text>-->
                        </xsl:when>
                        <xsl:when test="$dataType = 'Reference'">
                            <xsl:if test="not(@nts:max = '*')">
                                <xsl:text>.where(</xsl:text>
                            </xsl:if>
                            <xsl:if test="$skipExtensions = false()">
                                <xsl:call-template name="createExpressionExtension">
                                    <xsl:with-param name="fhirPath" select="$fhirPath"/>
                                </xsl:call-template>
                                <xsl:if test="f:extension|f:modifierExtension"> and </xsl:if>
                            </xsl:if>
                            <!-- Check if (reference OR identifier) and display exist -->
                            <!-- KT-393 -->
                            <xsl:text>(reference</xsl:text>
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
                            <xsl:if test="not(@nts:max = '*')">
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                            <!--<xsl:text>.exists((reference or identifier) and display)</xsl:text>-->
                        </xsl:when>
                        <xsl:when test="$dataType = 'Narrative' and f:status/@value = 'extensions'">
                            <!-- Narrative isn't always present in fixtures. If not present, it is generated at a later stage. We should find a way to always add this assert. -->
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = ('Address','Annotation','BackboneElement','CodeableConcept','Coding','ContactPoint','Extension','HumanName','Meta','Period','Quantity')">
                            <!-- If there are multiple children, we need a where statement -->
                            <xsl:if test="count(f:*) gt 1 and not(@nts:max = '*')">
                                <xsl:text>where(</xsl:text>
                            </xsl:if>
                            <xsl:if test="$skipExtensions = false()">
                                <xsl:for-each select="f:extension|f:modifierExtension">
                                    <xsl:call-template name="createExpression">
                                        <xsl:with-param name="topLevel" select="false()"/>
                                        <xsl:with-param name="focusFhirPath" select="parent::f:*/@nts:fhirPath"/>
                                    </xsl:call-template>
                                    <xsl:if test="not(position() = last()) or (position() = last() and following-sibling::f:*)">
                                        <xsl:text> and </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:if>
                            <xsl:for-each select="*[not(self::f:extension) and not(self::f:modifierExtension)]">
                                <xsl:call-template name="createExpression">
                                    <xsl:with-param name="topLevel" select="false()"/>
                                    <xsl:with-param name="focusFhirPath" select="parent::f:*/@nts:fhirPath"/>
                                </xsl:call-template>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:if test="count(f:*) gt 1 and not(@nts:max = '*')">
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:message select="concat('TODO EXPRESSION: ', $fhirPath, ' - ',$dataType)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                   
                    <xsl:call-template name="createExpressionSimple">
                        <!--<xsl:with-param name="topLevel" select="$topLevel"/>-->
                        <xsl:with-param name="includeThis">
                            <xsl:choose>
                                <xsl:when test="@nts:max = '*'">
                                    <xsl:value-of select="true()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="false()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="expression">
            <xsl:choose>
                <xsl:when test="contains($expressionPrefix, '{$_EXPR}')">
                    <xsl:variable name="regex">
                        <xsl:choose>
                            <xsl:when test="starts-with($addition, ' ') or starts-with($addition, '.') and contains($expressionPrefix, '.{$_EXPR}')">
                                <xsl:value-of select="'.{$_EXPR}'"/>
                            </xsl:when>
                            <xsl:when test="starts-with($addition, '.where(') and contains($expressionPrefix, '.where({$_EXPR})')">
                                <xsl:value-of select="'.where({$_EXPR})'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'{$_EXPR}'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="addition">
                        <xsl:choose>
                            <xsl:when test="string-length(normalize-space($addition)) gt 0">
                                <xsl:value-of select="$addition"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="normalize-space($addition)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:value-of select="replace($expressionPrefix, $regex, $addition, 'q')"/>
                </xsl:when>
                <xsl:when test="matches($expressionPrefix, 'where\([^(]+(\))+$') and not(matches($expressionPrefix, 'modifierExtension.where\(url = [^(]+(\))+$'))">
                    <!-- Escape dollar signs ($this) -->
                    <xsl:variable name="regexAddition" select="replace($addition, '$', '\$', 'q')"/>
                    <xsl:value-of select="replace($expressionPrefix, '(\))+$', concat($regexAddition, '$1'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$expressionPrefix"/>
                    <!-- Add a dot if addition doesn't start with a space or dot -->
                    <xsl:if test="not(starts-with($addition, ' ')) and not(starts-with($addition, '.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                    <xsl:choose>
                        <!-- If addition contains something other then space, we assume spaces are important -->
                        <xsl:when test="string-length(normalize-space($addition)) gt 0">
                            <xsl:value-of select="$addition"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="normalize-space($addition)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!--<xsl:message>===</xsl:message>
        <xsl:message>
            <xsl:value-of select="$fhirPath"/>
        </xsl:message>
        <xsl:message>
            <xsl:value-of select="$focusFhirPath"/>
        </xsl:message>
        <xsl:message select="$expressionPrefix"/>
        <xsl:message select="$addition"/>
        <!-\-<xsl:message select="$skipExtensions"/>
        <xsl:message select="$valueOnly"/>-\->
        <xsl:message select="$expression"/>-->
        
        <xsl:if test="string-length($addition) gt 0">
            <xsl:value-of select="$expression"/>
            <xsl:if test="$topLevel = true() and not(matches($expression, ' (=|~) (true|false|''[^'']+'')$'))">
                <xsl:text>.exists()</xsl:text>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="createExpressionSimple">
        <xsl:param name="dataType" select="@nts:dataType"/>
        <xsl:param name="parentDataType" select="parent::f:*/@nts:dataType"/>
        <!-- If a call is topLevel, we need an 'exists()' statement. If a call isn't, the 'exists()' statement is constructed at a higher level, so we don't need it here.  -->
        <!--<xsl:param name="topLevel" select="true()"/>-->
        <!-- Whether to include '$this' at the start of expression -->
        <xsl:param name="includeThis" select="false()"/>
        
        <xsl:variable name="expression">
            <xsl:choose>
                <xsl:when test="$parentDataType = 'Attachment'">
                    <!-- In Attachment, there is hardly anything that we can reliably check for more than existance, so we do nothing here. -->
                    <xsl:text> </xsl:text>
                </xsl:when>
                <xsl:when test="$dataType = ('boolean', 'decimal')">
                    <xsl:if test="$includeThis = true()">
                        <xsl:text>$this</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="concat(' = ', @value)"/>
                </xsl:when>
                <xsl:when test="$dataType = 'string' and $parentDataType = ('Coding','Quantity')">
                    <!-- This is .display (in Coding) or .unit (in Quantity), and by definition not topLevel, so we do not have to do anything -->
                    <xsl:text> </xsl:text>
                    <!-- KT-393 R4 -->
                    <xsl:if test="$fhirVersion = 'R4'">
                        <xsl:text>.exists()</xsl:text>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$dataType = 'string'">
                    <!-- '~' (equivalence) ignores case and whitespace. replace('.', '') removes dot and comma (or other characters - hyphens perhaps?). Or should we be allowed to define overrides in our NTS-script? -->
                    <xsl:if test="$includeThis = true()">
                        <xsl:text>$this</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="concat('.replace(''.'', '''').replace('','', '''') ~ ''', normalize-space(translate(@value, '.,', '')), '''')"/>
                </xsl:when>
                <xsl:when test="$dataType = ('dateTime','date')">
                    <!-- For now we only check if date or dateTime exist -->
                    <xsl:text> </xsl:text>
                    <!-- KT-393 R4 -->
                    <!--<xsl:if test="$fhirVersion = 'R4'">
                        <xsl:text>.exists()</xsl:text>
                    </xsl:if>-->
                </xsl:when>
                <xsl:when test="$dataType = 'code' and $parentDataType = 'Quantity'">
                    <xsl:if test="$includeThis = true()">
                        <xsl:text>$this</xsl:text>
                    </xsl:if>
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
                <xsl:when test="$dataType = 'code' or ($dataType = ('canonical', 'uri') and $parentDataType = ('Coding', 'Meta', 'Quantity'))">
                    <!-- For uri's in Coding and Quantity (.system) or uri/canonical in Meta (.profile) we want an exact match. I can imagine that in some situations we want to only check for existance. -->
                    <xsl:if test="$includeThis = true()">
                        <xsl:text>$this</xsl:text>
                    </xsl:if>
                    <xsl:value-of select="concat(' = ''', @value, '''')"/>
                </xsl:when>
                <xsl:when test="$dataType = 'uri'">
                    <!-- For other uri's we assume there doesn't have to be an exact match. -->
                    <xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="concat('TODO SIMPLE EXPRESSION: ',local-name(), ' - ',$dataType)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!--<xsl:message>===</xsl:message>
        <xsl:message select="local-name()"/>
        <xsl:message>
            <xsl:value-of select="$dataType"/>
        </xsl:message>
        <xsl:message>
            <xsl:value-of select="$parentDataType"/>
        </xsl:message>
        <xsl:message select="$expression"/>-->
        
        <xsl:value-of select="$expression"/>
    </xsl:template>
    
    <xsl:template name="createExpressionExtension">
        <xsl:param name="fhirPath" required="yes"/>
        
        <xsl:if test="f:extension">
            <xsl:for-each select="f:extension">
                <xsl:call-template name="createExpression">
                    <xsl:with-param name="topLevel" select="false()"/>
                    <xsl:with-param name="focusFhirPath" select="parent::f:*/@nts:fhirPath"/>
                </xsl:call-template>
                <xsl:if test="not(position() = last())">
                    <xsl:text> and </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="createDescription">
        <xsl:param name="resourceType" tunnel="yes"/>
        <!-- If true, the resource type is the focus of the description -->
        <xsl:param name="resourceTypeFocus" select="false()"/>
        <xsl:param name="skipExtensions" select="false()"/>
        
        <xsl:variable name="parentDescriptionPath" select="parent::f:*/@nts:descriptionPath"/>
        <xsl:variable name="descriptionPath" select="@nts:descriptionPath"/>
        <xsl:variable name="parentDataType" select="parent::f:*/@nts:dataType"/>
        <xsl:variable name="dataType" select="@nts:dataType"/>
        
        <xsl:variable name="descriptionPrefix">
            <xsl:choose>
                <xsl:when test="$resourceTypeFocus = true()">
                    <xsl:value-of select="substring-after($descriptionPath, $resourceType)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring-after($descriptionPath, $parentDescriptionPath)"/>
                </xsl:otherwise>
                <!--<xsl:when test="string-length($parentDescriptionPath) gt 0">
                    <xsl:value-of select="substring-after($descriptionPath, $parentDescriptionPath)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="substring-after($descriptionPath, $resourceType)"/>
                </xsl:otherwise>-->
            </xsl:choose>
        </xsl:variable>
        
        <!-- Here for refactoring purposes -->
        <xsl:variable name="descriptionPrefix">
            <xsl:choose>
                <xsl:when test="matches($descriptionPrefix, '\(''[^''\(\)]*''\)$')">
                    <xsl:value-of select="replace($descriptionPrefix, '\(''[^''\(\)]*''\)$', '')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$descriptionPrefix"/>
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
                                <xsl:call-template name="createDescription"/>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> and </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Attachment'">
                            <xsl:if test="$skipExtensions = false()">
                                <xsl:call-template name="createDescriptionExtension"/>
                            </xsl:if>
                            <xsl:text>with </xsl:text>
                            <xsl:for-each select="*[self::f:contentType or self::f:language]">
                                <xsl:variable name="description">
                                    <xsl:call-template name="createDescription"/>
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
                                    <xsl:call-template name="createDescription"/>
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
                                <xsl:message select="concat('UNHANDLED EXTENSION DESCRIPTION: ', $descriptionPath, ' - ',$dataType)"/>
                            </xsl:if>
                            <xsl:text>with .</xsl:text>
                            <xsl:choose>
                                <xsl:when test="f:system">system</xsl:when>
                                <xsl:when test="f:type">type</xsl:when>
                            </xsl:choose>
                            <xsl:text> and .value</xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Reference'">
                            <xsl:if test="$skipExtensions = false()">
                                <xsl:call-template name="createDescriptionExtension"/>
                            </xsl:if>
                            <xsl:text>with either .reference or .identifier and .display</xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = 'Narrative' and f:status/@value = 'extensions'">
                            <!-- Nothing to add -->
                            <xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="$dataType = ('Address','Annotation','BackboneElement','CodeableConcept','Coding','ContactPoint','Extension','HumanName','Meta','Period','Quantity')">
                            <xsl:if test="$dataType = 'Extension'">
                                <xsl:value-of select="concat('with url ''', @url, ''' ')"/>
                            </xsl:if>
                            <xsl:text>with </xsl:text>
                            <xsl:if test="$skipExtensions = false()">
                                <xsl:for-each select="f:extension|f:modifierExtension">
                                    <xsl:variable name="description">
                                        <xsl:call-template name="createDescription"/>
                                    </xsl:variable>
                                    <xsl:if test="fn:string-length($description) gt 0">
                                        <xsl:value-of select="$description"/>
                                    </xsl:if>
                                    <xsl:if test="not(position() = last()) or (position() = last() and following-sibling::f:*)">
                                        <xsl:text> and </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:if>
                            <xsl:for-each select="*[not(self::f:extension) and not(self::f:modifierExtension)]">
                                <xsl:variable name="description">
                                    <xsl:call-template name="createDescription"/>
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
                            <xsl:message select="concat('TODO DESCRIPTION: ', $descriptionPath, ' - ',$dataType)"/>
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
            <xsl:when test="$dataType = ('dateTime','date') or ($dataType = 'string' and $parentDataType = ('Coding','Quantity'))">
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
        <xsl:if test="f:extension">
            <xsl:text>with </xsl:text>
            <xsl:for-each select="f:extension">
                <xsl:call-template name="createDescription"/>
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
        <xsl:param name="parentFhirPath"/>
        <xsl:param name="parentDescriptionPath"/>
        <xsl:param name="parentDataType"/>
        <xsl:param name="structureDefinition" tunnel="yes"/>
        
        <!-- We need to assume what would be the polymorphicElementPath if the element is indeed polymorphic -->
        <xsl:variable name="polymorphicElementPath" select="concat($parentElementPath, '.',  nf:get-element-base(local-name()), '[x]')"/>
        
        <!-- If datatype, overrule structureDefinition -->
        <xsl:variable name="structureDefinition">
            <xsl:choose>
                <xsl:when test="$parentDataType = $complexDataTypes">
                    <xsl:copy-of select="document(concat($libPath, lower-case($fhirVersion), '/', $parentDataType, '.xml'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$structureDefinition"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Determine this once and store in variable -->
        <xsl:variable name="isPolymorphic">
            <xsl:choose>
                <xsl:when test="$structureDefinition/f:StructureDefinition/f:snapshot/f:element/@id = $polymorphicElementPath or parent::f:extension or parent::f:modifierExtension">
                    <xsl:value-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="elementPath">
            <xsl:choose>
                <!-- Base resource -->
                <xsl:when test="string-length($parentElementPath) = 0">
                    <xsl:value-of select="local-name()"/>
                </xsl:when>
                <!-- Complex datatypes aren't included in snapshot, so we find them this way -->
                <xsl:when test="$parentDataType = $complexDataTypes">
                    <xsl:variable name="head">
                        <xsl:variable name="regexReplace">
                            <xsl:call-template name="substring-before-last">
                                <xsl:with-param name="input" select="concat($parentElementPath, '.', local-name())"/>
                                <xsl:with-param name="substr" select="'.'"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:value-of select="replace($regexReplace,'((\]|\[))','\\$1')"/>
                    </xsl:variable>
                    <xsl:value-of select="replace(concat($parentElementPath, '.', local-name()), $head, $parentDataType)"/>
                </xsl:when>
                <xsl:when test="self::f:extension or self::f:modifierExtension">Extension</xsl:when>
                <xsl:when test="$isPolymorphic = true()">
                    <xsl:value-of select="$polymorphicElementPath"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($parentElementPath, '.', local-name())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="polymorphicDataType" select="nf:datatype-case(substring-after(local-name(), nf:get-element-base(local-name())))"/>
        
        <xsl:variable name="elementDefinition">
            <xsl:choose>
                <xsl:when test="self::f:extension or self::f:modifierExtension or parent::f:extension or parent::f:modifierExtension">
                    <!-- We don't need one -->
                </xsl:when>
                <xsl:when test="$structureDefinition/f:StructureDefinition/f:snapshot/f:element/@id = $elementPath">
                    <xsl:copy-of select="$structureDefinition/f:StructureDefinition/f:snapshot/f:element[@id = $elementPath]"/>
                </xsl:when>
                <xsl:when test="$isPolymorphic = true()">
                    <xsl:copy-of select="$structureDefinition/f:StructureDefinition/f:snapshot/f:element[@id = $polymorphicElementPath]"/>
                </xsl:when>
                
                <xsl:otherwise>
                    <xsl:message>Could not find ElementDefinition <xsl:value-of select="$elementPath"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="dataType">
            <xsl:choose>
                <xsl:when test="self::f:extension or self::f:modifierExtension">Extension</xsl:when>
                <xsl:when test="parent::f:extension or parent::f:modifierExtension">
                    <xsl:value-of select="$polymorphicDataType"/>
                </xsl:when>
                <xsl:when test="$elementDefinition/f:element/f:type/f:code/@value">
                    <xsl:choose>
                        <xsl:when test="count(distinct-values($elementDefinition/f:element/f:type/f:code/@value)) gt 1">
                            <xsl:value-of select="distinct-values($elementDefinition/f:element/f:type/f:code/@value[lower-case(.) = lower-case($polymorphicDataType)])"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="distinct-values($elementDefinition/f:element/f:type/f:code/@value)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$structureDefinition/f:StructureDefinition[f:kind/@value = 'resource'][f:type/@value = $elementPath]">
                    <!-- Suppress message for base resource -->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>Could not find datatype <xsl:value-of select="$elementPath"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="max">
            <xsl:choose>
                <xsl:when test="$elementDefinition/f:element/f:max/@value">
                    <xsl:value-of select="$elementDefinition/f:element/f:max/@value"/>
                </xsl:when>
                <xsl:when test="self::f:extension or self::f:modifierExtension">
                    <xsl:variable name="url" select="@url"/>
                    <xsl:choose>
                        <xsl:when test="preceding-sibling::*[@url = $url] or following-sibling::*[@url = $url]">
                            <xsl:value-of select="'*'"/>
                        </xsl:when>
                        <xsl:otherwise>UNK</xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="parent::f:extension or parent::f:modifierExtension">1</xsl:when>
                <xsl:otherwise>
                    <xsl:message>Could not find max cardinality - <xsl:value-of select="$elementPath"/></xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="fhirPath">
            <xsl:choose>
                <xsl:when test="string-length($parentFhirPath) = 0">
                    <xsl:value-of select="local-name()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="addition">
                        <xsl:choose>
                            <xsl:when test="self::f:extension">
                                <xsl:value-of select="concat(local-name(), '(''', @url, ''')')"/>
                            </xsl:when>
                            <xsl:when test="self::f:modifierExtension">
                                <xsl:value-of select="concat(local-name(), '.where(url = ''', @url, ''')')"/>
                            </xsl:when>
                            <xsl:when test="$isPolymorphic = true() and not($dataType = 'Extension')">
                                <xsl:value-of select="concat(nf:get-element-base(local-name()), '.ofType(', $dataType, ')')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="local-name()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="$max = '*'">
                            <xsl:value-of select="'.where({$_EXPR})'"/>
                        </xsl:if>
                    </xsl:variable>
                    
                    <xsl:choose>
                        <xsl:when test="contains($parentFhirPath, '{$_EXPR}')">
                            <xsl:variable name="addition">
                                <xsl:choose>
                                    <xsl:when test="contains($addition, '{$_EXPR}')">
                                        <xsl:value-of select="$addition"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat($addition, '.{$_EXPR}')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:value-of select="replace($parentFhirPath, '{$_EXPR}', $addition, 'q')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat($parentFhirPath, '.', $addition)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="descriptionPath">
            <xsl:choose>
                <xsl:when test="string-length($parentDescriptionPath) = 0">
                    <xsl:value-of select="local-name()"/>
                </xsl:when>
                <!-- Leaving this here for refactoring purposes, should be improved -->
                <xsl:when test="self::f:extension or self::f:modifierExtension">
                    <xsl:value-of select="concat($parentDescriptionPath, '.', local-name(), '(''', @url, ''')')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($parentDescriptionPath, '.', local-name())"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$dataType = 'Identifier' and preceding-sibling::*[local-name() = fn:current()/local-name()]">
                <xsl:message>Double Identifier detected: <xsl:value-of select="$elementPath"/> - Please check if this is a specific use case or not. If yes, it should be added to generateAsserts</xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="nts:dataType" select="$dataType"/>
                    <xsl:attribute name="nts:max" select="$max"/>
                    <xsl:attribute name="nts:elementPath" select="$elementPath"/>
                    <xsl:attribute name="nts:fhirPath" select="$fhirPath"/>
                    <xsl:attribute name="nts:descriptionPath" select="$descriptionPath"/>
                    <xsl:apply-templates select="node()" mode="#current">
                        <xsl:with-param name="parentElementPath" select="$elementPath"/>
                        <xsl:with-param name="parentFhirPath" select="$fhirPath"/>
                        <xsl:with-param name="parentDescriptionPath" select="$descriptionPath"/>
                        <xsl:with-param name="parentDataType" select="$dataType"/>
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