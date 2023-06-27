/*
 rule.summary=Modify the Task from a responseId with a different status
 rule.description=Modify the Task from a responseId with a different status
 rule.param.newStatus.required=true
 rule.param.fixtureId.required=true
*/

assert response.resource == "Bundle": "Server didn't return a Bundle with a single Task."
def bundle = response.body.document

assert response.getFhirPathBoolean("Bundle.entry.where(resource is Task).count() = 1"): "Server didn't return a Bundle with a single Task."
def task = null
for (entry in bundle.entry) {
    if (entry.resource.resourceType == "Task") {
        task = entry.resource
    }
}

task.status = '${param.newStatus}'
// task.text = ''
// if (response.body.bodyContentTypeEnum == 'json') {
    output['${param.fixtureId}'] = JsonOutput.toJson(task)
// }