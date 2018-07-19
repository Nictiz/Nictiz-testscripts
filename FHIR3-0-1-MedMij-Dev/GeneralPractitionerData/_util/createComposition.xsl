<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:f="http://hl7.org/fhir"
    exclude-result-prefixes="#all"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jul 19, 2018</xd:p>
            <xd:p><xd:b>Author:</xd:b> ahenket</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:param name="inputDir1">../_reference/resources-query-send</xsl:param>
    <xsl:param name="inputDir2">../_reference/resources-generic</xsl:param>
    
    <xsl:variable name="ipDir1">
        <xsl:choose>
            <xsl:when test="ends-with($inputDir1, '/')"><xsl:value-of select="$inputDir1"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($inputDir1,'/')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="ipDir2">
        <xsl:choose>
            <xsl:when test="ends-with($inputDir2, '/')"><xsl:value-of select="$inputDir2"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="concat($inputDir2,'/')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="uriICPCNL1">http://hl7.org/fhir/sid/icpc-1-nl</xsl:variable>
    <xsl:variable name="uriJournaalRegelTypen">http://fhir.nl/fhir/NamingSystem/journaalregeltypen</xsl:variable>
    <xsl:variable name="uriExtensionEpisodeOfCareTitle">http://nictiz.nl/fhir/StructureDefinition/EpisodeOfCare-Title</xsl:variable>
    <xsl:variable name="profileDiagnosticResult">http://nictiz.nl/fhir/StructureDefinition/gp-DiagnosticResult</xsl:variable>
    <xsl:variable name="profileLaboratoryResult">http://nictiz.nl/fhir/StructureDefinition/gp-LaboratoryResult</xsl:variable>
    <xd:doc>
        <xd:desc/>
    </xd:doc>
    <xsl:template match="/">
        <xsl:variable name="xml" select="collection(iri-to-uri(concat(resolve-uri($inputDir1),'?select=', '*.xml;recurse=no'))) | collection(iri-to-uri(concat(resolve-uri($inputDir2),'?select=', '*.xml;recurse=no')))"/>
        
        <xsl:variable name="encounterResource" as="element(f:Encounter)*" select="$xml/f:Encounter"/>
        
        <xsl:for-each select="$encounterResource">
            <xsl:sort select="f:id/@value"/>
            <xsl:variable name="encounter" select="." as="element(f:Encounter)"/>
            <xsl:variable name="encounterId" select="f:id/@value" as="xs:string"/>
            
            <xsl:variable name="compositionFilename" select="concat($ipDir1,'medmij-gpdata-fhir3-0-1-composition-', $encounterId, '.xml')"/>
            
            <xsl:variable name="patientResource" as="element(f:Patient)" select="$xml/f:Patient"/>
            <xsl:variable name="practitionerResource" as="element(f:Practitioner)" select="$xml/f:Practitioner"/>
            <xsl:variable name="practitionerRoleResource" as="element(f:PractitionerRole)" select="$xml/f:PractitionerRole"/>
            <xsl:variable name="episodeOfCare" as="element(f:EpisodeOfCare)*" select="$xml/f:EpisodeOfCare[f:id/@value = $encounter/f:episodeOfCare/f:reference/tokenize(@value, '/')[last()]]"/>
            <xsl:variable name="journalS" as="element(f:Observation)*" select="$xml/f:Observation[f:context/f:reference/@value = concat('Encounter/',$encounterId)][f:code/f:coding[f:system/@value = $uriJournaalRegelTypen][f:code/@value = 'S']]"/>
            <xsl:variable name="journalO" as="element(f:Observation)*" select="$xml/f:Observation[f:context/f:reference/@value = concat('Encounter/',$encounterId)][f:code/f:coding[f:system/@value = $uriJournaalRegelTypen][f:code/@value = 'O']]"/>
            <xsl:variable name="journalE" as="element(f:Observation)*" select="$xml/f:Observation[f:context/f:reference/@value = concat('Encounter/',$encounterId)][f:code/f:coding[f:system/@value = $uriJournaalRegelTypen][f:code/@value = 'E']]"/>
            <xsl:variable name="journalP" as="element(f:Observation)*" select="$xml/f:Observation[f:context/f:reference/@value = concat('Encounter/',$encounterId)][f:code/f:coding[f:system/@value = $uriJournaalRegelTypen][f:code/@value = 'P']]"/>
            <xsl:variable name="diagnosticResult" as="element(f:Observation)*" select="$xml/f:Observation[f:context/f:reference/@value = concat('Encounter/',$encounterId)][f:meta/f:profile/@value = $profileDiagnosticResult]"/>
            <xsl:variable name="labResult" as="element(f:Observation)*" select="$xml/f:Observation[f:context/f:reference/@value = concat('Encounter/',$encounterId)][f:meta/f:profile/@value = $profileLaboratoryResult]"/>
            <xsl:variable name="prescription" as="element(f:MedicationRequest)*" select="$xml/f:MedicationRequest[f:context/f:reference/@value = concat('Encounter/',$encounterId)]"/>
            
            <xsl:variable name="encounterDate" select="f:period/f:start/@value" as="xs:string"/>
            <xsl:variable name="patientName" select="string-join(($patientResource/f:name[1]/f:given[1]/@value, $patientResource/f:name/f:family[1]/@value), ' ')"/>
            <xsl:variable name="practitionerName" select="string-join(($practitionerResource/f:name[1]/f:given[1]/@value, $practitionerResource/f:name/f:family[1]/@value), ' ')"/>
            
            <xsl:result-document href="{$compositionFilename}" indent="yes" method="xml" omit-xml-declaration="yes">
                <xsl:processing-instruction name="xml-model">href="http://hl7.org/fhir/STU3/composition.sch" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
                <xsl:text>&#10;</xsl:text>
                <Composition xmlns="http://hl7.org/fhir" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hl7.org/fhir http://hl7.org/fhir/STU3/fhir-all.xsd">
                    <id value="gp-EncounterReport-{$encounterId}"/>
                    <meta>
                        <lastUpdated value="{current-dateTime()}"/>
                        <profile value="http://nictiz.nl/fhir/StructureDefinition/gp-EncounterReport"/>
                    </meta>
                    <text>
                        <status value="generated"/>
                        <div xmlns="http://www.w3.org/1999/xhtml">
                            <p>
                                <xsl:text>Contactverslag dd. </xsl:text>
                                <xsl:value-of select="$encounterDate"/>
                                <xsl:text> met patiënt </xsl:text>
                                <xsl:value-of select="$patientName"/>
                                <xsl:text> door huisarts </xsl:text>
                                <xsl:value-of select="$practitionerName"/>
                                <xsl:if test="$episodeOfCare">
                                    <xsl:text> in relatie tot episode </xsl:text>
                                    <xsl:value-of select="$episodeOfCare/f:extension[@url = $uriExtensionEpisodeOfCareTitle]/f:valueString/@value"/>
                                </xsl:if>
                            </p>
                            <table cellpadding="10">
                                <thead>
                                    <tr>
                                        <th>SOEP</th>
                                        <th>Text</th>
                                        <th>ICPC</th>
                                    </tr>
                                </thead>
                                <xsl:for-each select="$journalS, $journalO, $journalE, $journalP">
                                    <xsl:variable name="icpc" select="f:component[f:code/f:coding[f:code/@value = ('ADMDX', 'DISDX')]]/f:valueCodeableConcept/f:coding[f:system/@value = $uriICPCNL1]"/>
                                    <tr>
                                        <td>
                                            <xsl:value-of select="f:code/f:coding/f:code/@value"/>
                                        </td>
                                        <td>
                                            <xsl:value-of select="f:valueString/@value"/>
                                        </td>
                                        <td>
                                            <xsl:if test="$icpc">
                                                <span title="{$icpc/f:display/@value}">
                                                    <xsl:value-of select="$icpc/f:code/@value"/>
                                                </span>
                                            </xsl:if>
                                        </td>
                                    </tr>
                                </xsl:for-each>
                            </table>
                        </div>
                    </text>
                    <status value="final"/>
                    <type>
                        <coding>
                            <system value="http://loinc.org"/>
                            <code value="67781-5"/>
                            <display value="Summarization of encounter note Narrative"/>
                        </coding>
                    </type>
                    <subject>
                        <xsl:copy-of select="$practitionerRoleResource/f:subject/*"/>
                    </subject>
                    <encounter>
                        <reference value="Encounter/{$encounterId}"/>
                    </encounter>
                    <date value="{$encounterDate}"/>
                    <author>
                        <xsl:copy-of select="$practitionerRoleResource/f:practitioner/*"/>
                    </author>
                    <title value="Contactverslag dd. {$encounterDate}"/>
                    <xsl:for-each select="$journalS, $journalO, $journalE, $journalP">
                        <section>
                            <xsl:if test="f:component[f:code/f:coding[f:code/@value = ('ADMDX', 'DISDX')]]">
                                <extension url="http://nictiz.nl/fhir/StructureDefinition/code-icpc-1-nl">
                                    <xsl:copy-of select="f:component[f:code/f:coding[f:code/@value = ('ADMDX', 'DISDX')]]/f:valueCodeableConcept"/>
                                </extension>
                            </xsl:if>
                            <xsl:copy-of select="f:code"/>
                            <text>
                                <status value="additional"/>
                                <div xmlns="http://www.w3.org/1999/xhtml"><xsl:value-of select="f:valueString/@value"/></div>
                            </text>
                            <entry>
                                <reference value="{local-name()}/{f:id/@value}"/>
                            </entry>
                            <xsl:for-each select="$episodeOfCare">
                                <entry>
                                    <reference value="EpisodeOfCare/{f:id/@value}"/>
                                </entry>
                            </xsl:for-each>
                        </section>
                    </xsl:for-each>
                </Composition>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>