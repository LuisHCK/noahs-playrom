local layout = {}

function layout.build(viewport)
    local w = viewport.width
    local h = viewport.height
    local margin = 12

    local backSize = 52
    local backX = margin
    local backY = margin

    local indicatorH = 28
    local cardPadding = 16
    local cardY = backY + backSize + 10
    local cardH = h - cardY - indicatorH - cardPadding

    return {
        backButton = { x = backX, y = backY, width = backSize, height = backSize },
        cardRect = { x = margin + cardPadding, y = cardY, width = w - (margin + cardPadding) * 2, height = cardH },
        indicatorRect = { x = 0, y = h - indicatorH - 6, width = w, height = indicatorH },
        lastW = w,
        lastH = h
    }
end

return layout
