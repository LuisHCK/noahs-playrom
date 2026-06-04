local layout = {}

function layout.build(viewport)
    local w = viewport.width
    local h = viewport.height

    local cardW = w * 0.8
    local cardH = h * 0.65
    local cardX = (w - cardW) * 0.5
    local cardY = (h - cardH) * 0.5

    local titleH = h * 0.12
    local dotsH = h * 0.08

    return {
        cardRect = { x = cardX, y = cardY, width = cardW, height = cardH },
        titleRect = { x = 0, y = 0, width = w, height = titleH },
        dotsRect = { x = 0, y = h - dotsH, width = w, height = dotsH },
        toastRect = { x = 0, y = h * 0.45, width = w, height = 40 },
        lastW = w,
        lastH = h
    }
end

return layout
