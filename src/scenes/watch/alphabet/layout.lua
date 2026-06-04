local layout = {}

function layout.build(viewport)
    local w = viewport.width
    local h = viewport.height
    local edge = 10

    local backSize = 44
    local backX = edge
    local backY = edge

    local indicatorH = 20
    local cardY = backY + backSize + 8
    local cardH = h - cardY - indicatorH - 8

    return {
        backButton = { x = backX, y = backY, width = backSize, height = backSize },
        cardRect = { x = edge, y = cardY, width = w - edge * 2, height = cardH },
        indicatorRect = { x = 0, y = h - indicatorH - 4, width = w, height = indicatorH },
        lastW = w,
        lastH = h
    }
end

return layout
