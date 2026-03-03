local config = require("src.core.config")

local viewport = {
    width = config.baseWidth,
    height = config.baseHeight,
    scale = 1,
    offsetX = 0,
    offsetY = 0
}

function viewport:update(windowWidth, windowHeight)
    -- Preserve 16:9 virtual space with letterboxing.
    self.scale = math.min(windowWidth / self.width, windowHeight / self.height)
    self.offsetX = math.floor((windowWidth - self.width * self.scale) * 0.5)
    self.offsetY = math.floor((windowHeight - self.height * self.scale) * 0.5)
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

function viewport:isInside(screenX, screenY)
    local vx, vy = self:toVirtual(screenX, screenY)
    return vx >= 0 and vx <= self.width and vy >= 0 and vy <= self.height
end

return viewport
