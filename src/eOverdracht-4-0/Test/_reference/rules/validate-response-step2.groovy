/*
 rule.summary=Perform profile validation
 rule.description=Perform profile validation (description)
 rule.param.validationOutput.required=true
*/

def output = param['validationOutput']
def pattern = ~/(ERROR|WARNING): /
def matcher = pattern.matcher(output)

class Issue {
    String kind
    String message
}
def issues = []

def kind
def prev_end = -1
while (matcher.find()) {
    if (prev_end != -1) {
        issues.push(new Issue(kind: kind, message: output.substring(prev_end, matcher.start() - 2)))
    }
    prev_end = matcher.end()
    kind = matcher.group(1)
}
issues.push(new Issue(kind: kind, message: output.substring(prev_end, output.length() - 2)))

issues.each {
    if (!(it.message ==~ /.*Slicing cannot be evaluated: Error in discriminator at .* no children, no type.*/)) {
        try {
            if (it.kind == "ERROR") {
                fail("ERROR: " + it.message)
            } else if (it.kind == "WARNING") {
                warn("WARNING: " + it.message)
            }
        } catch (Throwable e) {
            errorsAndWarnings.registerAndContinue(e);
        }
    }
}
