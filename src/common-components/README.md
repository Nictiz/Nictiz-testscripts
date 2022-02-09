# Common components

This folder contains re-usable components that can be used across different NTS projects. Files in the root are considerd to be suitable for *all* projects and align with the Nictiz FHIR IG, while files for specific IG's should be placed in subfolders.

## Naming conventions

To help identifying what the common components can be used for, they are named according to the following scheme:

> [type of component].[description].[for what]
 
There are no hard rules for each of these naming parts, but so far the following parts are in use:
* Type of component:
    * "assert": One or more asserts.
    *  "canary-assert": One or more asserts that are not meant for the system under test, but as a "canary" for the test server.
    * "test": An action plus one or more asserts.
    * "header": Add a header to a request.
* For what:
    * "request", "response" or "general" for assert components.
    * "phr" and "xis" for test commponents. NB this is in a MedMij context. In a general context, this would probably be "client" and "server".
    
### "Internal" components

Some of the re-usable components are meant to be included in other components rather than to be used directly in NTS projects. These components start with an underscore. This is just a convention, it doesn't restrict their use in any way. However, if it turns out the there is a direct use for such an "internal" component, it should be renamed and described properly.