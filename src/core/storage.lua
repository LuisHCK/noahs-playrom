local storage = {}

local saveFile = "settings.lua"

-- Guard against malformed or incompatible save files.
local function safeLoadTable(chunk)
    local ok, result = pcall(chunk)
    if not ok or type(result) ~= "table" then
        return {}
    end
    return result
end

function storage:load()
    if not love.filesystem.getInfo(saveFile) then
        return {}
    end

    local chunk = love.filesystem.load(saveFile)
    if not chunk then
        return {}
    end

    return safeLoadTable(chunk)
end

local function serializeValue(value)
    local valueType = type(value)
    if valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end
    return string.format("%q", tostring(value))
end

function storage:save(data)
    -- Keep save format minimal and human-readable for quick debugging.
    -- Flat scalar keys only; legacy files with the old field set still load.
    local keys = {}
    for key, value in pairs(data) do
        local valueType = type(value)
        if valueType == "string" or valueType == "number" or valueType == "boolean" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)

    local parts = {}
    for _, key in ipairs(keys) do
        parts[#parts + 1] = string.format("[%q] = %s", key, serializeValue(data[key]))
    end

    love.filesystem.write(saveFile, "return { " .. table.concat(parts, ", ") .. " }")
end

return storage
