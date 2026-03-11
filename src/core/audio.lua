local audioFiles = require("src.data.audio_files")

local audio = {
    cache = {},
    activeBgm = nil
}

-- Resolve dot-path keys like "alphabet.en.letters.a".
local function walk(node, parts)
    for _, part in ipairs(parts) do
        node = node and node[part]
    end
    return node
end

local function parseKey(key)
    local parts = {}
    for part in string.gmatch(key, "([^.]+)") do
        parts[#parts + 1] = part
    end
    return parts
end

local function resolveNode(key)
    local parts = parseKey(key)

    local node = walk(audioFiles, parts)
    if node ~= nil then
        return node
    end

    -- Fallback pattern: module.lang.* -> module.common.*
    if #parts >= 3 then
        local fallbackParts = { parts[1], "common" }
        for index = 3, #parts do
            fallbackParts[#fallbackParts + 1] = parts[index]
        end
        node = walk(audioFiles, fallbackParts)
    end

    return node
end

local function defaultModeFromKey(key)
    local parts = parseKey(key)
    for _, part in ipairs(parts) do
        if part == "bgm" or part == "music" then
            return "stream"
        end
    end
    return "static" -- best for short SFX/voice.
end

local function normalizeEntry(key, node)
    if type(node) == "string" then
        return {
            path = node,
            mode = defaultModeFromKey(key),
            loop = false,
            volume = 1
        }
    end

    if type(node) == "table" and type(node.path) == "string" then
        return {
            path = node.path,
            mode = node.mode or defaultModeFromKey(key),
            loop = node.loop == true,
            volume = node.volume or 1
        }
    end

    return nil
end

local function getSource(entry)
    -- Cache by mode+path so stream/static variants do not conflict.
    local cacheKey = string.format("%s::%s", entry.mode, entry.path)
    if audio.cache[cacheKey] then
        return audio.cache[cacheKey]
    end

    local path = entry.path
    if not love.filesystem.getInfo(path) then
        -- Try common extensions so mappings can stay stable during swaps.
        local base = path:match("^(.*)%.[^.]+$")
        if base then
            local extensions = { ".ogg", ".wav", ".mp3", ".flac" }
            for _, ext in ipairs(extensions) do
                local candidate = base .. ext
                if love.filesystem.getInfo(candidate) then
                    path = candidate
                    break
                end
            end
        end
    end

    if not love.filesystem.getInfo(path) then
        return nil
    end

    local ok, source = pcall(love.audio.newSource, path, entry.mode)
    if not ok then
        return nil
    end

    source:setLooping(entry.loop)
    source:setVolume(entry.volume)

    audio.cache[cacheKey] = source
    return source
end

function audio:play(key)
    -- `play` is intentionally fire-and-forget for scene simplicity.
    local node = resolveNode(key)
    if not node then
        return false
    end

    local entry = normalizeEntry(key, node)
    if not entry then
        return false
    end

    local source = getSource(entry)
    if not source then
        return false
    end

    -- Keep looping BGM continuous when scenes re-enter and call play again.
    local isBgm = entry.loop and entry.mode == "stream"
    if isBgm then
        if self.activeBgm == source and source:isPlaying() then
            return true
        end

        if self.activeBgm and self.activeBgm ~= source then
            self.activeBgm:stop()
        end

        self.activeBgm = source
    end

    source:stop()
    source:play()
    return true
end

return audio
