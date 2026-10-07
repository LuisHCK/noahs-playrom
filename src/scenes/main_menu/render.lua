local placeholderCard = require("src.ui.placeholder_card")
local drawUtils = require("src.ui.draw_utils")

local render = {}

local function drawMenuBackground(asset, viewport)
    if asset and asset.type == "image" then
        local image = drawUtils.getImage(asset.path)
        if image then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(image, 0, 0, 0, viewport.width / image:getWidth(), viewport.height / image:getHeight())
            return
        end
    end

    love.graphics.setColor(drawUtils.colorFrom(asset))
    love.graphics.rectangle("fill", 0, 0, viewport.width, viewport.height)
end

function render.draw(state)
    local context = state.context
    local i18n = context.i18n
    local assets = context.assets
    local viewport = context.viewport
    local content = viewport:getContentArea()

    local backgroundAsset = assets:get("menuBackground")

    drawMenuBackground(backgroundAsset, viewport)

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.printf(i18n:t("appTitle"), state.layout.titleX, state.layout.titleY, content.width, "left")

    for _, button in ipairs(state.moduleButtons) do
        local normal = assets:get(button.assetKey or "moduleCard")

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

    love.graphics.setColor(0.9, 0.85, 0.75, 1)
    love.graphics.rectangle("fill", langButton.x, langButton.y, langButton.width, langButton.height, 10, 10)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("line", langButton.x, langButton.y, langButton.width, langButton.height, 10, 10)
    love.graphics.printf(i18n:t("languageButton"), langButton.x, langButton.y + 14, langButton.width, "center")
end

return render
