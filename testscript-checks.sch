<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2" xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    <sch:ns uri="http://hl7.org/fhir" prefix="f"/>
    <sch:pattern>
        <!-- Directory of the TestScript file we are checking. Assume any fixtures exist relative to this directory -->
        <sch:let name="workingdir" value="string-join(tokenize(document-uri(.), '/')[position() != last()], '/')"/>
        <!-- File name -->
        <sch:let name="filename" value="tokenize(document-uri(.), '/')[last()]"/>
        <!-- Base filename -->
        <sch:let name="basefilename" value="string-join(tokenize($filename, '\.')[position() != last()], '.')"/>
        <!-- Extension of filename -->
        <sch:let name="filenameext" value="tokenize($filename, '/')[last()]"/>
        <!-- Label to aid in mass checking -->
        <sch:let name="label" value="document-uri(.)"/>
        
        <sch:rule context="f:TestScript">
            <sch:assert test="f:id"
                ><sch:value-of select="$label"/>: TestScript id shall be present</sch:assert>
            <sch:assert test="f:url"
                ><sch:value-of select="$label"/>: TestScript url shall be present</sch:assert>
            <sch:assert test="f:status"
                ><sch:value-of select="$label"/>: TestScript status shall be present</sch:assert>
            <sch:assert test="f:date"
                ><sch:value-of select="$label"/>: TestScript date shall be present</sch:assert>
            <sch:assert test="f:publisher"
                ><sch:value-of select="$label"/>: TestScript publisher shall be present.</sch:assert>
            <sch:assert test="f:contact"
                ><sch:value-of select="$label"/>: TestScript contact shall be present.</sch:assert>
            <sch:assert test="f:description"
                ><sch:value-of select="$label"/>: TestScript description shall be present.</sch:assert>
            <sch:assert test="f:copyright"
                ><sch:value-of select="$label"/>: TestScript copyright shall be present.</sch:assert>
        </sch:rule>
        
        <sch:rule context="f:TestScript/f:id">
            <sch:assert test="@value = $basefilename" role="warning"
                ><sch:value-of select="$label"/>: TestScript id "<sch:value-of select="@value"/>" should match base file name of the test script "<sch:value-of select="$basefilename"/>"</sch:assert>
        </sch:rule>
        
        <sch:rule context="f:TestScript/f:url">
            <sch:assert test="ends-with(@value, $basefilename)" role="warning"
                ><sch:value-of select="$label"/>: TestScript url "<sch:value-of select="@value"/>" should end with base file name of the test script "<sch:value-of select="$basefilename"/>"</sch:assert>
        </sch:rule>
        
        <sch:rule context="f:TestScript/f:status">
            <sch:assert test="@value = ('draft', 'active')" role="warning"
                ><sch:value-of select="$label"/>: TestScript status "<sch:value-of select="@value"/>" should be draft or active</sch:assert>
        </sch:rule>
        
        <sch:rule context="f:TestScript/f:publisher">
            <sch:assert test="@value = 'Nictiz'" role="warning"
                ><sch:value-of select="$label"/>: TestScript publisher "<sch:value-of select="@value"/>" should be Nictiz.</sch:assert>
        </sch:rule>
        
        <sch:rule context="f:TestScript/f:contact">
            <sch:assert test="f:name[@value = 'Nictiz']" role="warning"
                ><sch:value-of select="$label"/>: TestScript contact name "<sch:value-of select="f:name/@value"/>" should be 'Nictiz'.</sch:assert>
            <sch:assert test="f:telecom[f:system/@value = 'email'][f:value/@value = 'kwalificatie@nictiz.nl'][f:use/@value = 'work']" role="warning"
                ><sch:value-of select="$label"/>: TestScript contact telecom should be system 'email', value 'kwalificatie@nictiz.nl', use 'work'.</sch:assert>
        </sch:rule>
        
        <sch:rule context="f:TestScript/f:copyright">
            <sch:assert test="matches(@value, '^© Nictiz')" role="warning"
                ><sch:value-of select="$label"/>: TestScript copyright "<sch:value-of select="@value"/>" should start with '© Nictiz' potentially followed by a year.</sch:assert>
        </sch:rule>
        
        <sch:rule context="f:fixture/f:resource/f:reference">
            <sch:report test="matches(@value, '^/|([A-Za-z]*:)')"
                ><sch:value-of select="$label"/>: Fixture id "<sch:value-of select="../../@id"/>", reference should not point to an absolute path "<sch:value-of select="@value"/>"</sch:report>
            
            <!-- Check if reference is an absolute path (handled above), is available as unparsed text (json/txt/...) or available as xml -->
            <sch:assert test="matches(@value, '^[A-Za-z]*:') ||
                              unparsed-text-available(concat($workingdir, '/', @value)) || 
                              doc-available(concat($workingdir, '/', @value))"
                ><sch:value-of select="$label"/>: Fixture id "<sch:value-of select="../../@id"/>", reference points to unavailable file "<sch:value-of select="@value"/>"</sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>