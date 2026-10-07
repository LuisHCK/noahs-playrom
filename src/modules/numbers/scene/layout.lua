local config = require("src.modules.numbers.content.config")

local layout = {}

function layout.build(viewport)
    local content = viewport:getContentArea()

    local headerH = 96
    local bottomReserve = 84
    local rows = config.stageSize
    local sideMargin = 300
    local numberW, numberH = 87, 92
    local dotsW, dotsH = 160, 92

    local numberX = content.x + sideMargin
    local dotsX = content.x + content.width - sideMargin - dotsW

    local boardTop = content.y + headerH
    local boardH = content.height - headerH - bottomReserve
    local rowGap = rows > 1 and (boardH - rows * numberH) / (rows - 1) or 0

    local numberSlots = {}
    local dotsSlots = {}

    for row = 1, rows do
        local y = boardTop + (row - 1) * (numberH + rowGap)
        numberSlots[row] = { x = numberX, y = y, width = numberW, height = numberH }
        dotsSlots[row] = { x = dotsX, y = y, width = dotsW, height = dotsH }
    end

    return {
        content = content,
        numberSize = { w = numberW, h = numberH },
        dotsSize = { w = dotsW, h = dotsH },
        numberSlots = numberSlots,
        dotsSlots = dotsSlots,
        progressY = content.y + content.height - 46,
        lastW = viewport.width,
        lastH = viewport.height
    }
end

return layout
