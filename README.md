# Nictiz TestScripts

This repository contains the test and qualification materials for the FHIR based standards that Nictiz maintains. These materials consist of FHIR TestScript resources plus associated fixtures.

The materials in this repository are developed and maintained using a custom shorthand format called NTS (Nictiz Test Scripts), which is maintained [in a separate repository](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate). The source materials can be found in the `src` folder, while the generated output can be found in the `dev` folder. This output folder needs to be called `dev` (only) to ease the synchronization of materials to the `dev` folder on Touchstone during development. In stable branches, the `dev` folder contains production materials. 

The projects in `src` are generally organized first by standard and then by the type of material (test and qualification). See below for the conventions on folder names in the repo.

To transform the source NTS materials to their output, [Apache ANT](https://ant.apache.org/) is required. Each project defines the output parameters using a `build.properties` file in the project folder (see below for the available parameters). At the root of the `src` folders, ANT build files and Windows batch files can be found for different steps in the build proces:

* Transforming one or more NTS project(s) to output containing the TestScript resources, fixtures and loadscripts.
* Adding narratives to the fixtures.
* Converting appropriate XML fixtures to JSON format.
* Centralizing loadscripts to a common folder.

In addition to building each project folder individually, the `buildscripts` folder contains scripts to build sets of projects that should be released together. 

## Folder structure

NTS source folders are organized according to the [NTS defaults](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate#folder-structure) and use some defaults for inclusions and exclusions of building loadscripts and generating narratives.

```
- Standard/            : Root folder for all materials pertaining the standard
  - build.properties   : File with the parameters for building all NTS project folders (see below).
                         Only a few additional parameters in relation to the build.properties in the project folder are needed.
  - build-[xxx].bat    : Batch file to build every NTS project folder.
  - /[NTS target]/     : One or more folders that correspond to an output folder. Typically there are 'Test' and 'Cert' folders.
    - build.properties : A file where parameters to the build script may be set (see below).
    - build-[xxx].bat  : A batch file to run the build for this folder with the appropriate parameters.
    - /InputFolder1/   : One or more dirs containing the NTS files. WARNING: all folder names starting with an underscore are ignored, while all other folders are included!
    - /_components/    : The components specific for that project - may be overridden using the components.dir parameter
    - /_reference/     : The fixtures and rules for that project. This folder is copied verbatim to the output folder.
      - [xxx]-token.xml: Special Patient fixtures containing only the bearer token.
      - /resources/    : Folder containing all the fixtures. Usually, these are organized in subfolders. When files need to be excluded from the loadscript, they need to be placed in a subfolder, which is then marked using the [...]
        - /minimum/    : Folder containing fixtures for TestScript `minimumId` checks. By default, this folder is excluded from narrative generation.
      - /rules/        : Folder containing the TestScript rules. By default, this folder is excluded from narrative generation and loadscripts.
```

## Build scripts
For each of the distinct build steps, an ANT build script exists in the `src` folder. What each script does is determined by the properties defined (see below), normally in a `build.properties` file. In addition, there is a wrapper scripts to do a complete build with all the steps, and a wrapper script to do a complete build with all the steps for multiple NTS target directories. The latter script is more efficiënt when there's a need to build multiple directories, because it batches several steps.

However, things get do get a bit hairy as to where to set the properties, so it's important to understand how the different steps interact.

* `build-nts-single.xml` is used to convert the NTS input from a single NTS directory ("NTS Target" in the folder structure).
* `build-nts-multiple.xml` is basically a wrapper to perform `build-nts-single.xml` on multiple folders.
* `build-addNarratives.xml` is used to add the missing narratives in a folder with fixtures.
* `build-convertFixtures.xml` is used to convert fixtures from XML to JSON.
* `build-centralizeLoadResources.xml` is used to search all subfolders of a folder for loadscripts and create a single new subfolder with all these loadscripts (with rewritten paths). This is needed for Touchstone maintenance purposes.

The two wrapper scripts are:
* `build-single.xml` to do a complete build of a single NTS directory
  * converting the NTS files
  * adding narratives to the fixtures
  * converting relevant fixtures from XML to JSON
* `build-multiple.xml` does the same, but for multiple directories.

Please note that the loadscript centralization step is never done as part of these builds; this is a concern for Touchstone maintainers rather than maintainers of individual standards.

## Setting properties
### Single versus multiple
Since there are two possible levels at which a build can be started -- a single NTS source directory or a collection of source directories -- there are also two levels at which properties can be/need to be set. As described above, each NTS source directory needs to have a `build.properties` file with the relevant properties for that single directory. Some of these properties are also used when building multiple directory's, but some of them need to be defined on the collection level in a separate `build.properties`. The collection level files are typically found in the root of a standards folder and in the `buildscripts` directory.

### The NTS conversion step
These properties should be set in the `build.properties` file in the root of the directory to build:
* `input.dir` - The directory of the NTS target, _relative to the base dir of this repo_. Required.
* `output.dir` - The directory of the output folder, _relative to the base dir of this repo_. Required.
* `targets.additional` - Comma separated list of [additional targets](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate#building-different-variants) to build. Optional.
* `components.dir` - The directory of the dir with components for this project, _relative to the base dir of this repo_. Normally not needed, but may be used to override the default location.
* `version.addition` - A string that will be added verbatim to the value in the TestScript.version from the input file. The default is defined in the folder 'buildscripts/version.addition.properties'.

When building multiple directory's, the script needs to be told which directories to build. This can be set using a distinct `build.properties` file with the following entry's:
* `input.dirs` - A comma-separated list of dirs, _relative to the base dir of this repo_, each containing a `build.properties` file. Required.

### The narrative generation step
* `generate.narratives.pattern` - The root folder of the fixtures where the narrative needs to be added. For the `build-single.xml` step, this defaults to `output.dir` so it's not needed (and ignored) for a single directory. For `build-multiple.xml`, this property is required.
* `dontgenerate.narrative.pattern` - Comma separated list of additional file name patterns that should be excluded from narrative generation. By default, the `minimum`, `rule` and `rules` folders and '-token.xml' files are excluded. This property needs to be set separately for single and multiple builds.
* `fhir.version` - The FHIR version to target, defaults to STU3. This property needs to be set separately for single and multiple builds.

### The fixture converting step
There are no properties to explicitly set. The NTS steps analyze which fixtures need to be converted and pass these to `build-convertFixtures.xml`.

### The loadscript centralization step
* `subdirs` - Comma separated list of the base dirs where a centralized loadscript folder should be generated.
* `loadresources.exclude` - Comma separated list of folders to exclude from loadscript generation, _relative to the folder containing the fixtures_.

### Overriding tool versions
* `*.tool.version` - Override the tool version for one of the specific steps in the build process (the tool version is the full name of a git branch or tag). The wildcard aligns with the ANT project names of the build files in the `src` folder, so:
  * `generateContentAssertsForProject.tool.version` overrides the version for the script that converts a single NTS folder.
  * `generateContentAssertsForProjects.tool.version` overrides the version for the script that converts a multiple NTS folders.
  * `addNarrativesForFolder.tool.version` overrides the version for the narrative generator (this should be the name of a release, not a branch or tag).
  * `convertFixtures.tool.version` overrides the version of the tool that converts fixture from XML to JSON.
  * `centralizeLoadResources.tool.version` overrides the version for the script to centralize loadscripts.
