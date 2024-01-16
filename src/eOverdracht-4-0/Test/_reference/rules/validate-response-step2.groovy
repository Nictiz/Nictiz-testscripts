/*
 rule.summary=Perform profile validation
 rule.description=Perform profile validation (description)
*/

def output = ruleOutputs.get('validationErrors').getBody().body
def pattern = ~/ERROR: /
def matcher = pattern.matcher(output)

def issues = []

def prev_end = -1
while (matcher.find()) {
    if (prev_end != -1) {
        issues.push("ERROR: " + output.substring(prev_end, matcher.start() - 2))
    }
    prev_end = matcher.end()
}
issues.push("ERROR: " + output.substring(prev_end, output.length() - 2))

def filtered = issues.findAll { (!(it ==~ /.*ERROR: Slicing cannot be evaluated: Error in discriminator at .* no children, no type.*/)) }
def e = new net.aegis.touchstone.data.model.testexecution.AssertionErrorAndWarning("Result:[" + String.join(", ", issues) + "]",
    ruleOutputs.get('validationWarnings').getBody().body)
throw e