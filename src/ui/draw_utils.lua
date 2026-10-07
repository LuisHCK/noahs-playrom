local images = require("src.core.images")

local drawUtils = {}

function drawUtils.getImage(path)
    return images.get(path)
end

function drawUtils.contains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width
        and y >= rect.y and y <= rect.y + rect.height
end

function drawUtils.colorFrom(asset)
    if asset and asset.type == "color" then return asset.value end
    return { 1, 1, 1, 1 }
end

function drawUtils.fitSizeInRect(contentW, contentH, rectW, rectH)
    local scale = math.min(rectW / contentW, rectH / contentH)
    return (rectW - contentW * scale) * 0.5, (rectH - contentH * scale) * 0.5, contentW * scale, contentH * scale
end

function drawUtils.drawAssetToRect(asset, rect, radius)
    if asset and asset.type == "image" then
        local image = images.get(asset.path)
        if image then
            local x, y, dw, dh = drawUtils.fitSizeInRect(image:getWidth(), image:getHeight(), rect.width, rect.height)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(image, rect.x + x, rect.y + y, 0, dw / image:getWidth(), dh / image:getHeight())
            return
        end
    end
    love.graphics.setColor(drawUtils.colorFrom(asset))
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, radius or 0, radius or 0)
end

return drawUtils
