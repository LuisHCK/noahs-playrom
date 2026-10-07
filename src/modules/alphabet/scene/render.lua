local Spritesheet = require("src.core.spritesheet")
local drawUtils = require("src.ui.draw_utils")
local scene_shell = require("src.core.scene_shell")
local sprites = require("src.data.sprites")

local render = {}
local alphabetSpritesheet = nil
local objectsSpanishSpritesheet = nil

local function getAlphabetSpritesheet()
    -- Lazy-load and reuse the alphabet letter spritesheet.
    if alphabetSpritesheet ~= nil then
        return alphabetSpritesheet
    end

    alphabetSpritesheet = Spritesheet.new(sprites.sheets.alphabet)

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

    objectsSpanishSpritesheet = Spritesheet.new(sprites.sheets.objectsSpanish)

    return objectsSpanishSpritesheet
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

    scene_shell.drawBackground(
        { type = "image", path = "assets/images/backgrounds/background-2.jpg" },
        viewport,
        assets:get("panelBackground")
    )

    scene_shell.drawTitle(moduleData.title or "Alphabet", moduleData.subtitle or "", content, 45, 80)
    scene_shell.drawBackButton(state.backButton, i18n)

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
            local image = drawUtils.getImage(cardAsset.path)
            if image then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(image, 0, 0, 0, rect.width / image:getWidth(), rect.height / image:getHeight())
            else
                love.graphics.setColor(0.78, 0.63, 0.45, 1)
                love.graphics.rectangle("fill", 0, 0, rect.width, rect.height, 10, 10)
            end
        else
            love.graphics.setColor(drawUtils.colorFrom(cardAsset))
            love.graphics.rectangle("fill", 0, 0, rect.width, rect.height, 10, 10)
        end

        if card.isFront then
            -- Front side: letter sprite (fallback to text if unavailable).
            local hasSprite = false
            if card.spriteIndex then
                local x, y, drawW, drawH = drawUtils.fitSizeInRect(letterSheet.spriteWidth, letterSheet.spriteHeight, rect.width, rect.height)
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
                local x, y, drawW, drawH = drawUtils.fitSizeInRect(objectSheet.spriteWidth, objectSheet.spriteHeight, insetW, insetH)
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
