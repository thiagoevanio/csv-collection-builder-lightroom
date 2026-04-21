CSV Input Guide
================

Place the client's CSV files in this folder.

This plugin is configured to open this folder by default when selecting a CSV
file in Lightroom Classic.


What the plugin does
====================

The plugin reads a CSV file and creates:

- one Collection Set for each class
- one Collection for each child inside the correct Collection Set

It does not import, move, rename, edit, or organize photos. It only creates
Collection Sets and Collections in the Lightroom catalog.


Required data
=============

Each CSV must include 3 columns:

- First Name
- Surname
- Class

The first non-empty row is treated as the header row.


Recommended header row
======================

This is the recommended format:

First Name,Surname,Class


Other accepted header names
===========================

The plugin also accepts these header variations.

First Name column:
- First Name
- FirstName
- Forename
- Name
- Child First Name
- Child's First Name

Surname column:
- Surname
- Last Name
- LastName
- Family Name
- Child's Surname

Class column:
- Class
- Room
- Classroom
- Group
- Child's Class
- The Class That They Are In


Naming rule
===========

Each Collection name is created as:

First Name + first 2 letters of Surname

Examples:
- Harry + White -> HarryWh
- Anna + Smith -> AnnaSm
- John + Brown -> JohnBr

If the surname has fewer than 2 letters, the plugin uses what is available and
adds a warning to the report.


Example CSV
===========

First Name,Surname,Class
Harry,White,Room A
Anna,Smith,Room A
John,Brown,Room B


Example result in Lightroom
===========================

Room A
- HarryWh
- AnnaSm

Room B
- JohnBr


Accepted file formats
=====================

The plugin accepts:

- .csv files
- .txt files containing CSV-style data
- comma-separated files
- semicolon-separated files
- tab-separated files
- UTF-8 files
- UTF-8 with BOM
- files with LF or CRLF line endings
- quoted values
- commas inside quoted values
- escaped quotes written as ""


Best practice for the client
============================

For the safest result, ask the client to save the file as:

- .csv
- UTF-8
- comma-separated
- header row exactly as: First Name,Surname,Class

Recommended standard format
===========================

This is the standard format we recommend sending to the client:

- save as .csv
- use UTF-8
- use the header row: First Name,Surname,Class
- separate values with commas


Important behavior
==================

- If First Name is empty, that row is skipped.
- If Class is empty, that row is skipped.
- If Surname is empty, the Collection name is created from First Name only and
  a warning is added to the report.
- If a row has fewer columns than expected, missing values are treated as empty.
- If a row has extra columns, extra values are ignored.
- Empty rows are ignored.
- Running the same CSV again does not create duplicate Collection Sets or
  duplicate Collections in the same set.


How to use
==========

1. Put the client's CSV file in this folder.
2. Open Lightroom Classic.
3. Go to Library > Plug-in Extras > Build Collections from CSV.
4. Select the CSV file.
5. Review the preview.
6. Click Create Collections.
7. Check the report generated in the Reports folder.


Report file
===========

After each import, the plugin creates a report in:

CSVtoCollections.lrplugin/Reports

The report includes:

- summary totals
- warnings
- errors
- details of created items
- details of items that already existed


Quick template to copy
======================

First Name,Surname,Class
Harry,White,Room A
Anna,Smith,Room A
John,Brown,Room B
