---@diagnostic disable: undefined-global

local LrTasks = import "LrTasks"

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

local CollectionBuilder = {}

local function buildCatalogIndex(catalog)
    local setsByName = {}
    local collectionsBySet = {}

    local topLevelSets = catalog:getChildCollectionSets() or {}
    for _, setObj in ipairs(topLevelSets) do
        local setName = Utils.sanitizeCollectionName(setObj:getName())
        if setName ~= "" then
            setsByName[setName] = setObj
            collectionsBySet[setName] = {}

            local childCollections = setObj:getChildCollections() or {}
            for _, collectionObj in ipairs(childCollections) do
                local collectionName = Utils.sanitizeCollectionName(collectionObj:getName())
                if collectionName ~= "" then
                    collectionsBySet[setName][collectionName] = collectionObj
                end
            end
        end
    end

    return setsByName, collectionsBySet
end

function CollectionBuilder.analyzePlan(catalog, entries)
    local analysis = {
        collectionSetsToCreate = 0,
        collectionSetsExisting = 0,
        collectionsToCreate = 0,
        collectionsExisting = 0,
    }

    local setsByName, collectionsBySet = buildCatalogIndex(catalog)
    local countedSets = {}
    local countedCollections = {}

    for _, entry in ipairs(entries or {}) do
        if not countedSets[entry.setName] then
            countedSets[entry.setName] = true
            if setsByName[entry.setName] then
                analysis.collectionSetsExisting = analysis.collectionSetsExisting + 1
            else
                analysis.collectionSetsToCreate = analysis.collectionSetsToCreate + 1
            end
        end

        local key = entry.setName .. "\0" .. entry.collectionName
        if not countedCollections[key] then
            countedCollections[key] = true
            if collectionsBySet[entry.setName] and collectionsBySet[entry.setName][entry.collectionName] then
                analysis.collectionsExisting = analysis.collectionsExisting + 1
            else
                analysis.collectionsToCreate = analysis.collectionsToCreate + 1
            end
        end
    end

    return analysis
end

function CollectionBuilder.applyPlan(catalog, entries)
    local result = {
        success = true,
        collectionSetsCreated = 0,
        collectionSetsExisting = 0,
        collectionsCreated = 0,
        collectionsExisting = 0,
        details = {},
        errors = {},
    }

    local function writeCatalogChanges()
        catalog:withWriteAccessDo("CSV Collection Builder Import", function()
            local setsByName, collectionsBySet = buildCatalogIndex(catalog)
            local countedSets = {}
            local countedCollections = {}

            for _, entry in ipairs(entries or {}) do
                local setName = entry.setName
                local collectionName = entry.collectionName

                local setObj = setsByName[setName]
                if not setObj then
                    setObj = catalog:createCollectionSet(setName, nil, true)
                    setsByName[setName] = setObj
                    collectionsBySet[setName] = collectionsBySet[setName] or {}

                    if not countedSets[setName] then
                        countedSets[setName] = true
                        result.collectionSetsCreated = result.collectionSetsCreated + 1
                    end
                elseif not countedSets[setName] then
                    countedSets[setName] = true
                    result.collectionSetsExisting = result.collectionSetsExisting + 1
                end

                local collectionKey = setName .. "\0" .. collectionName
                if not countedCollections[collectionKey] then
                    countedCollections[collectionKey] = true
                    local existingCollection = collectionsBySet[setName] and collectionsBySet[setName][collectionName]

                    if existingCollection then
                        result.collectionsExisting = result.collectionsExisting + 1
                        table.insert(result.details, string.format("%s > %s - Already existed", setName, collectionName))
                    else
                        local newCollection = catalog:createCollection(collectionName, setObj, true)
                        collectionsBySet[setName][collectionName] = newCollection
                        result.collectionsCreated = result.collectionsCreated + 1
                        table.insert(result.details, string.format("%s > %s - Created", setName, collectionName))
                    end
                end
            end
        end)
    end

    if LrTasks and LrTasks.pcall then
        local ok, catalogError = LrTasks.pcall(writeCatalogChanges)
        if not ok then
            result.success = false
            table.insert(result.errors, "Could not write changes to the Lightroom catalog. Please make sure the catalog is writable and try again. Details: " .. tostring(catalogError))
        end
    else
        -- Do not wrap Lightroom catalog writes in native pcall; it can break yielding calls.
        writeCatalogChanges()
    end

    return result
end

return CollectionBuilder
