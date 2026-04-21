# CSV Collection Builder for Lightroom Classic

## Supported environment

- Adobe Lightroom Classic on Mac desktop
- Lightroom SDK-based plugin runtime (Lua)
- No external dependencies

This plugin is designed for Lightroom Classic catalogs and does not require any third-party Lua libraries.

## What this plugin does

CSV Collection Builder is a Lightroom Classic plugin that creates Collection Sets and Collections from a CSV file.

- The `Class` value becomes a top-level Collection Set.
- Each child becomes a Collection inside that Collection Set.
- Collection naming rule: `First Name + first 2 characters of Surname`.

Example:

- `First Name: Harry`, `Surname: White`, `Class: Room A` -> `Room A > HarryWh`

## What this plugin does not do

This plugin does **not**:

- Import photos
- Move photos
- Edit photos
- Apply presets
- Modify image metadata

It only creates Collection Sets and Collections in the current Lightroom catalog.

## Required CSV format

Minimum required columns:

- First Name
- Surname
- Class

The first non-empty CSV row is treated as the header row.

Header variations supported:

- First Name: `First Name`, `FirstName`, `Forename`, `Name`, `Child First Name`, `Child's First Name`
- Surname: `Surname`, `Last Name`, `LastName`, `Family Name`, `Child's Surname`
- Class: `Class`, `Room`, `Classroom`, `Group`, `Child's Class`, `The Class That They Are In`

The parser supports:

- UTF-8 BOM removal
- Comma delimiter, plus simple auto-detection for semicolon and tab
- Quoted fields
- Commas inside quoted fields
- Escaped quotes (`""`)
- CRLF and LF line endings
- Empty line handling

## Example result

Input CSV:

```csv
First Name,Surname,Class
Harry,White,Room A
Anna,Smith,Room A
John,Brown,Room B
```

Result in Lightroom:

- Collection Set: Room A
  - Collection: HarryWh
  - Collection: AnnaSm
- Collection Set: Room B
  - Collection: JohnBr

## Import workflow

1. Go to `Library > Plug-in Extras > Build Collections from CSV`.
2. Put your input files in `CSVtoCollections.lrplugin/CSV Files`.
3. Select a CSV file.
4. Review the preview summary.
5. Click `Create Collections`.
6. Review completion message, CSV folder path, and report file path.

## Usage notes

- The plugin creates only top-level Collection Sets and child Collections.
- Collections are matched by name inside each Collection Set.
- The same Collection name may exist in different Collection Sets.
- If a surname has fewer than 2 characters, the plugin uses what is available and logs a warning.
- The plugin uses fixed folders inside `CSVtoCollections.lrplugin` for organization.

## Report output

The plugin organizes support files in fixed folders inside `CSVtoCollections.lrplugin`:

- `CSV Files` for input CSV files
- `Reports` for generated reports and error logs

After execution, a report is generated in the `Reports` folder:

- `CSVCollectionBuilder_Report_YYYYMMDD_HHMMSS.txt`

The report includes:

- Import summary
- Warnings
- Errors
- Per-collection details

## Troubleshooting

- If the plugin reports missing columns, confirm your header names or use a supported alias.
- If rows are skipped, review the report file for row-level reasons.
- If no collections are created, ensure `First Name` and `Class` are populated.
- If collection names are shorter than expected, check `Surname` length and content.
- If the report cannot be written, confirm you have write permission in `CSVtoCollections.lrplugin/Reports`.
- If the same CSV is imported twice, existing sets/collections are detected and not duplicated.

## Support notes

Automated Lightroom catalog creation cannot be executed outside Adobe Lightroom Classic. The CSV parser and file structure can be validated separately, and final catalog behavior must be tested inside Lightroom Classic.

## Plugin folder contents

- `Info.lua`
- `CSVImporter.lua`
- `CsvParser.lua`
- `CollectionBuilder.lua`
- `Utils.lua`
- `README.md`
- `INSTALLATION.md`
- `SAMPLE.csv`
- `TEST_PLAN.md`
- `CHANGELOG.md`
