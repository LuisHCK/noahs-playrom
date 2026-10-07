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

local SPECIES = {
    cow = { kind = "quad", body = { 0.95, 0.93, 0.88, 1 }, accent = { 0.24, 0.21, 0.19, 1 }, feature = "spots" },
    horse = { kind = "quad", body = { 0.55, 0.36, 0.24, 1 }, accent = { 0.28, 0.17, 0.11, 1 }, feature = "mane" },
    hen = { kind = "bird", body = { 0.90, 0.72, 0.35, 1 }, accent = { 0.82, 0.26, 0.20, 1 }, feature = "comb" },
    rooster = { kind = "bird", body = { 0.80, 0.32, 0.24, 1 }, accent = { 0.92, 0.76, 0.26, 1 }, feature = "comb" },
    duck = { kind = "bird", body = { 0.98, 0.96, 0.90, 1 }, accent = { 0.95, 0.70, 0.20, 1 }, feature = "bill" },
    pig = { kind = "quad", body = { 0.93, 0.65, 0.66, 1 }, accent = { 0.80, 0.45, 0.47, 1 }, feature = "snout" },
    sheep = { kind = "quad", body = { 0.96, 0.95, 0.93, 1 }, accent = { 0.34, 0.31, 0.29, 1 }, feature = "wool" },
    dog = { kind = "quad", body = { 0.72, 0.55, 0.35, 1 }, accent = { 0.40, 0.28, 0.18, 1 }, feature = "ears" },
    cat = { kind = "quad", body = { 0.58, 0.58, 0.62, 1 }, accent = { 0.90, 0.90, 0.92, 1 }, feature = "cat" }
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

local function drawLegs(x, y, w, h, color)
    love.graphics.setColor(color)
    local legW = w * 0.09
    local legH = h * 0.30
    local legY = y + h - legH
    love.graphics.rectangle("fill", x + w * 0.16, legY, legW, legH, 3, 3)
    love.graphics.rectangle("fill", x + w * 0.33, legY, legW, legH, 3, 3)
    love.graphics.rectangle("fill", x + w * 0.58, legY, legW, legH, 3, 3)
    love.graphics.rectangle("fill", x + w * 0.75, legY, legW, legH, 3, 3)
end

local function drawQuadruped(rect, species)
    local x, y, w, h = rect.x, rect.y, rect.width, rect.height
    local body = species.body
    local accent = species.accent

    drawLegs(x, y, w, h, body)

    love.graphics.setColor(body)
    love.graphics.ellipse("fill", x + w * 0.5, y + h * 0.52, w * 0.42, h * 0.30)

    local headX = x + w * 0.80
    local headY = y + h * 0.32
    local headR = h * 0.20
    love.graphics.setColor(body)
    love.graphics.ellipse("fill", headX, headY, headR * 1.05, headR)

    love.graphics.setColor(accent)
    if species.feature == "spots" then
        love.graphics.circle("fill", x + w * 0.42, y + h * 0.46, h * 0.08)
        love.graphics.circle("fill", x + w * 0.58, y + h * 0.58, h * 0.06)
    elseif species.feature == "mane" then
        love.graphics.polygon("fill",
            x + w * 0.66, y + h * 0.20,
            x + w * 0.72, y + h * 0.34,
            x + w * 0.64, y + h * 0.42,
            x + w * 0.60, y + h * 0.28)
    elseif species.feature == "wool" then
        for _, offset in ipairs({ { 0.30, 0.36 }, { 0.44, 0.30 }, { 0.58, 0.36 }, { 0.70, 0.32 } }) do
            love.graphics.circle("fill", x + w * offset[1], y + h * offset[2], h * 0.14)
        end
    elseif species.feature == "snout" then
        love.graphics.ellipse("fill", headX + headR * 0.55, headY + headR * 0.25, headR * 0.5, headR * 0.4)
    elseif species.feature == "dog" or species.feature == "ears" then
        love.graphics.ellipse("fill", headX - headR * 0.6, headY - headR * 0.7, headR * 0.35, headR * 0.7)
    elseif species.feature == "cat" then
        love.graphics.polygon("fill",
            headX - headR * 0.7, headY - headR * 0.4,
            headX - headR * 0.3, headY - headR * 1.1,
            headX - headR * 0.05, headY - headR * 0.45)
        love.graphics.polygon("fill",
            headX + headR * 0.05, headY - headR * 0.45,
            headX + headR * 0.3, headY - headR * 1.1,
            headX + headR * 0.7, headY - headR * 0.4)
    end

    love.graphics.setColor(0.15, 0.12, 0.10, 1)
    love.graphics.circle("fill", headX + headR * 0.45, headY - headR * 0.1, math.max(2, h * 0.02))
end

local function drawBird(rect, species)
    local x, y, w, h = rect.x, rect.y, rect.width, rect.height
    local body = species.body

    love.graphics.setColor({ 0.85, 0.55, 0.20, 1 })
    local legW = math.max(2, w * 0.05)
    love.graphics.rectangle("fill", x + w * 0.42, y + h * 0.86, legW, h * 0.14)
    love.graphics.rectangle("fill", x + w * 0.58, y + h * 0.86, legW, h * 0.14)

    love.graphics.setColor(body)
    love.graphics.ellipse("fill", x + w * 0.48, y + h * 0.60, w * 0.40, h * 0.34)

    local headX = x + w * 0.72
    local headY = y + h * 0.34
    local headR = h * 0.22
    love.graphics.circle("fill", headX, headY, headR)

    love.graphics.setColor(species.accent)
    love.graphics.polygon("fill",
        headX + headR * 0.8, headY - headR * 0.15,
        headX + headR * 1.9, headY + headR * 0.05,
        headX + headR * 0.8, headY + headR * 0.35)

    if species.feature == "comb" then
        love.graphics.circle("fill", headX - headR * 0.2, headY - headR * 0.9, headR * 0.35)
        love.graphics.circle("fill", headX + headR * 0.25, headY - headR * 1.0, headR * 0.30)
    elseif species.feature == "bill" then
        love.graphics.setColor(species.accent)
        love.graphics.ellipse("fill", headX + headR * 0.6, headY + headR * 0.2, headR * 0.7, headR * 0.32)
    end

    love.graphics.setColor(0.15, 0.12, 0.10, 1)
    love.graphics.circle("fill", headX + headR * 0.25, headY - headR * 0.15, math.max(2, h * 0.025))
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

    local species = SPECIES[key] or SPECIES.cow
    if species.kind == "bird" then
        drawBird(rect, species)
    else
        drawQuadruped(rect, species)
    end
end

local function drawBarn(x, y, w, h)
    love.graphics.setColor({ 0.80, 0.32, 0.26, 1 })
    love.graphics.rectangle("fill", x, y + h * 0.28, w, h * 0.72)
    love.graphics.setColor({ 0.55, 0.20, 0.16, 1 })
    love.graphics.polygon("fill", x - w * 0.04, y + h * 0.30, x + w * 0.5, y, x + w * 1.04, y + h * 0.30)
    love.graphics.setColor({ 0.95, 0.93, 0.88, 1 })
    love.graphics.rectangle("fill", x + w * 0.40, y + h * 0.55, w * 0.20, h * 0.45)
    love.graphics.setColor({ 0.35, 0.35, 0.40, 1 })
    love.graphics.rectangle("line", x + w * 0.40, y + h * 0.55, w * 0.20, h * 0.45)
end

local function drawStable(x, y, w, h)
    love.graphics.setColor({ 0.74, 0.60, 0.42, 1 })
    love.graphics.rectangle("fill", x, y + h * 0.32, w, h * 0.68)
    love.graphics.setColor({ 0.50, 0.36, 0.22, 1 })
    love.graphics.polygon("fill", x - w * 0.03, y + h * 0.34, x + w * 0.5, y, x + w * 1.03, y + h * 0.34)
    love.graphics.setColor({ 0.40, 0.28, 0.18, 1 })
    love.graphics.rectangle("line", x + w * 0.35, y + h * 0.52, w * 0.30, h * 0.48)
end

local function drawCoop(x, y, w, h)
    love.graphics.setColor({ 0.86, 0.72, 0.48, 1 })
    love.graphics.rectangle("fill", x, y + h * 0.42, w, h * 0.58)
    love.graphics.setColor({ 0.60, 0.42, 0.24, 1 })
    love.graphics.polygon("fill", x - w * 0.05, y + h * 0.44, x + w * 0.5, y + h * 0.05, x + w * 1.05, y + h * 0.44)
    love.graphics.setColor({ 0.30, 0.22, 0.15, 1 })
    love.graphics.circle("fill", x + w * 0.5, y + h * 0.72, h * 0.16)
end

local function drawGroundPatch(x, y, w, h, color)
    love.graphics.setColor(color)
    love.graphics.ellipse("fill", x + w * 0.5, y + h * 0.55, w * 0.5, h * 0.5)
end

local function drawStructure(rect, kind)
    local x, y, w, h = rect.x, rect.y, rect.width, rect.height

    if kind == "barn" then
        drawBarn(x, y, w, h)
    elseif kind == "stable" then
        drawStable(x, y, w, h)
    elseif kind == "coop" then
        drawCoop(x, y, w, h)
    elseif kind == "pond" then
        drawGroundPatch(x, y, w, h, { 0.45, 0.68, 0.82, 1 })
        love.graphics.setColor({ 0.62, 0.80, 0.90, 1 })
        love.graphics.ellipse("line", x + w * 0.5, y + h * 0.55, w * 0.44, h * 0.42)
    elseif kind == "mudPen" then
        drawGroundPatch(x, y, w, h, { 0.52, 0.38, 0.26, 1 })
    elseif kind == "field" then
        drawGroundPatch(x, y, w, h, { 0.55, 0.72, 0.38, 1 })
    elseif kind == "doghouse" then
        love.graphics.setColor({ 0.78, 0.60, 0.40, 1 })
        love.graphics.rectangle("fill", x, y + h * 0.35, w, h * 0.65)
        love.graphics.setColor({ 0.52, 0.36, 0.22, 1 })
        love.graphics.polygon("fill", x - w * 0.06, y + h * 0.37, x + w * 0.5, y, x + w * 1.06, y + h * 0.37)
        love.graphics.setColor({ 0.25, 0.18, 0.12, 1 })
        love.graphics.circle("fill", x + w * 0.5, y + h * 0.72, h * 0.18)
    elseif kind == "cottage" then
        love.graphics.setColor({ 0.90, 0.86, 0.78, 1 })
        love.graphics.rectangle("fill", x, y + h * 0.30, w, h * 0.70)
        love.graphics.setColor({ 0.62, 0.34, 0.28, 1 })
        love.graphics.polygon("fill", x - w * 0.05, y + h * 0.32, x + w * 0.5, y, x + w * 1.05, y + h * 0.32)
        love.graphics.setColor({ 0.55, 0.72, 0.85, 1 })
        love.graphics.rectangle("fill", x + w * 0.18, y + h * 0.50, w * 0.20, h * 0.20)
        love.graphics.setColor({ 0.50, 0.34, 0.22, 1 })
        love.graphics.rectangle("fill", x + w * 0.58, y + h * 0.58, w * 0.24, h * 0.42)
    elseif kind == "windmill" then
        love.graphics.setColor({ 0.86, 0.83, 0.76, 1 })
        love.graphics.polygon("fill", x + w * 0.2, y + h, x + w * 0.8, y + h, x + w * 0.66, y + h * 0.25, x + w * 0.34, y + h * 0.25)
        love.graphics.setColor({ 0.55, 0.38, 0.24, 1 })
        love.graphics.polygon("fill", x + w * 0.2, y + h * 0.27, x + w * 0.5, y, x + w * 0.8, y + h * 0.27)
        love.graphics.setColor({ 0.92, 0.90, 0.86, 1 })
        local cx, cy = x + w * 0.5, y + h * 0.22
        for index = 1, 4 do
            local angle = (index - 1) * math.pi / 2
            love.graphics.polygon("fill",
                cx, cy,
                cx + math.cos(angle) * w * 0.42, cy + math.sin(angle) * w * 0.42,
                cx + math.cos(angle + 0.35) * w * 0.10, cy + math.sin(angle + 0.35) * w * 0.10)
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

    drawStructure(rect, kind)
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
