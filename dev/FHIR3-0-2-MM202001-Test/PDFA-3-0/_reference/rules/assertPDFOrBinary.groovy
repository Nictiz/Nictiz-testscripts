/*
 rule.summary=Check if the response is a raw PDF or a Binary resource
 rule.description=Check if the response has either a Content-Type of "application/pdf" or a body containing a Binary resource
*/

// When the Content-Type header is "application/pdf", there is no FHIR resource and the second check will result in a
// hard error (instead of an assert failure). Therefore we execute it in an explicit if/else body, so it won't be
// executed if the first condition evaluates to true.
if (response.header("Content-Type").contains("application/pdf")) {
	assert true;
} else {
	assert response.getFhirPathBoolean("Binary.exists()");
}
