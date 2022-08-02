# Nictiz TestScripts

This repository contains the test and qualification materials for the FHIR based standards that Nictiz maintains. These materials consist of FHIR TestScript resources plus associated fixtures.

The materials in this repository are developed and maintained using a custom shorthand format called NTS, which is maintained [in a separate repository](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate). The source materials can be found in the `src` folder, while the generated output can be found in the `dev` folder. This output folder needs to be called `dev` (only) to ease the synchronization of materials to the `dev` folder on Touchstone during development. In stable branches, the `dev` folder contains production materials. 

The projects in `src` are generally organized first by standard and then by the type of material (test and qualification). See the (documentation on NTS folder structures for more information)[https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate#folder-structure].

To transform the source NTS materials to their output, [Apache ANT](https://ant.apache.org/) is required. Each project defines the output parameters using a `build.properties` file in the project folder. On the root of the `src` files, ANT build files and Windows batch files can be found for different steps in the build proces:

* Transforming one or more NTS project(s) to output containing the TestScript resources, fixtures and loadscripts.
* Adding narratives to the fixtures.
* Centralizing loadscripts to a common folder.

Apart from building each project folder separately, the `buildscripts` folder contains scripts to build sets of projects that should be release together. 
