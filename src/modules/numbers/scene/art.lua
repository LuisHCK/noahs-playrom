local Spritesheet = require("src.core.spritesheet")
local sprites = require("src.data.sprites")
local config = require("src.modules.numbers.content.config")

local art = {}

local cardsSheet = nil
local dotsSheet = nil
local fontCache = {}

local CARD_FILL = { 0.84, 0.70, 0.50, 1 }
local CARD_BORDER = { 0.42, 0.30, 0.20, 1 }
local DOTS_CARD_FILL = { 0.93, 0.89, 0.81, 1 }
local DOTS_CARD_BORDER = { 0.55, 0.42, 0.30, 1 }
local DIGIT_COLOR = { 0.20, 0.14, 0.10, 1 }
local DOT_COLOR = { 0.43, 0.29, 0.18, 1 }

local function getFont(size)
    local normalized = math.max(10, math.floor(size))
    if not fontCache[normalized] then
        fontCache[normalized] = love.graphics.newFont(normalized)
    end
    return fontCache[normalized]
end

function art.font(size)
    return getFont(size)
end

local function getCardsSheet()
    if not cardsSheet then
        cardsSheet = Spritesheet.new(sprites.sheets.numbersCards)
    end
    return cardsSheet
end

local function getDotsSheet()
    if not dotsSheet then
        dotsSheet = Spritesheet.new(sprites.sheets.numbersDots)
    end
    return dotsSheet
end

function art.number(rect, value)
    local sheet = getCardsSheet()
    if sheet.image then
        love.graphics.setColor(1, 1, 1, 1)
        if sheet:drawByIndex(value, rect.x, rect.y, rect.width, rect.height) then
            return
        end
    end

    love.graphics.setColor(CARD_FILL)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 14, 14)
    love.graphics.setColor(CARD_BORDER)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 14, 14)

    local size = rect.height * 0.6
    love.graphics.setFont(getFont(size))
    love.graphics.setColor(DIGIT_COLOR)
    local textY = rect.y + rect.height * 0.5 - size * 0.62
    love.graphics.printf(tostring(value), rect.x, textY, rect.width, "center")
end

function art.dots(rect, count)
    local sheet = getDotsSheet()
    if sheet.image then
        love.graphics.setColor(1, 1, 1, 1)
        if sheet:drawByIndex(count, rect.x, rect.y, rect.width, rect.height) then
            return
        end
    end

    love.graphics.setColor(DOTS_CARD_FILL)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 12, 12)
    love.graphics.setColor(DOTS_CARD_BORDER)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 12, 12)

    local pad = 8
    local columns = config.dotColumns
    local rows = math.max(1, math.ceil(count / columns))
    local innerW = rect.width - pad * 2
    local innerH = rect.height - pad * 2
    local cellW = innerW / columns
    local cellH = innerH / rows
    local radius = math.min(cellW, cellH) * 0.34

    for slot = 1, count do
        local row = math.floor((slot - 1) / columns)
        local column = (slot - 1) % columns
        local cx = rect.x + pad + column * cellW + cellW * 0.5
        local cy = rect.y + pad + row * cellH + cellH * 0.5
        love.graphics.setColor(DOT_COLOR)
        love.graphics.circle("fill", cx, cy, radius)
    end
end

return art
