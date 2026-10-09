local audioFiles = require("src.data.audio_files")

local audio = {
    cache = {},
    activeBgm = nil,
    volume = 1,
    sequence = nil
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
        return audio.cache[cacheKey].source
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

    audio.cache[cacheKey] = { source = source, baseVolume = entry.volume }
    return source
end

local DEFAULT_SEQUENCE_GAP = 0.12
audio.sequenceGap = DEFAULT_SEQUENCE_GAP

-- Play several keys back-to-back (used to stitch voice clips). Missing clips are
-- skipped. Replaces any sequence already in flight.
function audio:playSequence(keys, gap)
    if self.sequence then
        for _, item in ipairs(self.sequence.items) do
            if item.played then
                item.source:stop()
            end
        end
    end

    gap = gap or DEFAULT_SEQUENCE_GAP
    local items = {}
    local at = 0

    for _, entry in ipairs(keys) do
        -- A number inserts a silent pause (seconds) before the next clip.
        if type(entry) == "number" then
            at = at + entry
        else
            local node = resolveNode(entry)
            local config = node and normalizeEntry(entry, node) or nil
            local source = config and getSource(config) or nil
            if source then
                source:setVolume(config.volume * self.volume)
                local duration = 0.6
                local ok, value = pcall(source.getDuration, source)
                if ok and type(value) == "number" then
                    duration = value
                end
                items[#items + 1] = { source = source, at = at, played = false }
                at = at + duration + gap
            end
        end
    end

    if #items == 0 then
        self.sequence = nil
        return false
    end

    self.sequence = { items = items, elapsed = 0, total = at }
    return true
end

function audio:update(dt)
    local sequence = self.sequence
    if not sequence then
        return
    end

    sequence.elapsed = sequence.elapsed + dt
    for _, item in ipairs(sequence.items) do
        if not item.played and sequence.elapsed >= item.at then
            item.source:stop()
            item.source:play()
            item.played = true
        end
    end

    if sequence.elapsed >= sequence.total then
        self.sequence = nil
    end
end

function audio:getDuration(key)
    local node = resolveNode(key)
    local entry = node and normalizeEntry(key, node) or nil
    local source = entry and getSource(entry) or nil
    if not source then
        return 0
    end

    local ok, value = pcall(source.getDuration, source)
    if ok and type(value) == "number" then
        return value
    end
    return 0
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

    -- Apply global volume multiplier.
    source:setVolume(entry.volume * self.volume)

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

function audio:setVolume(v)
    self.volume = math.max(0, math.min(1, v))
    -- Update all cached sources so currently playing audio responds immediately.
    for _, item in pairs(self.cache) do
        item.source:setVolume(item.baseVolume * self.volume)
    end
end

function audio:getVolume()
    return self.volume
end

return audio
