/*
 rule.summary=Create new Task fixture
 rule.description=Create a new Task fixture based on the retreived Task for later use in the TestScript. This is not an actual test, but a step needed for the TestScript infrastructure.
 rule.param.fixtureId.required=true
 rule.param.newDate.required=true
 rule.param.responseId.required=false
*/

// This is a bespoke version of the general rewrite-response-taskStatus.groovy rule to create a fixture to propose an
// alternative transfer date.

import groovy.xml.XmlUtil

def usedResponse = (param.responseId == null) ? response : responses.get(param.responseId)
def isJson = (usedResponse.body.bodyContentTypeEnum.toString() == 'json')

// Let's get our hands on the Task resource from the response. Since this Groovy rule is not trivial to write and
// maintain, we want to support both the read and the search use case with the same rule. The search use case assumes
// that there the response is a search Bundle containing exactly one Task resource.
def task = null
task = usedResponse.body.document
assert task != null : "Couldn't extract Task resource from response."

// Now modify the Task status and write the result to the output. We also remove the narrative as there is no guarantee
// anymore that it still complies to the Task.
if (isJson) {
    task.status = "on-hold"
    if ("text" in task) {
        task.remove("text")
    }
    def alternativeDate = [
        type: [
            coding: [
                [
                    system: 'http://snomed.info/sct',
                    code: '146851000146105'
                ]
            ]
        ],
        valueDateTime: param.newDate
    ]
    if (!("output" in task)) {
        task.output = []
    }
    task.output.add(alternativeDate)

    output[param.fixtureId] = JsonOutput.toJson(task)
} else {
    task.status.@value = "on-hold"
    if (task.text != null) {
        task.text.replaceNode {}
    }
    task.appendNode {
        output {
            type {
                coding {
                    system(value: 'http://snomed.info/sct')
                    code(value: '146851000146105')
                }
            }
            valueDateTime(value: param.newDate)
        }
    }

    // The serializer in combination with the GPathResult (datatype of the XML Task) has the nasty habit of adding
    // "tag0" as the default namespace, so each FHIR element becomes "tag0:Task" etc. There are probably ways to solve
    // this in a decent way, but they are hard to find, so we just take a pragmatic approach and filter "tag0" from
    // the result.
    output[param.fixtureId] = XmlUtil.serialize(task).replace("tag0:", "").replace("xmlns:tag0", "xmlns")
}
