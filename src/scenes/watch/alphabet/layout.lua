local layout = {}

function layout.build(viewport)
    local w = viewport.width
    local h = viewport.height

    local backSize = 120
    local backX = 8
    local backY = 8

    local indicatorH = 90
    local cardPadding = 12
    local cardY = backY + backSize + 14
    local cardH = h - cardY - indicatorH - 14

    return {
        backButton = { x = backX, y = backY, width = backSize, height = backSize },
        cardRect = { x = cardPadding, y = cardY, width = w - cardPadding * 2, height = cardH },
        indicatorRect = { x = 0, y = h - indicatorH - 8, width = w, height = indicatorH },
        lastW = w,
        lastH = h
    }
end

return layout
