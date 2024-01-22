/*
 rule.summary=Pre-check for profile validation
 rule.description=This check can be ignored. It is meant to produce the output for the next step.
*/

// This rule performs profile validation on the response, but doesn't result in an actual check. Instead, the output is
// captured and exported as two text variables: "validationErrors" and "validationWarnings". This way, the output can
// be filtered in a future step.
// NOTE 1: The filtering could be done here, but this results in a timeout on Touchstone.
// NOTE 2: In the TestScript, the output's should be defined as "document", otherwise the output is shown verbatim on
//         the Touchstone interface.
// NOTE 3: Yes, this is a hack, needed to suppress false error messages by the Touchstone validator. I hope it's
//         temporary until the actual bug on Touchstone is resolved.
try {
    response.assertValidWithProfileId("Bundle-profile");
} catch (Throwable e) {
    output["validationErrors"] = e.getMessage();
    output["validationWarnings"] = e.warningMessage;
}