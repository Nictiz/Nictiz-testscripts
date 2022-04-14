/*
 rule.summary=Bundle.link.where(relation = 'self').url contains all parameters from the request URL
 rule.description=Assert that the parameters in the request URL are all handled by the server by expecting the self link. 
*/

String[] urlParts = java.net.URLDecoder.decode(request.getURL()).split("\\?")
if (urlParts.length > 0) {
	String selfLink = java.net.URLDecoder.decode(response.getFhirPathValue("Bundle.link.where(relation = 'self').url"))
	String requestParams = urlParts[1]
	for (String param : requestParams.split('&')) {
	    assert selfLink.contains(param) : "The request parameter \"" + param + "\" was absent from the self link." 
	}
}