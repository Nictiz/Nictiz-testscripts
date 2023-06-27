/*
 rule.summary=Modify the Task from a responseId with a different status
 rule.description=Modify the Task from a responseId with a different status
 rule.param.newStatus.required=true
 rule.param.fixtureId.required=true
*/

import groovy.xml.XmlUtil

assert response.resource == "Bundle": "Server didn't return a Bundle with a single Task."
assert response.getFhirPathBoolean("Bundle.entry.where(resource is Task).count() = 1"): "Server didn't return a Bundle with a single Task."

def isJson = (response.body.bodyContentTypeEnum.toString() == 'json')

logger.info(response.body.bodyContentTypeEnum.toString())

def task = null
if (isJson) {
    for (entry in response.body.document.entry) {
        if (entry.resource.resourceType == "Task") {
            task = entry.resource
        }
    }
} else {
    task = response.body.document.entry.'**'.find { it.name() == "Task" }
}

assert task != null : "Couldn't extract Task resource from response."

if (isJson) {
    task.status = '${param.newStatus}'
    output['${param.fixtureId}'] = JsonOutput.toJson(task)
} else {
    task.status.@value = '${param.newStatus}'
    output['${param.fixtureId}'] = XmlUtil.serialize(task)
}

// task.text = ''
// if (response.body.bodyContentTypeEnum == 'json') {
    
// }