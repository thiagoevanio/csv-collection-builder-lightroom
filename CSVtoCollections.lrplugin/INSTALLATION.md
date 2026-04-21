# Installation Guide (Mac)

1. Download and unzip the plugin folder.
2. Open Lightroom Classic.
3. Go to `File > Plug-in Manager`.
4. Click `Add`.
5. Select `CSVtoCollections.lrplugin`.
6. Make sure the plugin is enabled.
7. Put your CSV files inside `CSVtoCollections.lrplugin/CSV Files`.
8. Go to `Library > Plug-in Extras > Build Collections from CSV`.
9. Select the CSV file.
10. Review the preview.
11. Click `Create Collections`.

## Usage Guide

1. Prepare a CSV file with `First Name`, `Surname`, and `Class` columns.
2. Keep your CSV files inside `CSVtoCollections.lrplugin/CSV Files`.
3. In Lightroom Classic, open `Library > Plug-in Extras > Build Collections from CSV`.
4. Select your CSV file.
5. Review the preview totals and sample output.
6. Click `Create Collections` to apply changes.
7. Review the completion dialog.
8. Open the generated report file in `CSVtoCollections.lrplugin/Reports`.

## Notes

- Use UTF-8 CSV files when possible.
- Keep the plugin folder name exactly as `CSVtoCollections.lrplugin`.
- The plugin uses fixed `CSV Files` and `Reports` folders inside `CSVtoCollections.lrplugin`.
- If the plugin does not appear, reopen Plug-in Manager and confirm it is enabled.
- If the report cannot be saved, check folder write permissions for `CSVtoCollections.lrplugin/Reports`.
