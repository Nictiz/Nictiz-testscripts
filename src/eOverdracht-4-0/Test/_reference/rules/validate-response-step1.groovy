/*
 rule.summary=Perform profile validation
 rule.description=Perform profile validation (description)
*/

try {
    response.assertValidWithProfileId("Bundle-profile");
} catch (Throwable e) {
    //logger.info(e.properties.toString());
    output["validationErrors"] = e.getMessage();
    output["validationWarnings"] = e.warningMessage;
    // def msg = e.getMessage.split('\n').findAll {line ==~ /.*ERROR.*/}
    // def filtered = e.getMessage().split('\n').findAll {it -> true}
    // warn(e.getMessage().split(',')[1]);
    // e.getMessage().split('\n').each {line ->
        // if (!(line ==~ /.*ERROR: Slicing cannot be evaluated: Error in discriminator at .*: no children, no type.*/)) {
        // warn(line);
        // }
    // }
    // logger.info("warningMessage:")
    // logger.info(e.warningMessage)
    // logger.info("Class: " + e.warningMessage.class)

    // def messages = e.warningMessage.split(", (WARNING|ERROR)");
    // logger.info(messages[0]);
    // logger.info(messages[1]);
    // logger.info(messages[2]);
    // logger.info(messages[3]);
    // logger.info(messages[4]);
    // logger.info(messages[5]);
    // logger.info(messages[6]);
    // logger.info(messages[7]);
    // logger.info(messages[8]);
    // logger.info(messages[9]);
    // logger.info(messages[10]);
    // logger.info(messages[11]);
    // logger.info(messages[12]);
    // for (int i = 0; i < 1; i++) {
    //     logger.info("Foo");
    // }

    // e.warningMessage.split(", (WARNING|ERROR)").each {
    //     warn(it)
    // }
    // logger.info("detailMessage")
    // logger.info(e.detailMessage)
    // logger.info("Class: " + e.detailMessage.class)
    
    // warn(e.dump());
    // warn(e.inspect());
    // e.getMessage().split("\\n").each() { message ->
        // warn(e.getMessage())
    // }
    // errorsAndWarnings.registerAndContinue(e);
}