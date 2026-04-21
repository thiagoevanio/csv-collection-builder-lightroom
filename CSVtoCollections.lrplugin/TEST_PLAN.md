# Manual Test Plan

## Scope

This checklist validates plugin behavior in Adobe Lightroom Classic.

Automated Lightroom catalog creation cannot be executed outside Adobe Lightroom Classic. The CSV parser and file structure can be validated separately, and final catalog behavior must be tested inside Lightroom Classic.

## Preconditions

- Lightroom Classic installed on Mac desktop.
- Plugin loaded and enabled in Plug-in Manager.
- Test catalog available.
- `SAMPLE.csv` available.

## Checklist

- [ ] Install plugin on Lightroom Classic.
- [ ] Confirm menu entry exists at `Library > Plug-in Extras > Build Collections from CSV`.
- [ ] Load `SAMPLE.csv`.
- [ ] Confirm preview dialog appears.
- [ ] Confirm preview summary numbers are reasonable.
- [ ] Confirm preview text includes expected `Class > Collection` entries.
- [ ] Click `Create Collections`.
- [ ] Confirm `CSV Files` and `Reports` folders exist inside `CSVtoCollections.lrplugin`.
- [ ] Confirm Collection Sets were created.
- [ ] Confirm Collections were created inside correct sets.
- [ ] Confirm naming rule (`First Name + first 2 chars of Surname`).
- [ ] Confirm report file was generated inside `CSVtoCollections.lrplugin/Reports`.

## Duplicate and idempotency tests

- [ ] Run the same CSV import again.
- [ ] Confirm no duplicate Collection Sets are created.
- [ ] Confirm no duplicate Collections are created in the same set.
- [ ] Confirm report marks existing sets/collections.

## Validation and error handling tests

- [ ] Test CSV with missing `First Name` values.
- [ ] Test CSV with missing `Class` values.
- [ ] Test CSV with missing `Surname` values.
- [ ] Confirm problematic rows are skipped with warnings.
- [ ] Confirm missing required headers show friendly errors.
- [ ] Confirm empty file shows friendly error.
- [ ] Confirm canceling file selection exits gracefully.
- [ ] Confirm report save failure shows friendly message when `CSVtoCollections.lrplugin/Reports` is not writable.

## CSV parser robustness tests

- [ ] Test quoted values with commas.
- [ ] Test escaped quotes (`""`) inside values.
- [ ] Test CRLF and LF line endings.
- [ ] Test semicolon-delimited CSV.
- [ ] Test tab-delimited CSV.
- [ ] Test UTF-8 BOM CSV.
- [ ] Test surnames with accented UTF-8 characters (example: `Ávila`, `João`).

## Expected outcome

- Plugin creates only Collection Sets and Collections.
- Plugin does not import or alter photos.
- User-facing text is in English.
- Report file includes summary, warnings, errors, and details.
