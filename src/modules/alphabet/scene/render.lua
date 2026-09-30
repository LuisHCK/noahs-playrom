local Spritesheet = require("src.core.spritesheet")

local render = {}
local imageCache = {}
local alphabetSpritesheet = nil
local objectsSpanishSpritesheet = nil

local function getAlphabetSpritesheet()
    -- Lazy-load and reuse the alphabet letter spritesheet.
    if alphabetSpritesheet ~= nil then
        return alphabetSpritesheet
    end

    alphabetSpritesheet = Spritesheet.new({
        path = "assets/images/spritesheets/alphabet-spritesheet.png",
        columns = 1,
        rows = 27,
        spriteWidth = 128,
        spriteHeight = 130
    })

    return alphabetSpritesheet
end

local function getObjectsSpritesheet(language)
    -- Only Spanish object spritesheet exists for now.
    if language ~= "es" then
        return nil
    end

    if objectsSpanishSpritesheet ~= nil then
        return objectsSpanishSpritesheet
    end

    objectsSpanishSpritesheet = Spritesheet.new({
        path = "assets/images/spritesheets/objects-spanish.png",
        columns = 4,
        rows = 7,
        spriteWidth = 125,
        spriteHeight = 115
    })

    return objectsSpanishSpritesheet
end

local function colorFrom(asset)
    if asset and asset.type == "color" then
        return asset.value
    end
    return { 1, 1, 1, 1 }
end

local function getImage(path)
    if not path then
        return nil
    end

    -- Cache decoded images to avoid per-frame reloads.
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

local function fitSizeInRect(contentW, contentH, rectW, rectH)
    -- Fit content into a target box while preserving aspect ratio.
    local scale = math.min(rectW / contentW, rectH / contentH)
    local drawW = contentW * scale
    local drawH = contentH * scale
    local x = (rectW - drawW) * 0.5
    local y = (rectH - drawH) * 0.5
    return x, y, drawW, drawH
end

local function insetRect(rectW, rectH, factor)
    -- Shrink the drawable area (used to make object sprites slightly smaller).
    local width = rectW * factor
    local height = rectH * factor
    local x = (rectW - width) * 0.45
    local y = (rectH - height) * 0.45
    return x, y, width, height
end

function render.draw(state)
    local i18n = state.context.i18n
    local assets = state.context.assets
    local viewport = state.context.viewport
    local content = viewport:getContentArea()
    local moduleData = i18n:getModuleData("alphabet")
    local cardAsset = assets:get("alphabetCard")
    local letterSheet = getAlphabetSpritesheet()
    local objectSheet = getObjectsSpritesheet(state.language)

    local sceneBackground = getImage("assets/images/backgrounds/background-2.jpg")
    if sceneBackground then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sceneBackground, 0, 0, 0, viewport.width / sceneBackground:getWidth(), viewport.height / sceneBackground:getHeight())
    else
        love.graphics.setColor(colorFrom(assets:get("panelBackground")))
        love.graphics.rectangle("fill", 0, 0, viewport.width, viewport.height)
    end

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.printf(moduleData.title or "Alphabet", content.x, content.y + 45, content.width, "center")
    love.graphics.printf(moduleData.subtitle or "", content.x, content.y + 80, content.width, "center")

    local back = state.backButton
    love.graphics.setColor(0.9, 0.85, 0.75, 1)
    love.graphics.rectangle("fill", back.x, back.y, back.width, back.height, 10, 10)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("line", back.x, back.y, back.width, back.height, 10, 10)
    love.graphics.printf(i18n:t("back"), back.x, back.y + 16, back.width, "center")

    for _, card in ipairs(state.cards) do
        local rect = card.rect
        local scaleX = 1
        -- Flip animation scales only on X axis for a card-turn effect.
        if card.flip.active then
            local progress = card.flip.time / card.flip.duration
            if progress < 0.5 then
                scaleX = math.max(0.04, 1 - (progress * 2))
            else
                scaleX = math.max(0.04, (progress - 0.5) * 2)
            end
        end

        local centerX = rect.x + rect.width * 0.5
        local centerY = rect.y + rect.height * 0.5

        love.graphics.push()
        love.graphics.translate(centerX, centerY)
        love.graphics.scale(scaleX, 1)
        love.graphics.translate(-rect.width * 0.5, -rect.height * 0.5)

        -- 
        if cardAsset and cardAsset.type == "image" then
            local image = getImage(cardAsset.path)
            if image then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(image, 0, 0, 0, rect.width / image:getWidth(), rect.height / image:getHeight())
            else
                love.graphics.setColor(0.78, 0.63, 0.45, 1)
                love.graphics.rectangle("fill", 0, 0, rect.width, rect.height, 10, 10)
            end
        else
            love.graphics.setColor(colorFrom(cardAsset))
            love.graphics.rectangle("fill", 0, 0, rect.width, rect.height, 10, 10)
        end

        if card.isFront then
            -- Front side: letter sprite (fallback to text if unavailable).
            local hasSprite = false
            if card.spriteIndex then
                local x, y, drawW, drawH = fitSizeInRect(letterSheet.spriteWidth, letterSheet.spriteHeight, rect.width, rect.height)
                love.graphics.setColor(1, 1, 1, 1)
                hasSprite = letterSheet:drawByIndex(card.spriteIndex, x, y, drawW, drawH)
            end

            if not hasSprite then
                love.graphics.setColor(0.18, 0.14, 0.1, 1)
                love.graphics.printf(card.letter, 0, rect.height * 0.1, rect.width, "center")
            end
        else
            -- Back side: Spanish object sprite (fallback to localized text).
            local hasSprite = false
            if objectSheet and card.spriteIndex then
                local insetX, insetY, insetW, insetH = insetRect(rect.width, rect.height, 0.82)
                local x, y, drawW, drawH = fitSizeInRect(objectSheet.spriteWidth, objectSheet.spriteHeight, insetW, insetH)
                love.graphics.setColor(1, 1, 1, 1)
                hasSprite = objectSheet:drawByIndex(card.spriteIndex, insetX + x, insetY + y, drawW, drawH)
            end

            if not hasSprite then
                love.graphics.setColor(0.18, 0.14, 0.1, 1)
                love.graphics.printf(card.object, 4, rect.height * 0.35, rect.width - 8, "center")
            end
        end

        love.graphics.pop()
    end

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.printf("Tap any card to flip", content.x, content.y + 686, content.width, "center")
end

return render
