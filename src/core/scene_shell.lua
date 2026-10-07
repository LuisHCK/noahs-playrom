local Button = require("src.ui.button")
local drawUtils = require("src.ui.draw_utils")

local scene_shell = {}

local EDGE_MARGIN = 32
local BACK_FILL = { 0.9, 0.85, 0.75, 1 }
local BACK_BORDER = { 0.1, 0.1, 0.1, 1 }
local TEXT_COLOR = { 0.1, 0.1, 0.1, 1 }

function scene_shell.buildBackButton(onClick, opts)
    opts = opts or {}
    return Button.new({
        id = "back",
        x = opts.x or EDGE_MARGIN,
        y = opts.y or EDGE_MARGIN,
        width = opts.width or 140,
        height = opts.height or 50,
        onClick = onClick
    })
end

function scene_shell.drawBackButton(backButton, i18n)
    love.graphics.setColor(BACK_FILL)
    love.graphics.rectangle("fill", backButton.x, backButton.y, backButton.width, backButton.height, 10, 10)
    love.graphics.setColor(BACK_BORDER)
    love.graphics.rectangle("line", backButton.x, backButton.y, backButton.width, backButton.height, 10, 10)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.printf(i18n:t("back"), backButton.x, backButton.y + backButton.height * 0.32, backButton.width, "center")
end

function scene_shell.drawBackground(asset, viewport, fallbackAsset)
    if asset and asset.type == "image" then
        local image = drawUtils.getImage(asset.path)
        if image then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(image, 0, 0, 0, viewport.width / image:getWidth(), viewport.height / image:getHeight())
            return
        end
    end

    local resolved = (asset and asset.type == "color") and asset or fallbackAsset
    love.graphics.setColor(drawUtils.colorFrom(resolved))
    love.graphics.rectangle("fill", 0, 0, viewport.width, viewport.height)
end

function scene_shell.drawTitle(title, subtitle, content, titleOffset, subtitleOffset)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.printf(title or "", content.x, content.y + (titleOffset or 45), content.width, "center")
    love.graphics.printf(subtitle or "", content.x, content.y + (subtitleOffset or 80), content.width, "center")
end

return scene_shell
