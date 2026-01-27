# Nictiz TestScripts

This repository contains the test and qualification materials for the FHIR based standards that Nictiz maintains. These materials consist of FHIR TestScript resources plus associated fixtures.

The materials in this repository are developed and maintained using a custom shorthand format called NTS (Nictiz Test Scripts), which is maintained [in a separate repository](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate). The source materials can be found in the `src` folder, while the generated output can be found in the `output` folder.

The projects in `src` are generally organized first by standard and then by the type of material (test and qualification). See below for the conventions on folder names in the repo.

To transform the source NTS materials to their output, [Apache ANT](https://ant.apache.org/) is required. Each project defines the output parameters using a `build.properties` file in the project folder (see below for the available parameters). At the root of the `src` folders, ANT build files and Windows batch files can be found for different steps in the build proces:

* Transforming one or more NTS project(s) to output containing the TestScript resources, fixtures and loadscripts.
* Adding narratives to the fixtures.
* Converting appropriate XML fixtures to JSON format.
* Generating folder property files for the Conformancelab test engine.

In addition to building each project folder individually, the `buildscripts` folder contains scripts to build sets of projects that should be released together. 

## Folder structure

NTS source folders are organized according to the [NTS defaults](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate#folder-structure) and use some defaults for inclusions and exclusions of building loadscripts and generating narratives.

```
- Standard/              : Root folder for all materials pertaining the standard
  - build-[xxx].bat/sh   : Batch file to build every NTS project folder.
  - /[NTS unit]/         : One or more folders that correspond to an output folder. Typically there are 'Test' and 'Cert' folders.
                           This is seen as a discrete unit, containing materials for the combination of one standard and one goal,
                           and with dependencies applying to everything in the folder.
    - build.properties   : A file where parameters to the build script may be set (see below).
    - build-[xxx].bat/sh : A batch file to run the build for this folder with the appropriate parameters.
    - /InputFolder1/     : One or more dirs containing the NTS files (see below for more information). WARNING: all folder names
                           starting with an underscore are ignored, while all other folders are included!
    - /_components/      : The components specific for that project - may be overridden using the components.dir parameter
    - /_reference/       : The fixtures and rules for that project. This folder is copied verbatim to the output folder.
      - /resources/      : Folder containing all the fixtures. Usually, these are organized in subfolders.
        - /minimum/      : Folder containing fixtures for TestScript `minimumId` checks. By default, this folder is excluded from narrative generation.
      - /rules/          : Folder containing the TestScript rules. By default, this folder is excluded from narrative generation and loadscripts.
```

So for each combination of standard, goal and/or usecase, there is an 'NTS unit folder' that can be regarded as a discrete unit for building and publishing. The NTS input files are placed in subfolders under this main target. There are some rules for these folders:

* As stated above, they may not begin with and underscore. Apart from that, there are no strict naming limitations.
* Folders may be nested up to three levels deep.
* One of folder names in the subfolder hierarchy must correspond with a "role" that the user (the system under test) plays in the exchange. Default roles are "XIS-Server" and "PHR-Client" (MedMij) and "Sending-System", "Receiving-System", "Serving-System" and "Retrieving-System", but others may be used if it makes more sense for the information standard (see the `roles` property below).

## Build scripts

The normal way to perform the NTS transformation is by using one of two ANT scripts in the `src` folder:
* `build-single.xml` to do a complete build of a single NTS directory
  * converting the NTS files
  * adding narratives to the fixtures
  * converting relevant fixtures from XML to JSON
  * adding Conformancelab folder property files
* `build-multiple.xml` does the same, but for multiple directories (it is more efficient than running `build-single.xml` multiple times because it batches several steps). This can only be used for NTS directories with the same FHIR version!

If needed, an ANT build script exists for each of the distinct build steps, What each script does is determined by the properties defined (see below) in a `build.properties` file:

* `build-nts-single.xml` is used to convert the NTS input from a single NTS directory ("NTS Target" in the folder structure).
* `build-nts-multiple.xml` is basically a wrapper to perform `build-nts-single.xml` on multiple folders.
* `build-addNarratives.xml` is used to add the missing narratives in a folder with fixtures.
* `build-convertFixtures.xml` is used to convert fixtures from XML to JSON.
* `build-CLPropertiesFiles.xml` is used to add property files for Conformancelab in all TestScript containing subfolders of an output folder.

## Build properties
As described above, each NTS source directory needs to have a `build.properties` file with the following properties:

Parameters influencing the build process:

* `input.dir` (required) - The directory of the NTS target, _relative to the base dir of this repo_.
* `output.dir` (required) - The directory of the output folder, _relative to the base dir of this repo_.
* `fhir.version` (required) - The FHIR version of the exchange that is being tested, either "STU3" or "R4". Used for generating content specific asserts and for the Conformancelab properties.json.
* `goal` (required) - The goal of this set of scripts, either "Test" or "Cert".
* `informationStandard` (required) - The human readable name of the information standard this set of TestScripts is about, normally including the major version number. This is what's shown in the ConformanceLab interface.
* `usecase` (required) - The usecase, in the broadest sense of the word, these TestScripts apply to -- for example MedMij, eOverdracht MeO, etc. For MedMij, this must be the string "MedMij".
* `serverAlias` (required) - The alias of the server that the test set should use on the Conformancelab platform.
* [`targets.additional`] (optional) - Comma separated list of [additional targets](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate#building-different-variants) to build.
* [`dontgenerate.narrative.pattern`] (optional) - Comma separated list of file name patterns that should be excluded from narrative generation. By default, the `minimum`, `rule` and `rules` folders and '-token.xml' files are excluded.
* [`loadresources.exclude`] (optional) - A relative path to a folder containing the fixtures or to specific filenames to be excluded from the LoadResources script. Multiple entries can be comma separated. `*` is accepted as a wildcard.
* [`components.dir`] (optional) - The directory containing the project components, relative to input.dir. Defaults to `_components`.
* [`reference.subdir`] (optional) - The _name_ (not the path!) of the folder containing fixtures. Defaults to `_reference`.
* `processfixtures.skip`

Parameters to specify additional information:
* [`version.addition`] (optional) - A string that will be added verbatim to the value in the `TestScript.version` from the input file. The default is defined in the folder `Configuration/version.addition.properties`.
* [`packages`] (optional) - Comma separated list with the canonicals of the FHIR packages that should be used when the test engine performs profile validation.
* `package.[canonical]` (required for each package) - For each package listed using the `packages` property, the version of the package used. This is normally set in the common file `Configuration/package.version.properties`.
* `target.description.[additional target]` (required for each additional target) - For each defined additional target, a human readable description of the target.
* [`targets.adminOnly`] (optional) - Comma separated list of additional targets (see above) that in the test platform should be marked "admin only", i.e. not for end users.

## Conformancelab properties
Each output folder containing TestScripts and the folder containing a LoadResources-script, need a `properties.json` file to be accessible in Conformancelab. For the LoadResources folder, this file is generated from the build properties. 

In each input folder containing NTS-files, a file called `src-properties.json` must be present. This required file, which is copied to the output folder, should contain the following properties:

* `goal` (required) - Duplicates the property present in `build.properties`, `${goal}` should be used here to avoid entering the same property multiple times.
* `fhirVersion` (required) - Duplicates the property present in `build.properties`, `${fhir.version}` should be used here to avoid entering the same property multiple times.
* `informationStandard` (required) - Duplicates the property present in `build.properties`, `${informationStandard}` should be used here to avoid entering the same property multiple times.
* `usecase` (required) - Duplicates the property present in `build.properties`, `${usecase}` should be used here to avoid entering the same property multiple times.
* `role.name` (required) - The role that the user (system under test) plays in the exchange when using the TestScripts in this folder.
* [`role.description`] (optional) - A description of the role.
* [`category`] (optional) - Optional category of the set of TestScripts to be shown in the UI.
* [`subcategory`] (optional) - Optional subcategory of the set of TestScripts to be shown in the UI.
* [`adminOnly`] (optional) - If `true`, marks a folder that in the test platform should be marked "admin only", i.e. not for end users.
* `serverAlias` (required) - Duplicates the property present in `build.properties`, `${serverAlias}` should be used here to avoid entering the same property multiple times.

The following properties are automatically added to `properties.json` during the build:
* [`fhirPackage`] (optional, including `.name` and `.version`) - Derived from the `packages` build property
* [`variant`] (optional) - Added to the properties of a specific `target` that is defined in the `targets.additional` property. `target.description.[additional target]` is used as `variant.description`.
* [`adminOnly`] (optional) - If absent of `false` in `src-properties.json`, this property with value `true` is added if the current target is present in the `targets.adminOnly` property.

### Overriding tool versions
* `*.tool.version` - Override the tool version for one of the specific steps in the build process (the tool version is the full name of a git branch or tag). The wildcard aligns with the ANT project names of the build files in the `src` folder, so:
  * `generateContentAssertsForProject.tool.version` overrides the version for the script that converts a single NTS folder.
  * `generateContentAssertsForProjects.tool.version` overrides the version for the script that converts a multiple NTS folders.
  * `addNarrativesForFolder.tool.version` overrides the version for the narrative generator (this should be the name of a release, not a branch or tag).
  * `convertFixtures.tool.version` overrides the version of the tool that converts fixture from XML to JSON.
  * `buildCLPropertiesFiles.tool.version` overrides the version of the tool that generates Conformancelab properties files.
