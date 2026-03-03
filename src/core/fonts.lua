local fontFiles = require("src.data.font_files")

local fonts = {
    cache = {}
}

-- Keep font sizes stable and cache-friendly.
local function normalizeSize(size)
    return math.max(10, math.floor(size))
end

function fonts:get(name, size)
    -- Missing/invalid files fallback to Love's default font.
    local path = fontFiles[name]
    if not path or not love.filesystem.getInfo(path) then
        return love.graphics.getFont()
    end

    local normalized = normalizeSize(size)
    local cacheKey = string.format("%s::%d", name, normalized)

    if self.cache[cacheKey] then
        return self.cache[cacheKey]
    end

    local ok, font = pcall(love.graphics.newFont, path, normalized)
    if not ok then
        return love.graphics.getFont()
    end

    self.cache[cacheKey] = font
    return font
end

return fonts
