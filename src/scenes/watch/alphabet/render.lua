local Spritesheet = require("src.core.spritesheet")

local render = {}
local alphabetSpritesheet = nil
local objectsSpanishSpritesheet = nil
local BACK_FILL = { 0.9, 0.85, 0.75, 1 }
local BACK_BORDER = { 0.1, 0.1, 0.1, 1 }
local imageCache = {}

local function getImage(path)
    if not path then return nil end
    if imageCache[path] ~= nil then return imageCache[path] end
    if not love.filesystem.getInfo(path) then imageCache[path] = false; return nil end
    local ok, img = pcall(love.graphics.newImage, path)
    imageCache[path] = ok and img or false
    return ok and img or nil
end

local function colorFrom(asset)
    if asset and asset.type == "color" then return asset.value end
    return { 1, 1, 1, 1 }
end

local function getAlphabetSpritesheet()
    if alphabetSpritesheet ~= nil then return alphabetSpritesheet end
    alphabetSpritesheet = Spritesheet.new({
        path = "assets/images/spritesheets/alphabet-spritesheet.png",
        columns = 1, rows = 27, spriteWidth = 128, spriteHeight = 130
    })
    return alphabetSpritesheet
end

local function getObjectsSpritesheet(language)
    if language ~= "es" then return nil end
    if objectsSpanishSpritesheet ~= nil then return objectsSpanishSpritesheet end
    objectsSpanishSpritesheet = Spritesheet.new({
        path = "assets/images/spritesheets/objects-spanish.png",
        columns = 4, rows = 7, spriteWidth = 125, spriteHeight = 115
    })
    return objectsSpanishSpritesheet
end

local function fitSizeInRect(contentW, contentH, rectW, rectH)
    local scale = math.min(rectW / contentW, rectH / contentH)
    return (rectW - contentW * scale) * 0.5, (rectH - contentH * scale) * 0.5, contentW * scale, contentH * scale
end

local function insetRect(rectW, rectH, factor)
    local w = rectW * factor
    local h = rectH * factor
    return (rectW - w) * 0.45, (rectH - h) * 0.45, w, h
end

local function wrapIndex(index, total)
    return ((index - 1 + total) % total) + 1
end

function render.draw(stateObj, layout)
    local viewport = stateObj.context.viewport
    local assets = stateObj.context.assets
    local total = #stateObj.deck
    local cardRect = layout.cardRect
    local letterSheet = getAlphabetSpritesheet()
    local objectSheet = getObjectsSpritesheet(stateObj.language)
    local cardBgAsset = assets:get("alphabetCard")

    -- Background.
    love.graphics.setColor(0.96, 0.93, 0.87, 1)
    love.graphics.rectangle("fill", 0, 0, viewport.width, viewport.height)

    -- Back button.
    local bb = layout.backButton
    love.graphics.setColor(BACK_FILL)
    love.graphics.rectangle("fill", bb.x, bb.y, bb.width, bb.height, 8, 8)
    love.graphics.setColor(BACK_BORDER)
    love.graphics.rectangle("line", bb.x, bb.y, bb.width, bb.height, 8, 8)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.printf("←", bb.x, bb.y + 10, bb.width, "center")

    -- Compute slide offset for card.
    local slideOffset = 0
    if stateObj.swipeAnim.active then
        slideOffset = stateObj.swipeAnim.progress * viewport.width * stateObj.swipeAnim.direction * -1
    elseif stateObj.touchCurrentX then
        slideOffset = stateObj.touchCurrentX - stateObj.touchStartX
    end

    -- Draw adjacent cards for peek during swipe.
    for _, offset in ipairs({ -1, 0, 1 }) do
        local idx = wrapIndex(stateObj.currentIndex + offset, total)
        local c = stateObj.deck[idx]
        local cx = cardRect.x + offset * viewport.width + slideOffset
        local cy = cardRect.y

        if idx == stateObj.currentIndex then
            -- Current card: everything flips together inside the transform.
            local scaleX = 1
            if stateObj.flip.active then
                local progress = stateObj.flip.time / stateObj.flip.duration
                if progress < 0.5 then
                    scaleX = math.max(0.04, 1 - (progress * 2))
                else
                    scaleX = math.max(0.04, (progress - 0.5) * 2)
                end
            end

            local centerX = cx + cardRect.width * 0.5
            local centerY = cy + cardRect.height * 0.5

            love.graphics.push()
            love.graphics.translate(centerX, centerY)
            love.graphics.scale(scaleX, 1)
            love.graphics.translate(-cardRect.width * 0.5, -cardRect.height * 0.5)

            -- Card background.
            if cardBgAsset and cardBgAsset.type == "image" then
                local image = getImage(cardBgAsset.path)
                if image then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(image, 0, 0, 0, cardRect.width / image:getWidth(), cardRect.height / image:getHeight())
                else
                    love.graphics.setColor(colorFrom(cardBgAsset))
                    love.graphics.rectangle("fill", 0, 0, cardRect.width, cardRect.height, 10, 10)
                end
            else
                love.graphics.setColor(colorFrom(cardBgAsset))
                love.graphics.rectangle("fill", 0, 0, cardRect.width, cardRect.height, 10, 10)
            end

            if c.isFront then
                local hasSprite = false
                if c.spriteIndex then
                    local x, y, dw, dh = fitSizeInRect(letterSheet.spriteWidth, letterSheet.spriteHeight, cardRect.width, cardRect.height)
                    love.graphics.setColor(1, 1, 1, 1)
                    hasSprite = letterSheet:drawByIndex(c.spriteIndex, x, y, dw, dh)
                end
                if not hasSprite then
                    love.graphics.setColor(0.18, 0.14, 0.1, 1)
                    love.graphics.printf(c.letter, 0, cardRect.height * 0.1, cardRect.width, "center")
                end
            else
                local hasSprite = false
                if objectSheet and c.spriteIndex then
                    local insX, insY, insW, insH = insetRect(cardRect.width, cardRect.height, 0.82)
                    local x, y, dw, dh = fitSizeInRect(objectSheet.spriteWidth, objectSheet.spriteHeight, insW, insH)
                    love.graphics.setColor(1, 1, 1, 1)
                    hasSprite = objectSheet:drawByIndex(c.spriteIndex, insX + x, insY + y, dw, dh)
                end
                if not hasSprite then
                    love.graphics.setColor(0.18, 0.14, 0.1, 1)
                    love.graphics.printf(c.object, 4, cardRect.height * 0.35, cardRect.width - 8, "center")
                end
            end

            love.graphics.pop()
        else
            -- Peek card: background only.
            if cardBgAsset and cardBgAsset.type == "image" then
                local image = getImage(cardBgAsset.path)
                if image then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(image, cx, cy, 0, cardRect.width / image:getWidth(), cardRect.height / image:getHeight())
                else
                    love.graphics.setColor(colorFrom(cardBgAsset))
                    love.graphics.rectangle("fill", cx, cy, cardRect.width, cardRect.height, 10, 10)
                end
            else
                love.graphics.setColor(colorFrom(cardBgAsset))
                love.graphics.rectangle("fill", cx, cy, cardRect.width, cardRect.height, 10, 10)
            end
        end
    end

    -- Indicator: "N / 27".
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.printf(stateObj.currentIndex .. " / " .. total, layout.indicatorRect.x, layout.indicatorRect.y, layout.indicatorRect.width, "center")
end

return render
