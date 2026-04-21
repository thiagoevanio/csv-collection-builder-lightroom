---@diagnostic disable: undefined-global

local Utils = {}

local function safeImport(moduleName)
    if type(import) ~= "function" then
        return nil
    end

    local ok, module = pcall(import, moduleName)
    if ok then
        return module
    end

    return nil
end

local LrPathUtils = safeImport("LrPathUtils")
local LrFileUtils = safeImport("LrFileUtils")
local UTF8_CHAR_PATTERN = "[%z\1-\127\194-\244][\128-\191]*"

function Utils.trim(value)
    if value == nil then
        return ""
    end

    local text = tostring(value)
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

function Utils.isBlank(value)
    return Utils.trim(value) == ""
end

function Utils.normalizeSpaces(value)
    local text = Utils.trim(value)
    text = text:gsub("[%z\1-\31\127]", " ")
    text = text:gsub("%s+", " ")
    return Utils.trim(text)
end

function Utils.normalizeHeader(value)
    local text = Utils.normalizeSpaces(value):lower()
    text = text:gsub("[_%-%s]+", "")
    text = text:gsub("[^%w]", "")
    return text
end

function Utils.stripUtf8Bom(text)
    if text == nil or text == "" then
        return text or "", false
    end

    local bom = string.char(239, 187, 191)
    if text:sub(1, 3) == bom then
        return text:sub(4), true
    end

    return text, false
end

function Utils.sanitizeCollectionName(value)
    local text = Utils.normalizeSpaces(value)
    text = text:gsub("[/\\:<>|%*%?]", " ")
    text = text:gsub("%s+", " ")
    return Utils.trim(text)
end

function Utils.getSurnameCode(surname)
    local clean = Utils.normalizeSpaces(surname)
    if clean == "" then
        return "", true
    end

    local compact = clean:gsub("%s+", "")
    compact = compact:gsub("[^%w\128-\255]", "")
    if compact == "" then
        compact = clean:gsub("%s+", "")
    end

    local codeChars = {}
    for char in compact:gmatch(UTF8_CHAR_PATTERN) do
        table.insert(codeChars, char)
        if #codeChars >= 2 then
            break
        end
    end

    local code = table.concat(codeChars)
    local isShort = #codeChars < 2
    return code, isShort
end

function Utils.buildCollectionName(firstName, surname)
    local first = Utils.normalizeSpaces(firstName)
    first = first:gsub("%s+", "")

    local surnameCode, isShortSurname = Utils.getSurnameCode(surname)
    local collectionName = Utils.sanitizeCollectionName(first .. surnameCode)
    return collectionName, isShortSurname
end

function Utils.timestampCompact()
    return os.date("%Y%m%d_%H%M%S")
end

function Utils.timestampReadable()
    return os.date("%Y-%m-%d %H:%M:%S")
end

function Utils.joinLines(lines)
    return table.concat(lines or {}, "\n")
end

function Utils.getParentDirectory(filePath)
    if not filePath then
        return nil
    end

    if LrPathUtils and LrPathUtils.parent then
        return LrPathUtils.parent(filePath)
    end

    local normalized = tostring(filePath):gsub("\\", "/")
    return normalized:match("^(.*)/[^/]*$")
end

function Utils.joinPath(parentPath, childName)
    if not parentPath or parentPath == "" then
        return childName
    end

    if LrPathUtils and LrPathUtils.child then
        return LrPathUtils.child(parentPath, childName)
    end

    if parentPath:sub(-1) == "/" or parentPath:sub(-1) == "\\" then
        return parentPath .. childName
    end

    local separator = "/"
    if parentPath:match("\\") then
        separator = "\\"
    end
    return parentPath .. separator .. childName
end

function Utils.getLeafName(path)
    if not path then
        return ""
    end

    local normalized = tostring(path):gsub("[/\\]+$", "")
    return normalized:match("([^/\\]+)$") or normalized
end

function Utils.getPluginDirectory()
    if _PLUGIN and _PLUGIN.path and _PLUGIN.path ~= "" then
        return _PLUGIN.path
    end

    if debug and debug.getinfo then
        local source = debug.getinfo(1, "S")
        if source and source.source then
            local scriptPath = source.source:gsub("^@", "")
            local pluginDirectory = Utils.getParentDirectory(scriptPath)
            if pluginDirectory and pluginDirectory ~= "" then
                return pluginDirectory
            end
        end
    end

    return nil
end

function Utils.getWorkspacePaths()
    local rootDirectory = Utils.getPluginDirectory()
    if not rootDirectory or rootDirectory == "" then
        return nil
    end

    local csvFolderName = "CSV Files"
    local reportsFolderName = "Reports"

    return {
        rootDirectory = rootDirectory,
        csvDirectory = Utils.joinPath(rootDirectory, csvFolderName),
        reportsDirectory = Utils.joinPath(rootDirectory, reportsFolderName),
    }
end

function Utils.ensureDirectory(path)
    if not path or path == "" then
        return false, "Directory path was empty."
    end

    if Utils.fileExists(path) then
        return true
    end

    if LrFileUtils and LrFileUtils.createAllDirectories then
        local ok, result = pcall(LrFileUtils.createAllDirectories, path)
        if ok and (result == nil or result == true or result == 0) then
            return true
        end
        if Utils.fileExists(path) then
            return true
        end
        if not ok then
            return false, tostring(result)
        end
    end

    local command
    local separator = package and package.config and package.config:sub(1, 1) or "/"
    if separator == "\\" then
        command = string.format('mkdir "%s" >NUL 2>NUL', tostring(path))
    else
        local escaped = tostring(path):gsub('"', '\\"')
        command = string.format('mkdir -p "%s" >/dev/null 2>&1', escaped)
    end

    local result = os.execute(command)
    if result == true or result == 0 then
        return true
    end

    if Utils.fileExists(path) then
        return true
    end

    return false, "Could not create directory."
end

function Utils.fileExists(path)
    if LrFileUtils and LrFileUtils.exists then
        return LrFileUtils.exists(path)
    end

    local handle = io.open(path, "rb")
    if not handle then
        return false
    end

    handle:close()
    return true
end

function Utils.readFile(path)
    local handle, err = io.open(path, "rb")
    if not handle then
        return nil, err
    end

    local content = handle:read("*a")
    handle:close()
    return content
end

function Utils.writeFile(path, content)
    local handle, err = io.open(path, "w")
    if not handle then
        return false, err
    end

    handle:write(content or "")
    handle:close()
    return true
end

function Utils.newAliasLookup(definitions)
    local lookup = {}

    for key, aliases in pairs(definitions or {}) do
        lookup[key] = {}
        for _, alias in ipairs(aliases) do
            lookup[key][Utils.normalizeHeader(alias)] = true
        end
    end

    return lookup
end

function Utils.resolveRequiredHeaders(headers, aliasLookup)
    local indices = {}

    for index, header in ipairs(headers or {}) do
        local normalized = Utils.normalizeHeader(header)
        for key, lookup in pairs(aliasLookup or {}) do
            if not indices[key] and lookup[normalized] then
                indices[key] = index
            end
        end
    end

    return indices
end

return Utils
