local placeholderCard = require("src.ui.placeholder_card")

local render = {}
local imageCache = {}

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

    -- Cache decoded images to avoid reloading every frame.
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

local function drawMenuBackground(asset)
    if asset and asset.type == "image" then
        local image = getImage(asset.path)
        if image then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(image, 0, 0, 0, 1280 / image:getWidth(), 720 / image:getHeight())
            return
        end
    end

    love.graphics.setColor(colorFrom(asset))
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
end

function render.draw(state)
    local context = state.context
    local i18n = context.i18n
    local assets = context.assets

    local backgroundAsset = assets:get("menuBackground")

    drawMenuBackground(backgroundAsset)

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.printf(i18n:t("appTitle"), state.layout.titleX, state.layout.titleY, 1120, "left")

    for _, button in ipairs(state.moduleButtons) do
        -- Map each tile to its dedicated final art asset.
        local moduleAssetKeyById = {
            alphabet = "moduleCardAlphabet",
            animals = "moduleCardAnimals",
            numbers = "moduleCardNumbers",
            universe = "moduleCardUniverse"
        }
        local normal = assets:get(moduleAssetKeyById[button.id] or "moduleCard")

        -- Press feedback: scale around tile center.
        local scale = button.visualScale or 1
        local scaledWidth = button.width * scale
        local scaledHeight = button.height * scale
        local rect = {
            x = button.x + (button.width - scaledWidth) * 0.5,
            y = button.y + (button.height - scaledHeight) * 0.5,
            width = scaledWidth,
            height = scaledHeight
        }

        placeholderCard.draw(
            rect,
            nil,
            nil,
            { normal = normal, pressed = normal },
            false,
            { showText = false }
        )
    end

    local langButton = state.languageButton
    local profileButton = state.profileButton

    love.graphics.setColor(0.9, 0.85, 0.75, 1)
    love.graphics.rectangle("fill", profileButton.x, profileButton.y, profileButton.width, profileButton.height, 10, 10)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("line", profileButton.x, profileButton.y, profileButton.width, profileButton.height, 10, 10)
    love.graphics.printf("Profile", profileButton.x, profileButton.y + 7, profileButton.width, "center")
    love.graphics.printf(assets:getProfile(), profileButton.x, profileButton.y + 24, profileButton.width, "center")

    love.graphics.setColor(0.9, 0.85, 0.75, 1)
    love.graphics.rectangle("fill", langButton.x, langButton.y, langButton.width, langButton.height, 10, 10)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("line", langButton.x, langButton.y, langButton.width, langButton.height, 10, 10)
    love.graphics.printf(i18n:t("languageButton"), langButton.x, langButton.y + 14, langButton.width, "center")
end

return render
