local config = require("src.core.config")

local viewport = {
    baseWidth = config.baseWidth,
    baseHeight = config.baseHeight,
    width = config.baseWidth,
    height = config.baseHeight,
    scale = 1,
    offsetX = 0,
    offsetY = 0
}

function viewport:update(windowWidth, windowHeight)
    -- Fill the screen by expanding virtual width/height based on aspect ratio.
    local targetAspect = self.baseWidth / self.baseHeight
    local windowAspect = windowWidth / windowHeight

    if windowAspect >= targetAspect then
        self.scale = windowHeight / self.baseHeight
        self.width = windowWidth / self.scale
        self.height = self.baseHeight
    else
        self.scale = windowWidth / self.baseWidth
        self.width = self.baseWidth
        self.height = windowHeight / self.scale
    end

    self.offsetX = 0
    self.offsetY = 0
end

function viewport:beginDraw()
    love.graphics.clear(0.1, 0.1, 0.12, 1)
    love.graphics.push()
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale, self.scale)
end

function viewport:endDraw()
    love.graphics.pop()
end

function viewport:toVirtual(screenX, screenY)
    -- Map physical pixels into virtual scene coordinates.
    return (screenX - self.offsetX) / self.scale, (screenY - self.offsetY) / self.scale
end

function viewport:getContentArea()
    -- Canonical 16:9 region centered inside the adaptive virtual canvas.
    return {
        x = (self.width - self.baseWidth) * 0.5,
        y = (self.height - self.baseHeight) * 0.5,
        width = self.baseWidth,
        height = self.baseHeight
    }
end

function viewport:isInside(screenX, screenY)
    local vx, vy = self:toVirtual(screenX, screenY)
    return vx >= 0 and vx <= self.width and vy >= 0 and vy <= self.height
end

return viewport
