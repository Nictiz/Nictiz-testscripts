/*
 rule.summary=Modify the Task from a responseId with a different status
 rule.description=Modify the Task from a responseId with a different status
 rule.param.newStatus.required=true
*/

def bundle = response.body.document
def task = bundle.entry[0].resource
task.status = '${param.newStatus}'
// task.text = ''
// if (response.body.bodyContentTypeEnum == 'json') {
    output['taskModified'] = JsonOutput.toJson(task)
// }