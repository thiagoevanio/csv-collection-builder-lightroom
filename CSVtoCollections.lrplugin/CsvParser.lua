---@diagnostic disable: undefined-global

local function loadUtilsModule()
    local ok, module = pcall(require, "Utils")
    if ok and module then
        return module
    end

    if type(import) == "function" then
        ok, module = pcall(import, "Utils")
        if ok and module then
            return module
        end
    end

    error("Unable to load internal module: Utils")
end

local Utils = loadUtilsModule()

local CsvParser = {}

local DELIMITER_CANDIDATES = { ",", ";", "\t" }

local function isRowEmpty(values)
    for _, value in ipairs(values or {}) do
        if Utils.trim(value) ~= "" then
            return false
        end
    end

    return true
end

local function extractFirstRecord(text)
    local inQuotes = false
    local buffer = {}
    local i = 1

    while i <= #text do
        local ch = text:sub(i, i)

        if ch == "\"" then
            local nextCh = text:sub(i + 1, i + 1)
            if inQuotes and nextCh == "\"" then
                table.insert(buffer, ch)
                table.insert(buffer, nextCh)
                i = i + 1
            else
                inQuotes = not inQuotes
                table.insert(buffer, ch)
            end
        elseif (ch == "\n" or ch == "\r") and not inQuotes then
            break
        else
            table.insert(buffer, ch)
        end

        i = i + 1
    end

    return table.concat(buffer)
end

local function countDelimiterOutsideQuotes(line, delimiter)
    local count = 0
    local inQuotes = false
    local i = 1

    while i <= #line do
        local ch = line:sub(i, i)

        if ch == "\"" then
            local nextCh = line:sub(i + 1, i + 1)
            if inQuotes and nextCh == "\"" then
                i = i + 1
            else
                inQuotes = not inQuotes
            end
        elseif not inQuotes and ch == delimiter then
            count = count + 1
        end

        i = i + 1
    end

    return count
end

local function detectDelimiter(text)
    local firstRecord = extractFirstRecord(text)
    local bestDelimiter = ","
    local bestScore = -1

    for _, delimiter in ipairs(DELIMITER_CANDIDATES) do
        local score = countDelimiterOutsideQuotes(firstRecord, delimiter)
        if score > bestScore then
            bestScore = score
            bestDelimiter = delimiter
        end
    end

    return bestDelimiter
end

local function parseRecords(text, delimiter, errors)
    local records = {}
    local currentFieldChars = {}
    local currentRecord = {}
    local inQuotes = false
    local lineNumber = 1
    local recordStartLine = 1

    local function pushField()
        local fieldValue = table.concat(currentFieldChars)
        table.insert(currentRecord, Utils.trim(fieldValue))
        currentFieldChars = {}
    end

    local function pushRecord()
        pushField()
        table.insert(records, {
            values = currentRecord,
            lineNumber = recordStartLine,
        })
        currentRecord = {}
        recordStartLine = lineNumber + 1
    end

    local i = 1
    while i <= #text do
        local ch = text:sub(i, i)

        if inQuotes then
            if ch == "\"" then
                local nextCh = text:sub(i + 1, i + 1)
                if nextCh == "\"" then
                    table.insert(currentFieldChars, "\"")
                    i = i + 1
                else
                    inQuotes = false
                end
            else
                table.insert(currentFieldChars, ch)
                if ch == "\n" then
                    lineNumber = lineNumber + 1
                end
            end
        else
            if ch == "\"" then
                local currentValue = table.concat(currentFieldChars)
                if currentValue:match("^%s*$") then
                    currentFieldChars = {}
                    inQuotes = true
                else
                    table.insert(currentFieldChars, ch)
                end
            elseif ch == delimiter then
                pushField()
            elseif ch == "\r" then
                local nextCh = text:sub(i + 1, i + 1)
                if nextCh == "\n" then
                    i = i + 1
                end
                pushRecord()
                lineNumber = lineNumber + 1
            elseif ch == "\n" then
                pushRecord()
                lineNumber = lineNumber + 1
            else
                table.insert(currentFieldChars, ch)
            end
        end

        i = i + 1
    end

    if inQuotes then
        table.insert(errors, "Malformed CSV data. A quoted field was not properly closed.")
    end

    if #currentRecord > 0 or #currentFieldChars > 0 then
        pushRecord()
    end

    return records
end

function CsvParser.parseText(text)
    local result = {
        headers = {},
        rows = {},
        errors = {},
        warnings = {},
        delimiter = ",",
        bomDetected = false,
        totalRowsRead = 0,
        emptyRowsSkipped = 0,
    }

    if text == nil or text == "" then
        table.insert(result.errors, "The selected CSV file is empty.")
        return result
    end

    text, result.bomDetected = Utils.stripUtf8Bom(text)
    result.delimiter = detectDelimiter(text)

    local allRows = parseRecords(text, result.delimiter, result.errors)
    if #result.errors > 0 then
        return result
    end

    if #allRows == 0 then
        table.insert(result.errors, "The selected CSV file is empty.")
        return result
    end

    local headerRowIndex = nil
    for index, row in ipairs(allRows) do
        if not isRowEmpty(row.values) then
            headerRowIndex = index
            break
        end
    end

    if not headerRowIndex then
        table.insert(result.errors, "CSV header row was not found.")
        return result
    end

    result.headers = allRows[headerRowIndex].values
    local headerCount = #result.headers

    if headerCount == 0 or isRowEmpty(result.headers) then
        table.insert(result.errors, "CSV header row was not found.")
        return result
    end

    for index = headerRowIndex + 1, #allRows do
        local row = allRows[index]
        local values = row.values
        result.totalRowsRead = result.totalRowsRead + 1

        if #values < headerCount then
            for padIndex = #values + 1, headerCount do
                values[padIndex] = ""
            end
            table.insert(result.warnings, string.format("Row %d has fewer columns than expected. Missing values were treated as empty.", row.lineNumber))
        elseif #values > headerCount then
            table.insert(result.warnings, string.format("Row %d has extra columns. Extra values were ignored.", row.lineNumber))
        end

        local normalizedValues = {}
        for valueIndex = 1, headerCount do
            normalizedValues[valueIndex] = values[valueIndex] or ""
        end

        if isRowEmpty(normalizedValues) then
            result.emptyRowsSkipped = result.emptyRowsSkipped + 1
            table.insert(result.warnings, string.format("Row %d was ignored because it is empty.", row.lineNumber))
        else
            table.insert(result.rows, {
                values = normalizedValues,
                lineNumber = row.lineNumber,
            })
        end
    end

    return result
end

function CsvParser.parseFile(path)
    local result = {
        headers = {},
        rows = {},
        errors = {},
        warnings = {},
        delimiter = ",",
        bomDetected = false,
        totalRowsRead = 0,
        emptyRowsSkipped = 0,
    }

    if not path or path == "" then
        table.insert(result.errors, "No CSV file was selected.")
        return result
    end

    local content, err = Utils.readFile(path)
    if not content then
        table.insert(result.errors, "The CSV file could not be opened for reading.")
        return result
    end

    if content == "" then
        table.insert(result.errors, "The selected CSV file is empty.")
        return result
    end

    return CsvParser.parseText(content)
end

return CsvParser
