# Changelog

## 1.0.1 - 2026-04-20

- Improved collection name generation for UTF-8 surnames when extracting first 2 characters.
- Improved user-facing error messages for report save failures.
- Improved Lightroom catalog write failure message with actionable guidance.
- Added resilient local module loading with friendly configuration error handling.
- Prioritized Lightroom import-based module loading to reduce module resolution conflicts.
- Added detailed unexpected error diagnostics in the import failure dialog.
- Replaced `xpcall` with `pcall` for Lightroom runtime compatibility (`xpcall` may be nil in some builds).
- Aligned `CSVImporter.lua`, `CsvParser.lua`, and `CollectionBuilder.lua` with the known-working V104 runtime baseline.
- Expanded installation guide with an explicit usage guide section.
- Expanded README with compatibility, usage notes, and troubleshooting details.
- Expanded manual test plan with UTF-8 and report permission scenarios.

## 1.0.0 - 2026-04-20

- Initial release of `CSVtoCollections.lrplugin`.
- Added CSV import workflow from `Library > Plug-in Extras`.
- Added CSV parser with support for quoted fields, escaped quotes, BOM handling, and delimiter auto-detection.
- Added preview dialog before catalog write operations.
- Added collection set and collection creation logic with duplicate protection.
- Added final report generation to `.txt` file next to source CSV.
- Added installation guide, sample CSV, README, and manual test plan.
