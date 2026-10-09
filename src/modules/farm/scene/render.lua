local scene_shell = require("src.core.scene_shell")
local images = require("src.core.images")
local art = require("src.modules.farm.scene.art")
local config = require("src.modules.farm.content.config")

local render = {}

-- Fallback sky gradient bands, used only when farm-sky.png is absent.
local SKY_BANDS = {
    { 0.62, 0.80, 0.92, 1 },
    { 0.72, 0.86, 0.94, 1 },
    { 0.82, 0.90, 0.92, 1 }
}
-- Fallback ground color, used only when farm-ground.png is absent.
local GRASS = { 0.58, 0.74, 0.40, 1 }
-- Vertical stretch (scaleY) applied to the far/hills strip. Values > 1 make the
-- hills taller so they overlap the grass instead of meeting it edge to edge.
local FAR_STRETCH = 2.1
-- Vertical stretch (scaleY) applied to the ground strip. Values > 1 raise the
-- grass above the ground line so it overlaps the base of the hills.
local GROUND_STRETCH = 2
-- Pixels the far strip's bottom is pushed below the ground line, so the hills
-- tuck behind the grass (the far strip is drawn before the ground).
local FAR_OVERLAP = 60
-- Confetti colors used by the Find-mode celebration.
local CONFETTI_COLORS = {
    { 0.85, 0.35, 0.30 },
    { 0.95, 0.80, 0.30 },
    { 0.45, 0.70, 0.35 },
    { 0.35, 0.60, 0.80 }
}

local function forEachMotif(camX, factor, spacing, content, callback)
    local offset = camX * factor
    local first = math.floor(offset / spacing) - 1
    local last = first + math.ceil(content.width / spacing) + 3
    for index = first, last do
        callback(content.x + index * spacing - offset, index)
    end
end

local function drawSky(content)
    local bandH = content.height / #SKY_BANDS
    for index, color in ipairs(SKY_BANDS) do
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", content.x, content.y + (index - 1) * bandH, content.width, bandH + 1)
    end
end

local function drawFar(content, camX, groundScreenY)
    forEachMotif(camX, config.parallax[1], 720, content, function(sx, index)
        local h = 120 + (index % 3) * 30
        art.hill(sx, groundScreenY - 20, 430, h, { 0.55, 0.70, 0.52, 0.6 })
    end)

    forEachMotif(camX, config.parallax[1], 460, content, function(sx, index)
        if index % 3 == 0 then
            art.cloud(sx, groundScreenY - 320 - (index % 4) * 24, 1 + (index % 2) * 0.3)
        end
    end)
end

local function drawGround(content, camX, groundScreenY)
    love.graphics.setColor(GRASS)
    love.graphics.rectangle("fill", content.x, groundScreenY, content.width, content.height - (groundScreenY - content.y))

    forEachMotif(camX, config.parallax[3], 900, content, function(sx)
        art.fence(sx, groundScreenY + 4, 360, 60)
    end)
end

local contentHeights = {}

local function imageContentHeight(image)
    local cached = contentHeights[image]
    if cached then
        return cached
    end

    local ok, data = pcall(image.newImageData, image)
    if not ok or not data then
        contentHeights[image] = image:getHeight()
        return image:getHeight()
    end

    local width, height = data:getDimensions()
    local top = 0
    for y = 0, height - 1 do
        local opaque = false
        for x = 0, width - 1, 4 do
            local _, _, _, alpha = data:getPixel(x, y)
            if alpha > 0.03 then
                opaque = true
                break
            end
        end
        if opaque then
            top = y
            break
        end
    end

    local contentHeight = height - top
    contentHeights[image] = contentHeight
    return contentHeight
end

local function layerImage(context, key)
    local asset = context.assets:get(key)
    if not asset or asset.type ~= "image" then
        return nil
    end
    return images.get(asset.path)
end

local function drawTiled(image, content, camX, factor, topY, scaleX, scaleY)
    local drawWidth = image:getWidth() * scaleX
    local offset = camX * factor
    local startX = content.x - (offset % drawWidth)

    love.graphics.setColor(1, 1, 1, 1)
    local x = startX - drawWidth
    while x < content.x + content.width do
        love.graphics.draw(image, x, topY, 0, scaleX, scaleY)
        x = x + drawWidth
    end
end

local function drawStructureEntity(content, camX, structure)
    local x = content.x + structure.x - camX
    local y = content.y + structure.y
    art.structure({ x = x, y = y, width = structure.width, height = structure.height }, structure.kind)
end

local function drawAnimalEntity(content, camX, state, animal)
    local sx = content.x + animal.x - camX
    local sy = content.y + animal.y
    local scale = 1
    local offsetY = 0
    local offsetX = 0

    if animal.animT > 0 then
        local progress = 1 - animal.animT / config.bounceDuration
        local bounce = math.sin(math.pi * progress)
        offsetY = -bounce * animal.height * 0.18
        scale = 1 + bounce * 0.08
    end

    if animal.shakeT > 0 then
        local progress = 1 - animal.shakeT / config.shakeDuration
        offsetX = math.sin(progress * math.pi * 8) * (1 - progress) * 10
    end

    local centerX = sx + animal.width * 0.5 + offsetX
    local baseY = sy + animal.height + offsetY

    love.graphics.push()
    love.graphics.translate(centerX, baseY)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-animal.width * 0.5, -animal.height)
    art.animal({ x = 0, y = 0, width = animal.width, height = animal.height }, animal.key)
    love.graphics.pop()
end

local function drawWorld(state, content, viewport)
    local camX = state.camera.x
    local groundScreenY = content.y + config.groundY

    love.graphics.setScissor(
        viewport.offsetX + content.x * viewport.scale,
        viewport.offsetY + content.y * viewport.scale,
        content.width * viewport.scale,
        content.height * viewport.scale
    )

    local context = state.context
    local sky = layerImage(context, "farmSky")
    local far = layerImage(context, "farmFar")
    local ground = layerImage(context, "farmGround")

    -- Stretch the far and ground strips vertically so they overlap: the grass
    -- rises above the ground line and the hills sink behind it, with the sky
    -- reaching the ground line behind them.
    local groundBand = content.height - config.groundY
    local groundScale = ground and (groundBand / math.max(1, imageContentHeight(ground))) or 1
    local groundScaleY = groundScale * GROUND_STRETCH
    local farScaleY = groundScale * FAR_STRETCH
    local farBottom = groundScreenY + FAR_OVERLAP

    if sky then
        local skyScale = (groundScreenY - content.y) / sky:getHeight()
        drawTiled(sky, content, camX, 0, content.y, skyScale, skyScale)
    else
        drawSky(content)
    end

    if far then
        drawTiled(far, content, camX, config.parallax[1],
            farBottom - far:getHeight() * farScaleY, groundScale, farScaleY)
    else
        drawFar(content, camX, groundScreenY)
    end

    if ground then
        drawTiled(ground, content, camX, config.parallax[3],
            content.y + content.height - ground:getHeight() * groundScaleY, groundScale, groundScaleY)
    else
        drawGround(content, camX, groundScreenY)
    end

    local viewLeft = camX - 400
    local viewRight = camX + content.width + 400

    for _, structure in ipairs(state.structures) do
        if structure.x + structure.width >= viewLeft and structure.x <= viewRight then
            drawStructureEntity(content, camX, structure)
        end
    end

    for _, animal in ipairs(state.animals) do
        if animal.x + animal.width >= viewLeft and animal.x <= viewRight then
            drawAnimalEntity(content, camX, state, animal)
        end
    end

    love.graphics.setScissor()
end

local function drawModeBar(state, layout, moduleData)
    local bar = layout.modeBar
    local labels = moduleData.modes or {}

    for _, id in ipairs(bar.order) do
        local button = bar.buttons[id]
        local active = state.mode == id

        if active then
            love.graphics.setColor(0.98, 0.90, 0.70, 1)
        else
            love.graphics.setColor(0.90, 0.85, 0.75, 1)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 12, 12)

        love.graphics.setColor(0.10, 0.10, 0.10, active and 1 or 0.55)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 12, 12)

        love.graphics.printf(labels[id] or id, button.x, button.y + button.height * 0.30, button.width, "center")
    end
end

local function drawBanner(state, layout, moduleData)
    if state.mode ~= "find" or state.phase == "celebrating" then
        return
    end

    local target = state.find and state.find.target
    if not target then
        return
    end

    local banner = layout.banner
    local plate = layerImage(state.context, "farmBanner")
    if plate then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(plate, banner.x, banner.y, 0,
            banner.width / plate:getWidth(), banner.height / plate:getHeight())
    else
        love.graphics.setColor(1, 0.98, 0.92, 0.96)
        love.graphics.rectangle("fill", banner.x, banner.y, banner.width, banner.height, 16, 16)
        love.graphics.setColor(0.20, 0.15, 0.10, 1)
        love.graphics.rectangle("line", banner.x, banner.y, banner.width, banner.height, 16, 16)
    end

    local animals = moduleData.animals or {}
    local label = animals[target.key] or target.key
    local text
    if (state.find.feedbackTimer or 0) > 0 then
        text = moduleData.correct or "Correct!"
    elseif state.find.prompt == "name" then
        text = string.format(moduleData.findPrompt or "Find: %s", label)
    else
        text = moduleData.listen or "Listen... who is it?"
    end

    love.graphics.setColor(0.20, 0.15, 0.10, 1)
    love.graphics.printf(text, banner.x, banner.y + banner.height * 0.38, banner.width, "center")
end

local function drawCelebration(state, content, moduleData)
    local elapsed = (state.find and state.find.celebrateT) or 0
    local centerX = content.x + content.width * 0.5
    local centerY = content.y + content.height * 0.42

    local ringAlpha = math.max(0, 1 - elapsed / 1.6)
    love.graphics.setColor(1, 0.86, 0.42, 0.45 * ringAlpha)
    love.graphics.circle("fill", centerX, centerY, 40 + elapsed * 180)

    for index = 1, 44 do
        local color = CONFETTI_COLORS[((index - 1) % #CONFETTI_COLORS) + 1]
        local x = content.x + ((index * 137.5) % content.width)
        local fall = (elapsed * 170 + index * 41) % (content.height + 80)
        local y = content.y - 40 + fall

        love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.rotate(elapsed * 2 + index)
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", -5, -5, 10, 10)
        love.graphics.pop()
    end

    love.graphics.setFont(art.font(content.height * 0.07))
    love.graphics.setColor(0.20, 0.14, 0.10, 1)
    love.graphics.printf(moduleData.complete or "", content.x, centerY - content.height * 0.06, content.width, "center")
end

function render.draw(state)
    local context = state.context
    local i18n = context.i18n
    local viewport = context.viewport
    local content = viewport:getContentArea()
    local layout = state.layout
    local moduleData = i18n:getModuleData("farm")

    drawWorld(state, content, viewport)

    love.graphics.setFont(art.font(content.height * 0.045))
    love.graphics.setColor(0.20, 0.14, 0.10, 1)
    love.graphics.printf(moduleData.title or "Farm", content.x, content.y + 96, content.width, "left")

    love.graphics.setFont(art.font(content.height * 0.03))
    drawModeBar(state, layout, moduleData)

    if state.mode ~= "find" then
        love.graphics.setColor(0.25, 0.20, 0.15, 1)
        love.graphics.printf(moduleData.instruction or "", content.x, content.y + content.height - 44, content.width, "center")
    else
        drawBanner(state, layout, moduleData)
    end

    love.graphics.setFont(art.font(content.height * 0.03))
    scene_shell.drawBackButton(state.backButton, i18n)

    if state.phase == "celebrating" then
        drawCelebration(state, content, moduleData)
    end
end

return render
