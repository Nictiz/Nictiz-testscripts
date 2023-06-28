/*
 rule.summary=Create new Task fixture
 rule.description=Create a new Task fixture based on the retreived Task for later use in the TestScript. This is not an actual test, but a step needed for the TestScript infrastructure.
 rule.param.newStatus.required=true
 rule.param.fixtureId.required=true
 rule.param.responseId.required=false
*/

import groovy.xml.XmlUtil

def usedResponse = (param.responseId == null) ? response : responses.get(param.responseId)
def isJson = (usedResponse.body.bodyContentTypeEnum.toString() == 'json')

// Let's get our hands on the Task resource from the response. Since this Groovy rule is not trivial to write and
// maintain, we want to support both the read and the search use case with the same rule. The search use case assumes
// that there the response is a search Bundle containing exactly one Task resource.
def task = null
if (usedResponse.resource == "Task") {
    task = usedResponse.body.document
} else if (usedResponse.resource == "Bundle") {
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
}
assert task != null : "Couldn't extract Task resource from response."

// Now modify the Task status and write the result to the output. We also remove the narrative as there is no guarantee
// anymore that it still complies to the Task.
if (isJson) {
    task.status = param.newStatus
    if ("text" in task) {
        task.remove("text")
    }

    output[param.fixtureId] = JsonOutput.toJson(task)
} else {
    task.status.@value = param.newStatus
    if (task.text != null) {
        task.text.replaceNode {}
    }
    // The serializer in combination with the GPathResult (datatype of the XML Task) has the nasty habit of adding
    // "tag0" as the default namespace, so each FHIR element becomes "tag0:Task" etc. There are probably ways to solve
    // this in a decent way, but they are hard to find, so we just take a pragmatic approach and filter "tag0" from
    // the result.
    output[param.fixtureId] = XmlUtil.serialize(task).replace("tag0:", "").replace("xmlns:tag0", "xmlns")
}
