# CSV Collection Builder for Lightroom Classic

> Automates Lightroom collection organization in seconds using structured CSV data.

## 🚀 Status

✔ Production-ready  
✔ Successfully delivered to client  
✔ Actively usable in real workflows  

## 🖼️ Preview

### 📂 Generated Collections
<img width="1366" height="724" alt="result" src="https://github.com/user-attachments/assets/5121c714-627c-461a-9377-651cb98f3a59" />

### 📄 CSV Selection
<img width="1366" height="698" alt="select-csv" src="https://github.com/user-attachments/assets/32f2a373-2b97-444c-a155-df537d40b3f2" />

### ⚙️ Plugin Installed
<img width="1366" height="717" alt="plugin-manager" src="https://github.com/user-attachments/assets/201726ef-cd65-4066-a592-b8e3c89ea68a" />

A professional Adobe Lightroom Classic plugin that automates the creation of **Collection Sets** and **Collections** from CSV files.

This project was developed for a real client workflow and delivered successfully. The plugin was built to reduce repetitive manual organization inside Lightroom catalogs by transforming spreadsheet data into a clean collection structure in just a few clicks.

## Overview

This plugin reads a CSV file and creates:

- one **Collection Set** for each class/group
- one **Collection** for each child/item inside the correct Collection Set

### Naming rule

Each collection name is generated using:

`First Name + first 2 letters of Surname`

Example:

- `Harry, White, Room A` → `Room A > HarryWh`
- `Anna, Smith, Room A` → `Room A > AnnaSm`
- `John, Brown, Room B` → `Room B > JohnBr`

## Problem Solved

The client needed a Lightroom Classic plugin to automate catalog naming and collection creation based on CSV data, without touching the photos themselves.

Manual creation of collection sets and collections for large school or client-based photo libraries is repetitive and error-prone. This plugin eliminates that manual work and standardizes the process.

## Features

- CSV import workflow directly inside Lightroom Classic
- Automatic creation of top-level Collection Sets from class/group values
- Automatic creation of child Collections inside the correct set
- Preview dialog before writing to the catalog
- Duplicate protection for existing sets and collections
- CSV parser with support for:
  - UTF-8 and UTF-8 BOM
  - comma, semicolon, and tab delimiters
  - quoted values
  - escaped quotes
  - CRLF and LF line endings
- Friendly validation and error handling
- Detailed report generation after import
- Installation guide and manual test plan included

## Supported CSV Columns

Required logical fields:

- `First Name`
- `Surname`
- `Class`

The plugin also supports common header aliases such as:

- `FirstName`, `Forename`, `Name`
- `Last Name`, `Family Name`
- `Room`, `Classroom`, `Group`

## What the Plugin Does Not Do

This plugin does **not**:

- import photos
- move or rename files
- edit image metadata
- apply presets
- reorganize image files on disk

It only creates Collection Sets and Collections in the active Lightroom catalog.

## Tech Stack

- **Language:** Lua
- **Platform:** Adobe Lightroom Classic SDK
- **Architecture:** modular plugin structure
- **Environment:** Mac and Windows compatible Lightroom Classic workflow

## Project Structure

```text
CSVtoCollections.lrplugin/
├── Info.lua
├── CSVImporter.lua
├── CsvParser.lua
├── CollectionBuilder.lua
├── Utils.lua
├── README.md
├── INSTALLATION.md
├── TEST_PLAN.md
├── CHANGELOG.md
├── CSV Files/
│   └── README.txt
└── Reports/
    └── README.txt
```

## Workflow

1. Load the plugin into Lightroom Classic via Plug-in Manager
2. Place the client CSV file in the plugin's `CSV Files` folder
3. Open `Library > Plug-in Extras > Build Collections from CSV`
4. Select the CSV file
5. Review the preview dialog
6. Click **Create Collections**
7. Review the generated report in the `Reports` folder

## Example Input

```csv
First Name,Surname,Class
Harry,White,Room A
Anna,Smith,Room A
John,Brown,Room B
```

## Example Output in Lightroom

```text
Room A
- HarryWh
- AnnaSm

Room B
- JohnBr
```

## Validation and Reliability

This project includes:

- installation documentation
- usage documentation
- manual test plan
- changelog
- row-level validation behavior
- warnings and error reporting
- idempotent behavior for repeated imports

## Real-World Delivery

This plugin was developed for a real Upwork client request and delivered as a working production-ready solution for their workflow. The client needed a simple but reliable automation that removed repetitive collection setup in Lightroom, and successfully streamlined their workflow.

## Portfolio Notes

This repository is presented as a portfolio case study to demonstrate:

- practical plugin development for Adobe Lightroom Classic
- automation of client workflows
- clean Lua project organization
- defensive CSV parsing and validation
- user-focused error handling and reporting

## License

You can choose one of these approaches before publishing:

- **MIT License** if you want to keep it open for viewing/reuse
- **All Rights Reserved** if you want this repository to serve only as a portfolio showcase

If the code was made specifically for a client and ownership was transferred, confirm that you are allowed to publish the source before making the repository public.

