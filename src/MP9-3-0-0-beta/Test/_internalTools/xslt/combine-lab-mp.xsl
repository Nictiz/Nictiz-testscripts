<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" xmlns:nf="http://www.nictiz.nl/functions" xmlns:f="http://hl7.org/fhir" xmlns:nts="http://nictiz.nl/xsl/testscript" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:util="urn:hl7:utilities" version="2.0" xmlns="" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema">
    
    <xsl:output indent="yes"/>
    
    <xsl:param name="nhgFixture" select="document('../../../../../../HL7-mappings/ada_2_fhir-r4/lab/3.0.0/sturen_laboratoriumresultaten/fhir_instance/lr-slr-TEST-KC-NHG-Nierfunctie-Scenario1-1.xml')"/>
    <xsl:param name="nhgId" select="'mv-mp-vo-tst-4-2-a-nierfunctie-NHG-v30'"/>
    
    <xsl:param name="loincFixture" select="document('../../../../../../HL7-mappings/ada_2_fhir-r4/lab/3.0.0/sturen_laboratoriumresultaten/fhir_instance/lr-slr-TEST-KC-LOINC-Nierfunctie-Scenario3-3.xml')"/>
    <xsl:param name="loincId" select="'mv-mp-vo-tst-4-2-b-nierfunctie-loinc-zonder-panel-v30'"/>
    
    <xsl:template match="f:Bundle">
        <xsl:copy>
            <xsl:variable name="patientFullUrl" select="f:entry[f:resource/f:Patient]/f:fullUrl/@value"/>
            <xsl:variable name="bundleId" select="f:id/@value"/>
            <xsl:apply-templates select="f:*[not(self::f:entry)]"/>
            <xsl:apply-templates select="f:entry[f:resource/f:MedicationRequest]"/>
            <xsl:choose>
                <xsl:when test="$bundleId = $nhgId">
                    <xsl:apply-templates select="$nhgFixture/f:Bundle/f:entry[f:resource[f:Observation|f:Specimen]]" mode="editPatient">
                        <xsl:with-param name="patientFullUrl" select="$patientFullUrl" tunnel="yes"/>
                        <xsl:with-param name="performerFullUrl" select="$nhgFixture/f:Bundle/f:entry[f:resource/f:Organization/f:identifier[f:system/@value = 'http://fhir.nl/fhir/NamingSystem/ura']/f:value/@value = '00003333']/f:fullUrl/@value" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$bundleId = $loincId">
                    <xsl:apply-templates select="$loincFixture/f:Bundle/f:entry[f:resource[f:Observation|f:Specimen]]" mode="editPatient">
                        <xsl:with-param name="patientFullUrl" select="$patientFullUrl" tunnel="yes"/>
                        <xsl:with-param name="performerFullUrl" select="$loincFixture/f:Bundle/f:entry[f:resource/f:Organization/f:identifier[f:system/@value = 'http://fhir.nl/fhir/NamingSystem/ura']/f:value/@value = '00003333']/f:fullUrl/@value" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Unexpected situation</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="f:entry[f:resource[f:Patient|f:PractitionerRole|f:Practitioner|f:Organization]]"/>
            <!-- Laboratorium 't Proefje -->
            <xsl:choose>
                <xsl:when test="$bundleId = $nhgId">
                    <xsl:apply-templates select="$nhgFixture/f:Bundle/f:entry[f:resource/f:Organization/f:identifier[f:system/@value = 'http://fhir.nl/fhir/NamingSystem/ura']/f:value/@value = '00003333']"/>
                </xsl:when>
                <xsl:when test="$bundleId = $loincId">
                    <xsl:apply-templates select="$loincFixture/f:Bundle/f:entry[f:resource/f:Organization/f:identifier[f:system/@value = 'http://fhir.nl/fhir/NamingSystem/ura']/f:value/@value = '00003333']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="yes">Unexpected situation</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="f:entry[f:resource/f:Medication]"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="f:subject[f:type/@value = 'Patient']/f:reference/@value" mode="editPatient">
        <xsl:param name="patientFullUrl" tunnel="yes"/>
        <xsl:attribute name="value" select="$patientFullUrl"/>
    </xsl:template>
    
    <xsl:template match="f:performer[f:type/@value = 'Organization']/f:reference/@value" mode="editPatient">
        <xsl:param name="performerFullUrl" tunnel="yes"/>
        <xsl:attribute name="value" select="$performerFullUrl"/>
    </xsl:template>
    
</xsl:stylesheet>
