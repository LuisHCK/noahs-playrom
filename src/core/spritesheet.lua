local Spritesheet = {}
Spritesheet.__index = Spritesheet

function Spritesheet.new(config)
    -- Config expects: path, spriteWidth, spriteHeight, columns, rows.
    local self = setmetatable({}, Spritesheet)

    self.path = config.path
    self.spriteWidth = config.spriteWidth
    self.spriteHeight = config.spriteHeight
    self.columns = config.columns
    self.rows = config.rows
    self.image = nil
    self.quads = {}

    -- Keep object valid even if image is missing; callers can fallback.
    if not self.path or not love.filesystem.getInfo(self.path) then
        return self
    end

    local ok, image = pcall(love.graphics.newImage, self.path)
    if not ok then
        return self
    end

    self.image = image
    local imageWidth, imageHeight = image:getDimensions()

    -- Build quads in row-major order: left->right, top->bottom.
    local index = 1
    for row = 1, self.rows do
        for column = 1, self.columns do
            local x = (column - 1) * self.spriteWidth
            local y = (row - 1) * self.spriteHeight
            self.quads[index] = love.graphics.newQuad(
                x,
                y,
                self.spriteWidth,
                self.spriteHeight,
                imageWidth,
                imageHeight
            )
            index = index + 1
        end
    end

    return self
end

function Spritesheet:getQuadByIndex(index)
    -- 1-based linear lookup.
    return self.quads[index]
end

function Spritesheet:getQuad(row, column)
    -- Convert row/column to the same row-major linear index.
    local index = (row - 1) * self.columns + column
    return self.quads[index]
end

function Spritesheet:drawByIndex(index, x, y, width, height)
    if not self.image then
        return false
    end

    local quad = self:getQuadByIndex(index)
    if not quad then
        return false
    end

    -- Optional width/height draw target; defaults to native sprite size.
    local sx = (width or self.spriteWidth) / self.spriteWidth
    local sy = (height or self.spriteHeight) / self.spriteHeight

    love.graphics.draw(self.image, quad, x, y, 0, sx, sy)
    return true
end

function Spritesheet:draw(row, column, x, y, width, height)
    local quad = self:getQuad(row, column)
    if not self.image or not quad then
        return false
    end

    -- Same scaling behavior as drawByIndex.
    local sx = (width or self.spriteWidth) / self.spriteWidth
    local sy = (height or self.spriteHeight) / self.spriteHeight

    love.graphics.draw(self.image, quad, x, y, 0, sx, sy)
    return true
end

return Spritesheet
