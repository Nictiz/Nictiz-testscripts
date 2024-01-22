/*
 rule.summary=Perform profile validation
 rule.description=Perform profile validation
*/

// This rule is used to filter the error messages from profile validation on the false error that "Slicing cannot
// be evaluated" in the Composition profiles. See https://bits.nictiz.nl/browse/TOUCH-320 for more information.
// It uses the variables "validationErrors" and "validationWarnings" that are produced by a previous step and filters
// out this error message.

// Split the string of error messages in individual error messages
def output = ruleOutputs.get('validationErrors').getBody().body
def pattern = ~/ERROR: /
def matcher = pattern.matcher(output)
def issues = []
def prefix
def prev_end = -1
while (matcher.find()) {
    if (prev_end == -1) {
        prefix = output.substring(0, matcher.start())
    } else {
        issues.push("ERROR: " + output.substring(prev_end, matcher.start() - 2))
    }
    prev_end = matcher.end()
}
issues.push("ERROR: " + output.substring(prev_end, output.length() - 2))

// Filter the error messages so that the incorrect messages are excluded
def filtered = issues.findAll { (!(it ==~ /.*ERROR: Slicing cannot be evaluated: Error in discriminator at .* no children, no type.*/)) }

// Re-create the output as an AssertionErrorAndWarning object
def e = new net.aegis.touchstone.data.model.testexecution.AssertionErrorAndWarning(prefix + String.join(", ", issues) + "]",
    ruleOutputs.get('validationWarnings').getBody().body)
throw e