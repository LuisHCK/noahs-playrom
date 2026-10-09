local Spritesheet = require("src.core.spritesheet")
local images = require("src.core.images")
local assets = require("src.core.assets")
local sprites = require("src.data.sprites")

local art = {}

local animalsSheet = nil
local structuresSheet = nil
local fontCache = {}

local STRUCTURE_INDEX = {
    barn = 1,
    stable = 2,
    coop = 3,
    pond = 4,
    mudPen = 5,
    field = 6,
    doghouse = 7,
    cottage = 8,
    windmill = 9
}

-- Animals drawn from a single dedicated image (asset key) instead of the sheet.
local ANIMAL_IMAGE_KEYS = {
    cow = "farmCow",
    horse = "farmHorse",
    hen = "farmHen",
    rooster = "farmRooster",
    duck = "farmDuck",
    pig = "farmPig",
    sheep = "farmSheep",
    dog = "farmDog",
    cat = "farmCat"
}

-- Structures drawn from a single dedicated image (asset key) instead of the sheet.
local STRUCTURE_IMAGE_KEYS = {
    barn = "farmBarn",
    stable = "farmStable",
    coop = "farmCoop",
    pond = "farmPond",
    mudPen = "farmMudPen",
    field = "farmField",
    doghouse = "farmDoghouse",
    cottage = "farmCottage",
    windmill = "farmWindmill"
}

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

local function getAnimalsSheet()
    if not animalsSheet then
        animalsSheet = Spritesheet.new(sprites.sheets.farmAnimals)
    end
    return animalsSheet
end

local function getStructuresSheet()
    if not structuresSheet then
        structuresSheet = Spritesheet.new(sprites.sheets.farmStructures)
    end
    return structuresSheet
end

local function drawSpriteFit(sheet, index, rect)
    local quad = sheet:getQuadByIndex(index)
    if not quad then
        return false
    end

    local scale = math.min(rect.width / sheet.spriteWidth, rect.height / sheet.spriteHeight)
    local drawWidth = sheet.spriteWidth * scale
    local drawHeight = sheet.spriteHeight * scale
    local x = rect.x + (rect.width - drawWidth) * 0.5
    local y = rect.y + rect.height - drawHeight

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sheet.image, quad, x, y, 0, scale, scale)
    return true
end

local function drawImageFit(image, rect)
    local imageWidth, imageHeight = image:getDimensions()
    local scale = math.min(rect.width / imageWidth, rect.height / imageHeight)
    local drawWidth = imageWidth * scale
    local drawHeight = imageHeight * scale
    local x = rect.x + (rect.width - drawWidth) * 0.5
    local y = rect.y + rect.height - drawHeight

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, x, y, 0, scale, scale)
    return true
end

function art.animal(rect, key)
    local imageKey = ANIMAL_IMAGE_KEYS[key]
    if imageKey then
        local asset = assets:get(imageKey)
        local image = asset and asset.type == "image" and images.get(asset.path) or nil
        if image and drawImageFit(image, rect) then
            return
        end
    end

    local sheet = getAnimalsSheet()
    if sheet.image then
        local index = sprites.farmIndexByKey[key]
        if index and drawSpriteFit(sheet, index, rect) then
            return
        end
    end
end

function art.structure(rect, kind)
    local imageKey = STRUCTURE_IMAGE_KEYS[kind]
    if imageKey then
        local asset = assets:get(imageKey)
        local image = asset and asset.type == "image" and images.get(asset.path) or nil
        if image and drawImageFit(image, rect) then
            return
        end
    end

    local sheet = getStructuresSheet()
    if sheet.image then
        local index = STRUCTURE_INDEX[kind]
        if index and drawSpriteFit(sheet, index, rect) then
            return
        end
    end
end

function art.cloud(cx, cy, scale)
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.circle("fill", cx, cy, 26 * scale)
    love.graphics.circle("fill", cx + 28 * scale, cy - 10 * scale, 22 * scale)
    love.graphics.circle("fill", cx + 54 * scale, cy, 24 * scale)
    love.graphics.rectangle("fill", cx - 6 * scale, cy - 4 * scale, 62 * scale, 24 * scale, 12 * scale, 12 * scale)
end

function art.hill(cx, baseY, w, h, color)
    love.graphics.setColor(color)
    love.graphics.ellipse("fill", cx, baseY, w, h)
end

function art.tree(cx, baseY, scale, canopyColor)
    love.graphics.setColor({ 0.42, 0.30, 0.20, 1 })
    love.graphics.rectangle("fill", cx - 6 * scale, baseY - 46 * scale, 12 * scale, 46 * scale)
    love.graphics.setColor(canopyColor)
    love.graphics.circle("fill", cx, baseY - 62 * scale, 30 * scale)
    love.graphics.circle("fill", cx - 22 * scale, baseY - 48 * scale, 22 * scale)
    love.graphics.circle("fill", cx + 22 * scale, baseY - 48 * scale, 22 * scale)
end

function art.fence(x, baseY, width, spacing)
    love.graphics.setColor({ 0.72, 0.60, 0.44, 1 })
    love.graphics.rectangle("fill", x, baseY - 42, width, 6)
    love.graphics.rectangle("fill", x, baseY - 20, width, 6)
    local postX = x
    while postX <= x + width do
        love.graphics.rectangle("fill", postX, baseY - 54, 8, 54, 2, 2)
        postX = postX + spacing
    end
end

return art
