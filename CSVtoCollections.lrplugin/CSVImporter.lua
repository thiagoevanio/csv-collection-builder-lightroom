---@diagnostic disable: undefined-global, need-check-nil

local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrFunctionContext = import "LrFunctionContext"
local LrPathUtils = import "LrPathUtils"
local LrTasks = import "LrTasks"
local LrView = import "LrView"

local moduleLoadErrors = {}
local lastCsvPath = nil

local function extendPackagePath()
    if _PLUGIN and _PLUGIN.path and LrPathUtils and LrPathUtils.child then
        local pluginPattern = LrPathUtils.child(_PLUGIN.path, "?.lua")
        if package and package.path and not package.path:find(pluginPattern, 1, true) then
            package.path = pluginPattern .. ";" .. package.path
        end
    end
end

extendPackagePath()

local function loadLocalModule(moduleName)
    local ok, loadedModule = pcall(require, moduleName)
    if ok and loadedModule then
        return loadedModule
    end

    table.insert(moduleLoadErrors, string.format("require('%s') failed: %s", moduleName, tostring(loadedModule)))

    if type(import) == "function" then
        ok, loadedModule = pcall(import, moduleName)
        if ok and loadedModule then
            return loadedModule
        end
        table.insert(moduleLoadErrors, string.format("import('%s') failed: %s", moduleName, tostring(loadedModule)))
    end

    return nil
end

local CollectionBuilder = loadLocalModule("CollectionBuilder") or {}
local CsvParser = loadLocalModule("CsvParser") or {}
local Utils = loadLocalModule("Utils") or {}

local modulesReady =
    CollectionBuilder and
    CollectionBuilder.analyzePlan and
    CollectionBuilder.applyPlan and
    CsvParser and
    CsvParser.parseFile and
    Utils.timestampCompact and
    Utils.timestampReadable and
    Utils.getParentDirectory and
    Utils.joinPath and
    Utils.getWorkspacePaths and
    Utils.ensureDirectory and
    Utils.writeFile and
    Utils.fileExists and
    Utils.newAliasLookup and
    Utils.resolveRequiredHeaders and
    Utils.normalizeSpaces and
    Utils.sanitizeCollectionName and
    Utils.buildCollectionName

local HEADER_ALIASES = {
    firstName = {
        "First Name",
        "FirstName",
        "Forename",
        "Name",
        "Child First Name",
        "Child's First Name",
    },
    surname = {
        "Surname",
        "Last Name",
        "LastName",
        "Family Name",
        "Child's Surname",
    },
    className = {
        "Class",
        "Room",
        "Classroom",
        "Group",
        "Child's Class",
        "The Class That They Are In",
    },
}

local PREVIEW_LIMIT = 12

local function buildPreviewText(entries)
    if #entries == 0 then
        return "No valid rows found."
    end

    local lines = {}
    local limit = math.min(#entries, PREVIEW_LIMIT)

    for i = 1, limit do
        local entry = entries[i]
        table.insert(lines, string.format("%s > %s", entry.setName, entry.collectionName))
    end

    if #entries > PREVIEW_LIMIT then
        table.insert(lines, string.format("... and %d more", #entries - PREVIEW_LIMIT))
    end

    return table.concat(lines, "\n")
end

local function showPreviewDialog(summary, previewText)
    local dialogResult = "cancel"

    LrFunctionContext.callWithContext("csvPreviewDialog", function()
        local f = LrView.osFactory()

        -- Keep this preview UI intentionally simple. Some Lightroom Classic
        -- versions are sensitive to edit fields/bindings inside plugin modals.
        local contents = f:column {
            spacing = f:control_spacing(),

            f:static_text { title = string.format("Total rows read: %d", summary.totalRowsRead), width_in_chars = 78 },
            f:static_text { title = string.format("Valid rows: %d", summary.validRows), width_in_chars = 78 },
            f:static_text { title = string.format("Rows with warnings/errors: %d", summary.rowsWithIssues), width_in_chars = 78 },
            f:static_text { title = string.format("Collection Sets to create: %d", summary.collectionSetsToCreate), width_in_chars = 78 },
            f:static_text { title = string.format("Collection Sets already existing: %d", summary.collectionSetsExisting), width_in_chars = 78 },
            f:static_text { title = string.format("Collections to create: %d", summary.collectionsToCreate), width_in_chars = 78 },
            f:static_text { title = string.format("Collections already existing: %d", summary.collectionsExisting), width_in_chars = 78 },

            f:static_text { title = "", width_in_chars = 78 },
            f:static_text { title = "Preview:", width_in_chars = 78 },
            f:static_text { title = previewText, width_in_chars = 78, height_in_lines = 14 },
        }

        dialogResult = LrDialogs.presentModalDialog {
            title = "CSV Preview",
            contents = contents,
            actionVerb = "Create Collections",
            cancelVerb = "Cancel",
        }
    end)

    return dialogResult == "ok"
end

local function buildReportText(report)
    local lines = {
        "CSV Collection Builder Import Report",
        "Generated at: " .. Utils.timestampReadable(),
        "CSV file: " .. report.csvFile,
        "",
        "Summary:",
        "- Total rows read: " .. report.summary.totalRowsRead,
        "- Valid rows: " .. report.summary.validRows,
        "- Skipped rows: " .. report.summary.skippedRows,
        "- Collection sets created: " .. report.summary.collectionSetsCreated,
        "- Collection sets already existing: " .. report.summary.collectionSetsExisting,
        "- Collections created: " .. report.summary.collectionsCreated,
        "- Collections already existing: " .. report.summary.collectionsExisting,
        "",
        "Warnings:",
    }

    if #report.warnings == 0 then
        table.insert(lines, "- None")
    else
        for _, warning in ipairs(report.warnings) do
            table.insert(lines, "- " .. warning)
        end
    end

    table.insert(lines, "")
    table.insert(lines, "Errors:")

    if #report.errors == 0 then
        table.insert(lines, "- None")
    else
        for _, err in ipairs(report.errors) do
            table.insert(lines, "- " .. err)
        end
    end

    table.insert(lines, "")
    table.insert(lines, "Details:")

    if #report.details == 0 then
        table.insert(lines, "- None")
    else
        for _, detail in ipairs(report.details) do
            table.insert(lines, "- " .. detail)
        end
    end

    return table.concat(lines, "\n")
end

local function saveReport(reportText)
    local workspacePaths = Utils.getWorkspacePaths()
    if not workspacePaths or not workspacePaths.reportsDirectory then
        return false, nil
    end

    local reportsReady = Utils.ensureDirectory(workspacePaths.reportsDirectory)
    if not reportsReady then
        return false, nil
    end

    local reportName = "CSVCollectionBuilder_Report_" .. Utils.timestampCompact() .. ".txt"
    local reportPath = Utils.joinPath(workspacePaths.reportsDirectory, reportName)
    local ok = Utils.writeFile(reportPath, reportText)

    if not ok then
        return false, nil
    end

    return true, reportPath
end

local function saveErrorLog(errorText)
    if not modulesReady or not lastCsvPath or lastCsvPath == "" then
        return nil
    end

    local workspacePaths = Utils.getWorkspacePaths()
    if not workspacePaths or not workspacePaths.reportsDirectory then
        return nil
    end

    local reportsReady = Utils.ensureDirectory(workspacePaths.reportsDirectory)
    if not reportsReady then
        return nil
    end

    local errorName = "CSVCollectionBuilder_Error_" .. Utils.timestampCompact() .. ".txt"
    local errorPath = Utils.joinPath(workspacePaths.reportsDirectory, errorName)
    local ok = Utils.writeFile(errorPath, errorText)

    if ok then
        return errorPath
    end

    return nil
end

local function prepareEntries(parseResult, headerIndices)
    local entries = {}
    local warnings = {}
    local errors = {}
    local seenTargets = {}
    local issueRows = {}

    local validRows = 0
    local skippedRows = 0

    local function markIssue(lineNumber)
        if lineNumber then
            issueRows[lineNumber] = true
        end
    end

    for _, row in ipairs(parseResult.rows) do
        local firstName = Utils.normalizeSpaces(row.values[headerIndices.firstName] or "")
        local surname = Utils.normalizeSpaces(row.values[headerIndices.surname] or "")
        local className = Utils.sanitizeCollectionName(row.values[headerIndices.className] or "")

        if firstName == "" then
            skippedRows = skippedRows + 1
            table.insert(warnings, string.format("Row %d skipped: missing First Name.", row.lineNumber))
            markIssue(row.lineNumber)
        elseif className == "" then
            skippedRows = skippedRows + 1
            table.insert(warnings, string.format("Row %d skipped: missing Class.", row.lineNumber))
            markIssue(row.lineNumber)
        else
            local collectionName, shortSurname = Utils.buildCollectionName(firstName, surname)
            if collectionName == "" then
                skippedRows = skippedRows + 1
                table.insert(errors, string.format("Row %d skipped: could not generate a valid collection name.", row.lineNumber))
                markIssue(row.lineNumber)
            else
                if surname == "" then
                    table.insert(warnings, string.format("Row %d: Surname is empty. Collection name was generated from First Name only.", row.lineNumber))
                    markIssue(row.lineNumber)
                elseif shortSurname then
                    table.insert(warnings, string.format("Row %d: Surname has fewer than 2 characters.", row.lineNumber))
                    markIssue(row.lineNumber)
                end

                local key = className .. "\0" .. collectionName
                if seenTargets[key] then
                    skippedRows = skippedRows + 1
                    table.insert(warnings, string.format("Row %d skipped: duplicate target %s > %s.", row.lineNumber, className, collectionName))
                    markIssue(row.lineNumber)
                else
                    seenTargets[key] = true
                    validRows = validRows + 1
                    table.insert(entries, {
                        lineNumber = row.lineNumber,
                        setName = className,
                        collectionName = collectionName,
                    })
                end
            end
        end
    end

    local rowsWithIssues = 0
    for _ in pairs(issueRows) do
        rowsWithIssues = rowsWithIssues + 1
    end

    return {
        entries = entries,
        warnings = warnings,
        errors = errors,
        issueRows = issueRows,
        rowsWithIssues = rowsWithIssues,
        validRows = validRows,
        skippedRows = skippedRows + parseResult.emptyRowsSkipped,
        totalRowsRead = parseResult.totalRowsRead,
    }
end

local function showError(title, body)
    LrDialogs.message(title, body, "critical")
end

local function runImport()
    if not modulesReady then
        local details = "One or more internal plugin files could not be loaded. Please reinstall CSVtoCollections.lrplugin."
        if #moduleLoadErrors > 0 then
            details = details .. "\n\nDiagnostic details:\n" .. table.concat(moduleLoadErrors, "\n")
        end
        showError("Plugin configuration error", details)
        return
    end

    local workspacePaths = Utils.getWorkspacePaths()
    local csvDirectoryReady = false
    if workspacePaths and workspacePaths.csvDirectory then
        csvDirectoryReady = Utils.ensureDirectory(workspacePaths.csvDirectory)
    end
    if workspacePaths and workspacePaths.reportsDirectory then
        Utils.ensureDirectory(workspacePaths.reportsDirectory)
    end

    local selectedPaths = LrDialogs.runOpenPanel {
            title = "Select CSV File",
            prompt = "Select CSV",
        canChooseFiles = true,
        canChooseDirectories = false,
        allowsMultipleSelection = false,
        fileTypes = { "csv", "txt" },
        initialDirectory = workspacePaths and workspacePaths.csvDirectory or nil,
    }

    if not selectedPaths or #selectedPaths == 0 then
        LrDialogs.message("Import canceled", "No CSV file was selected.", "info")
        return
    end

    local csvPath = selectedPaths[1]
    lastCsvPath = csvPath

    if not Utils.fileExists(csvPath) then
        showError("CSV file not found", "The selected CSV file could not be found.")
        return
    end

    local parseResult = CsvParser.parseFile(csvPath)

    if #parseResult.errors > 0 then
        showError("CSV validation failed", parseResult.errors[1])
        return
    end

    if #parseResult.headers == 0 then
        showError("CSV validation failed", "CSV header row was not found.")
        return
    end

    local aliasLookup = Utils.newAliasLookup(HEADER_ALIASES)
    local headerIndices = Utils.resolveRequiredHeaders(parseResult.headers, aliasLookup)

    local missingHeaders = {}
    if not headerIndices.firstName then
        table.insert(missingHeaders, "First Name")
    end
    if not headerIndices.surname then
        table.insert(missingHeaders, "Surname")
    end
    if not headerIndices.className then
        table.insert(missingHeaders, "Class")
    end

    if #missingHeaders > 0 then
        local missingText = table.concat(missingHeaders, ", ")
        showError("CSV validation failed", "Missing required column(s): " .. missingText .. ".")
        return
    end

    local prepared = prepareEntries(parseResult, headerIndices)

    local allWarnings = {}
    local parserIssueRows = {}
    if parseResult.bomDetected then
        table.insert(allWarnings, "UTF-8 BOM was detected and removed.")
    end
    for _, parserWarning in ipairs(parseResult.warnings) do
        table.insert(allWarnings, parserWarning)
        local rowNumber = tonumber(parserWarning:match("^Row%s+(%d+)"))
        if rowNumber then
            parserIssueRows[rowNumber] = true
        end
    end
    for _, warning in ipairs(prepared.warnings) do
        table.insert(allWarnings, warning)
    end

    local allErrors = {}
    for _, err in ipairs(prepared.errors) do
        table.insert(allErrors, err)
    end

    local catalog = LrApplication.activeCatalog()
    local analysis = CollectionBuilder.analyzePlan(catalog, prepared.entries)

    local issueRows = {}
    for rowNumber in pairs(prepared.issueRows) do
        issueRows[rowNumber] = true
    end
    for rowNumber in pairs(parserIssueRows) do
        issueRows[rowNumber] = true
    end

    local rowsWithIssues = 0
    for _ in pairs(issueRows) do
        rowsWithIssues = rowsWithIssues + 1
    end

    if rowsWithIssues == 0 and (#allWarnings + #allErrors) > 0 then
        rowsWithIssues = #allWarnings + #allErrors
    end

    local shouldContinue = showPreviewDialog({
        totalRowsRead = prepared.totalRowsRead,
        validRows = prepared.validRows,
        rowsWithIssues = rowsWithIssues,
        collectionSetsToCreate = analysis.collectionSetsToCreate,
        collectionSetsExisting = analysis.collectionSetsExisting,
        collectionsToCreate = analysis.collectionsToCreate,
        collectionsExisting = analysis.collectionsExisting,
    }, buildPreviewText(prepared.entries))

    if not shouldContinue then
        LrDialogs.message("Import canceled", "No changes were made to the catalog.", "info")
        return
    end

    local buildResult = {
        success = true,
        collectionSetsCreated = 0,
        collectionSetsExisting = 0,
        collectionsCreated = 0,
        collectionsExisting = 0,
        details = {},
        errors = {},
    }

    if #prepared.entries > 0 then
        buildResult = CollectionBuilder.applyPlan(catalog, prepared.entries)
        if not buildResult.success then
            table.insert(allErrors, "Could not complete catalog updates.")
        end
    end

    for _, buildError in ipairs(buildResult.errors) do
        table.insert(allErrors, buildError)
    end

    local report = {
        csvFile = csvPath,
        summary = {
            totalRowsRead = prepared.totalRowsRead,
            validRows = prepared.validRows,
            skippedRows = prepared.skippedRows,
            collectionSetsCreated = buildResult.collectionSetsCreated,
            collectionSetsExisting = buildResult.collectionSetsExisting,
            collectionsCreated = buildResult.collectionsCreated,
            collectionsExisting = buildResult.collectionsExisting,
        },
        warnings = allWarnings,
        errors = allErrors,
        details = buildResult.details,
    }

    local reportText = buildReportText(report)
    local reportSaved, reportPath = saveReport(reportText)

    local messageBody
    if #allErrors > 0 then
        messageBody = "The import completed with errors. Please review the report."
    elseif prepared.skippedRows > 0 or #allWarnings > 0 then
        messageBody = "Import completed. Some rows were skipped. Please review the report."
    else
        messageBody = "Import completed successfully."
    end

    if reportSaved then
        messageBody = messageBody .. "\n\nReport: " .. reportPath
    else
        messageBody = messageBody .. "\n\nThe report could not be saved in the Reports folder."
    end

    if workspacePaths and workspacePaths.csvDirectory and csvDirectoryReady then
        messageBody = messageBody .. "\nCSV folder: " .. workspacePaths.csvDirectory
    end

    if #allErrors > 0 then
        LrDialogs.message("Import completed with errors", messageBody, "warning")
    else
        LrDialogs.message("Import completed", messageBody, "info")
    end
end

local function showUnexpectedError(err)
    local errorText = "CSV Collection Builder Error Report\nGenerated at: "
    if modulesReady then
        errorText = errorText .. Utils.timestampReadable()
    else
        errorText = errorText .. os.date("%Y-%m-%d %H:%M:%S")
    end
    errorText = errorText .. "\n\n" .. tostring(err)

    local errorPath = saveErrorLog(errorText)
    local body = "The import could not be completed due to an unexpected error."
        .. "\n\nTechnical details:\n" .. tostring(err)

    if errorPath then
        body = body .. "\n\nError log: " .. errorPath
    end

    LrDialogs.message("Import failed", body, "critical")
end

LrTasks.startAsyncTask(function()
    -- Important: do not use Lua's native pcall/xpcall around Lightroom UI/catalog calls.
    -- Some Lightroom SDK calls yield internally, and native pcall in the embedded Lua
    -- environment can trigger: "Yielding is not allowed within a C or metamethod call".
    -- LrTasks.pcall is the Lightroom-safe protected call that permits yielding.
    if LrTasks and LrTasks.pcall then
        local ok, err = LrTasks.pcall(runImport)
        if not ok then
            showUnexpectedError(err)
        end
    else
        -- Fallback: run directly rather than wrapping in native pcall, because native
        -- pcall can break Lightroom dialogs.
        runImport()
    end
end)
