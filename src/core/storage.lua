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

function storage:save(data)
    -- Keep save format minimal and human-readable for quick debugging.
    local encoded = string.format(
        "return { language = %q, assetProfile = %q }",
        data.language or "en",
        data.assetProfile or "prototype"
    )

    love.filesystem.write(saveFile, encoded)
end

return storage
