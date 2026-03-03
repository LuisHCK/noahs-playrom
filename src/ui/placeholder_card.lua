local placeholderCard = {}
local imageCache = {}

local function getImage(path)
    if not path then
        return nil
    end

    if imageCache[path] ~= nil then
        return imageCache[path]
    end

    if not love.filesystem.getInfo(path) then
        imageCache[path] = false
        return nil
    end

    local ok, image = pcall(love.graphics.newImage, path)
    imageCache[path] = ok and image or false
    return ok and image or nil
end

local function drawFill(rect, asset, fallbackColor)
    if asset and asset.type == "image" then
        local image = getImage(asset.path)
        if image then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                image,
                rect.x,
                rect.y,
                0,
                rect.width / image:getWidth(),
                rect.height / image:getHeight()
            )
            return
        end
    end

    if asset and asset.type == "color" then
        love.graphics.setColor(asset.value)
    else
        love.graphics.setColor(fallbackColor)
    end

    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 16, 16)
end

function placeholderCard.draw(rect, title, subtitle, assetsByState, isPressed, options)
    options = options or {}
    local fillAsset = isPressed and assetsByState.pressed or assetsByState.normal
    local fallback = isPressed and { 0.68, 0.53, 0.35, 1 } or { 0.78, 0.63, 0.45, 1 }
    drawFill(rect, fillAsset, fallback)

    if options.showText ~= false then
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.printf(title or "", rect.x + 12, rect.y + rect.height * 0.35, rect.width - 24, "center")
        love.graphics.printf(subtitle or "", rect.x + 12, rect.y + rect.height * 0.6, rect.width - 24, "center")
    end
end

return placeholderCard
