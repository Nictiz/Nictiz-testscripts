/*
 rule.summary=Create new Task fixture
 rule.description=Create a new Task fixture based on the retreived Task for later use in the TestScript. This is not an actual test, but a step needed for the TestScript infrastructure.
 rule.param.varName.required=true
 rule.param.responseId.required=false
 rule.param.qrReference.required=true
 rule.param.qrDisplay.required=true
*/

// This is a bespoke version of the rewrite-response-taskStatus.groovy rule that adds the QuestionnaireResponse
// reference as output to the Task, in accordance with the QuestionnaireProvisioningTask profile.

import groovy.xml.XmlUtil

def usedResponse = (param.responseId == null) ? response : responses.get(param.responseId)
def isJson = (usedResponse.body.bodyContentTypeEnum.toString() == 'json')

// Let's get our hands on the Task resource from the response. Since this Groovy rule is not trivial to write and
// maintain, we want to support both the read and the search use case with the same rule. The search use case assumes
// that there the response is a search Bundle containing exactly one Task resource.
def task = null
assert usedResponse.getFhirPathBoolean("Bundle.entry.where(resource is Task).count() = 1"): "Server didn't return a Bundle with a single Task."

if (isJson) {
    for (entry in usedResponse.body.document.entry) {
        if (entry.resource.resourceType == "Task") {
            task = entry.resource
        }
    }
} else {
    task = usedResponse.body.document.entry.'**'.find { it.name() == "Task" }
}
assert task != null : "Couldn't extract Task resource from response."

// Now modify the Task status and write the result to the output. We also remove the narrative as there is no guarantee
// anymore that it still complies to the Task.
if (isJson) {
    task.status = "completed"
    if ("text" in task) {
        task.remove("text")
    }

    output[param.varName] = JsonOutput.toJson(task)
} else {
    task.status.@value = "completed"
    if (task.text != null) {
        task.text.replaceNode {}
    }
    task.appendNode {
        output {
            type {
                text(value: "QuestionnaireResponse")
            }
            valueReference {
                reference(value: param.qrReference)
                display(value: param.qrDisplay)
            }
        }
    }
    
    // The serializer in combination with the GPathResult (datatype of the XML Task) has the nasty habit of adding
    // "tag0" as the default namespace, so each FHIR element becomes "tag0:Task" etc. There are probably ways to solve
    // this in a decent way, but they are hard to find, so we just take a pragmatic approach and filter "tag0" from
    // the result.
    def xml = XmlUtil.serialize(task)
    xml = xml.replace("tag0:", "")
    xml = xml.replace("xmlns:tag0", "xmlns")
    xml = xml.replaceAll("<\\?xml .*?>", "")
    xml = xml.replaceAll("\\sxmlns.*?>", ">")
    output[param.varName] = xml
}
