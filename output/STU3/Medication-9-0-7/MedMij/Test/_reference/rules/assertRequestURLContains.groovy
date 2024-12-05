/*
 rule.summary=Check if request contains one of the expected search parameters: ${param.searchparam1} or ${param.searchparam2}
 rule.description=Assert that the request contains one of the expected search parameter
 rule.param.searchparam1.required=true
 rule.param.searchparam2.required=true
*/

assert contains("${param.searchparam1}", request.getURL()) || contains("${param.searchparam2}", request.getURL()): "The search URL did not contain one of the expected search parameters: ${param.searchparam1} or ${param.searchparam2}"
