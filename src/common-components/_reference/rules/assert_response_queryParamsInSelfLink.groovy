/*
 rule.summary=Bundle.link.where(relation = 'self').url contains all parameters from the request URL
 rule.description=Assert that the parameters in the request URL are all handled by the server by inspecting the self link. 
*/

String[] reqParts = java.net.URLDecoder.decode(request.getURL()).split("\\?")
if (reqParts.length > 0) {
	String selfLink = java.net.URLDecoder.decode(response.getFhirPathValue("Bundle.link.where(relation = 'self').url"))
    String reqParams = reqParts[1]
    for (String reqParamFull : reqParams.split('&')) {
        if (!selfLink.contains(reqParamFull)) { // See if the param and value are present verbatim in the self link

            // If not, this might be due to the fact that the parameter is a reference that was rewritten by the
            // server, either by adding the resource type or removing it.
            def (reqParam, reqVal) = reqParamFull.split('=')
            def refPattern = /^([A-Z][A-Za-z]+\/)?([A-Za-z0-9\-\.]{1,64})$/
            def asReference = reqVal =~ refPattern

            def errorString = "The requested parameter ${reqParamFull} was absent from the self link"

            if (!asReference) {
                // Apparently, the request parameter wasn't a reference
                fail(errorString)
            } else {
                if (asReference[0][1] == null) {
                    // Resource type was not present in the request, so let's see if we have a match _with_ something
                    // that looks like a resource type.
                    assert selfLink =~ /${reqParam}=[A-Z][A-Za-z]+\/${asReference[0][2]}/ : errorString
                } else {
                    // Resource type was present in the request, so let's see if we have a match without it.
                    assert selfLink.contains("${reqParam}=${asReference[0][2]}") : errorString
                }
            }
        }
    }
}