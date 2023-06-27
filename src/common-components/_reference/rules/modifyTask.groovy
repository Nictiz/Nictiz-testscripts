/*
 rule.summary=Modify the Task from a responseId with a different status
 rule.description=Modify the Task from a responseId with a different status
 rule.param.newStatus.required=true
 rule.param.fixtureId.required=true
*/

import groovy.xml.XmlUtil

def isJson = (response.body.bodyContentTypeEnum.toString() == 'json')

// Let's get our hands on the Task resource from the response. Since this Groovy rule is not trivial to write and
// maintain, we want to support both the read and the search use case with the same rule. The search use case assumes
// that there the response is a search Bundle containing exactly one Task resource.

def task = null
if (response.resource == "Task") {
    task = response.body
} else if (response.resource == "Bundle") {
    assert response.getFhirPathBoolean("Bundle.entry.where(resource is Task).count() = 1"): "Server didn't return a Bundle with a single Task."

    if (isJson) {
        for (entry in response.body.document.entry) {
            if (entry.resource.resourceType == "Task") {
                task = entry.resource
            }
        }
    } else {
        task = response.body.document.entry.'**'.find { it.name() == "Task" }
    }
}
assert task != null : "Couldn't extract Task resource from response."

if (isJson) {
    task.status = '${param.newStatus}'
    if ("text" in task) {
        task.remove("text")
    }

    output['${param.fixtureId}'] = JsonOutput.toJson(task)
} else {
    task.status.@value = '${param.newStatus}'
    if (task.text != null) {
        task.text.replaceNode {}
    }
    output['${param.fixtureId}'] = XmlUtil.serialize(task)
}
