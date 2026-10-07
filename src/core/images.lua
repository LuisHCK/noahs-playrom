local images = {}

local cache = {}

function images.get(path)
    if not path then
        return nil
    end

    local cached = cache[path]
    if cached ~= nil then
        return cached or nil
    end

    if not love.filesystem.getInfo(path) then
        cache[path] = false
        return nil
    end

    local ok, image = pcall(love.graphics.newImage, path)
    cache[path] = ok and image or false
    return ok and image or nil
end

function images.clear()
    cache = {}
end

return images
