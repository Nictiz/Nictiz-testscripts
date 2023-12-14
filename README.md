# Nictiz TestScripts

This repository contains the test and qualification materials for the FHIR based standards that Nictiz maintains. These materials consist of FHIR TestScript resources plus associated fixtures.

The materials in this repository are developed and maintained using a custom shorthand format called NTS (Nictiz Test Scripts), which is maintained [in a separate repository](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate). The source materials can be found in the `src` folder, while the generated output can be found in the `dev` folder. This output folder needs to be called `dev` (only) to ease the synchronization of materials to the `dev` folder on Touchstone during development. In stable branches, the `dev` folder contains production materials. 

The projects in `src` are generally organized first by standard and then by the type of material (test and qualification). See below for the conventions on folder names in the repo.

To transform the source NTS materials to their output, [Apache ANT](https://ant.apache.org/) is required. Each project defines the output parameters using a `build.properties` file in the project folder (see below for the available parameters). At the root of the `src` folders, ANT build files and Windows batch files can be found for different steps in the build proces:

* Transforming one or more NTS project(s) to output containing the TestScript resources, fixtures and loadscripts.
* Adding narratives to the fixtures.
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
### build.properties parameters
#### General
* `components.dir` - The directory of the dir with components for this project, _relative to the base dir of this repo_. Normally not needed.
* `version.addition` - A string that will be added verbatim to the value in the TestScript.version from the input file. The default is defined in the folder 'buildscripts/version.addition.properties'.

#### build.properties in an NTS target directory
* `input.dir` - The directory of the NTS target, _relative to the base dir of this repo_. Required.
* `output.dir` - The directory of the output folder, _relative to the base dir of this repo_. Required.
* `targets.additional` - Comma separated list of [additional targets](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate#building-different-variants) to build.

#### build.properties for building multiple targets
* `input.dirs` - A comma-seperated list of dirs, _relative to the base dir of this repo_, each containing a build.properties file. Required.

### For building narratives
* `generate.narratives.pattern` - The root folder of the fixtures where the narrative needs to be added. Needs to be defined in the build.properties for multiple targets, but is normally not needed in the build.properties for a single target.
* `dontgenerate.narratives.pattern` - Comma seperated list of additional file name patterns that should be excluded from narrative generation. By default, the 'minimum' folder and '-token.xml' files are excluded.

### For loadscripts
* `loadresources.exclude` - Comma separated list of folders to exclude from loadscript generation, _relative to the folder containing the fixtures_.
