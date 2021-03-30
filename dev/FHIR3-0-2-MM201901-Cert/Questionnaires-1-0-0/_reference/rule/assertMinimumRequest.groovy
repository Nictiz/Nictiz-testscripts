/*
 rule.summary=Check if request conforms to the minimum fixture in the same format as the request (xml/json)
 rule.description=Assert that the request contains the minimum required amount of data
 rule.param.minimumFixtureBase.required=true
*/

assert request.header("Content-Type").contains("json") || request.header("Content-Type").contains("xml"): "Expected JSON or XML in message body"
assert request.body != null: "Expected message body but did not find it in request"
String postfix = (request.header("Content-Type").contains("json")) ? "-json" : "-xml"
request.assertMinimum(param.minimumFixtureBase + postfix)