local config = require("src.modules.farm.content.config")

local layout = {}

function layout.build(viewport)
    local content = viewport:getContentArea()

    local barH = config.modeBarHeight
    local bw, bh = 180, barH - 16
    local gap = 16
    local order = { "explore", "learn", "find" }
    local barW = #order * bw + (#order - 1) * gap
    local barX = content.x + (content.width - barW) * 0.5
    local barY = content.y + 16

    local buttons = {}
    for index, id in ipairs(order) do
        buttons[id] = {
            id = id,
            x = barX + (index - 1) * (bw + gap),
            y = barY + 8,
            width = bw,
            height = bh
        }
    end

    local bannerW = 640
    local bannerH = 120
    local banner = {
        x = content.x + (content.width - bannerW) * 0.5,
        y = content.y + content.height - bannerH - 28,
        width = bannerW,
        height = bannerH
    }

    return {
        content = content,
        groundY = config.groundY,
        modeBar = {
            x = barX,
            y = barY,
            width = barW,
            height = barH,
            order = order,
            buttons = buttons
        },
        banner = banner,
        lastW = viewport.width,
        lastH = viewport.height
    }
end

return layout
