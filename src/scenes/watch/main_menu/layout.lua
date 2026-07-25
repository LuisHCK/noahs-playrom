local layout = {}

function layout.build(viewport)
    local w = viewport.width
    local h = viewport.height

    local cardW = w * 0.8
    local cardH = h * 0.5
    local textAreaH = h * 0.065
    local gap = h * 0.015
    local combinedH = cardH + gap + textAreaH
    local startY = (h - combinedH) * 0.5
    local cardX = (w - cardW) * 0.5
    local cardY = startY
    local textY = startY + cardH + gap

    local titleH = h * 0.12
    local dotsH = h * 0.08

    local btnSize = 120
    return {
        cardRect = { x = cardX, y = cardY, width = cardW, height = cardH },
        cardTextRect = { x = cardX, y = textY, width = cardW, height = textAreaH },
        titleRect = { x = 0, y = 0, width = w, height = titleH },
        dotsRect = { x = 0, y = h - dotsH, width = w, height = dotsH },
        toastRect = { x = 0, y = h * 0.45, width = w, height = 40 },
        settingsButton = { x = w - btnSize - 8, y = 8, width = btnSize, height = btnSize },
        lastW = w,
        lastH = h
    }
end

return layout
