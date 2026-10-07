local manifest = require("src.data.modules_manifest")

local modules = {}
local cache = nil

local function defaultCardAssetKey(id)
    return "moduleCard" .. id:sub(1, 1):upper() .. id:sub(2)
end

local function normalize(descriptor)
    return {
        id = descriptor.id,
        enabled = descriptor.enabled ~= false,
        scene = descriptor.scene,
        scenePath = descriptor.scenePath,
        cardAssetKey = descriptor.cardAssetKey or defaultCardAssetKey(descriptor.id),
        audioPrefix = descriptor.audioPrefix or descriptor.id
    }
end

local function load()
    if cache then
        return cache
    end

    cache = {}
    local seen = {}

    for _, path in ipairs(manifest) do
        local descriptor = require(path)
        assert(type(descriptor) == "table", "Module manifest entry '" .. path .. "' did not return a table")
        assert(type(descriptor.id) == "string", "Module '" .. path .. "' is missing an id")
        assert(type(descriptor.scene) == "string", "Module '" .. descriptor.id .. "' is missing a scene key")
        assert(type(descriptor.scenePath) == "string", "Module '" .. descriptor.id .. "' is missing a scenePath")
        assert(not seen[descriptor.id], "Duplicate module id '" .. descriptor.id .. "'")
        seen[descriptor.id] = true

        cache[#cache + 1] = normalize(descriptor)
    end

    return cache
end

function modules.list()
    return load()
end

function modules.get(id)
    for _, descriptor in ipairs(load()) do
        if descriptor.id == id then
            return descriptor
        end
    end
    return nil
end

function modules.sceneEntries()
    local entries = {}
    for _, descriptor in ipairs(load()) do
        entries[#entries + 1] = { path = descriptor.scenePath, key = descriptor.scene }
    end
    return entries
end

return modules
