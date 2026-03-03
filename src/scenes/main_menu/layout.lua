local layout = {}

function layout.build()
    -- Area reserved for the 2x2 game tiles.
    local menuRect = {
        x = 100,
        y = 150,
        width = 1080,
        height = 500
    }

    local gap = 36
    -- Tile target ratio: 2:1.
    local ratioWidth = 2
    local ratioHeight = 1

    -- Fit two tiles + one gap per row/column inside menuRect.
    local maxCardWidthByArea = (menuRect.width - gap) / 2
    local maxCardHeightByArea = (menuRect.height - gap) / 2
    -- If width is limiting, derive max height from 2:1: h = w * (1/2).
    local maxCardHeightByWidth = maxCardWidthByArea * (ratioHeight / ratioWidth)
    -- Final size keeps both bounds while preserving 2:1.
    local cardHeight = math.min(maxCardHeightByArea, maxCardHeightByWidth)
    local cardWidth = cardHeight * (ratioWidth / ratioHeight)

    -- Center the full 2x2 tile block in the menu area.
    local totalWidth = cardWidth * 2 + gap
    local totalHeight = cardHeight * 2 + gap
    local startX = menuRect.x + (menuRect.width - totalWidth) * 0.5
    local startY = menuRect.y + (menuRect.height - totalHeight) * 0.5

    return {
        titleX = 80,
        titleY = 50,
        profileButton = {
            x = 970,
            y = 40,
            width = 140,
            height = 48
        },
        languageButton = {
            x = 1120,
            y = 40,
            width = 90,
            height = 48
        },
        moduleSlots = {
            { x = startX, y = startY, width = cardWidth, height = cardHeight },
            { x = startX + cardWidth + gap, y = startY, width = cardWidth, height = cardHeight },
            { x = startX, y = startY + cardHeight + gap, width = cardWidth, height = cardHeight },
            { x = startX + cardWidth + gap, y = startY + cardHeight + gap, width = cardWidth, height = cardHeight }
        }
    }
end

return layout
