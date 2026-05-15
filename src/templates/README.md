# FHIR TestScript Templates

This folder contains starter templates for FHIR TestScript source files that are
written in NTS and generated from `src` to `output` by the Nictiz TestScript
tooling.

These files are templates only. Do not build this folder directly. Copy the
files you need into an actual NTS unit and replace all `TODO` values first.

For the repository layout, build properties, and normal build flow, see the
[repository README](../../README.md). For NTS syntax and generator behavior, see
the [NTS generate README](https://github.com/Nictiz/Nictiz-tooling-testscripts/tree/main/generate).

## Files

| File | Purpose |
| --- | --- |
| `build.properties` | Template for the NTS unit build configuration. Copy this to `src/<InformationStandard>/<Test\|Cert>/build.properties`. |
| `src-properties.json` | Template for ConformanceLab folder metadata. Copy this to each role/input folder that contains NTS XML files. |
| `Retrieve.xml` | Template for a retrieving system that performs FHIR `search` and `read` interactions. |
| `Serve.xml` | Template for a serving system that responds to FHIR `search` and `read` interactions. |
| `Send.xml` | Template for a sending system that sends a FHIR `transaction` Bundle. |
| `Receive.xml` | Template for a receiving system that receives a FHIR `transaction` Bundle. |

## Role Mapping

| Template | Default role folder | NTS scenario | System under test |
| --- | --- | --- | --- |
| `Retrieve.xml` | `Retrieving-System` | `client` | The system initiates requests to retrieve data. |
| `Serve.xml` | `Serving-System` | `server` | The system responds to retrieval requests. |
| `Send.xml` | `Sending-System` | `client` | The system initiates a send transaction. |
| `Receive.xml` | `Receiving-System` | `server` | The system handles an incoming send transaction. |

Projects may use more specific role folder names, such as `Retrieving-XIS` or
`Sending-PHR`, when that better matches the information standard. Make sure the
`role.name` in `src-properties.json` matches the role shown to users.

## Basic Use

1. Copy `build.properties` to the NTS unit folder, for example:
   `src/<InformationStandard>/<Test|Cert>/build.properties`.
2. Create or choose the role folder under that NTS unit, for example:
   `src/<InformationStandard>/<Test|Cert>/Retrieving-System/`.
3. Copy the matching XML template into the role folder and rename it to the
   final TestScript id.
4. Copy `src-properties.json` into the same role folder and update the role
   metadata.
5. Add any required fixtures under the unit's `_reference` folder. The send and
   receive templates expect Bundle fixtures under `bundles/send/` and
   `bundles/receive/`.
6. Replace every `TODO` value in the copied files.
7. Run the normal NTS build for the unit. The generated FHIR TestScript files
   are written to the `output.dir` configured in `build.properties`.

## Notes

- Keep template comments in English.
- Keep `src-properties.json` valid JSON; JSON comments are not allowed.
- `build.properties` paths are relative to the repository root.
- `{$_FORMAT}` in fixture paths lets the generated TestScript follow the active
  output format when XML and JSON fixture variants are available.
- Use `nts:authToken` only when the scenario needs a patient token. The
  referenced `patientResourceId` must exist in
  `Configuration/QualificationTokens.json`.
