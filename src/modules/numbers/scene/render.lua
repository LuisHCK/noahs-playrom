local scene_shell = require("src.core.scene_shell")
local art = require("src.modules.numbers.scene.art")

local render = {}

local GLOW_COLOR = { 0.55, 0.75, 0.50, 1 }
local CONNECT_COLOR = { 1.0, 0.78, 0.28, 1 }
local SHADOW_COLOR = { 0, 0, 0, 0.18 }
local CONFETTI_COLORS = {
    { 0.85, 0.35, 0.30 },
    { 0.95, 0.80, 0.30 },
    { 0.45, 0.70, 0.35 },
    { 0.35, 0.60, 0.80 }
}

local function drawPiece(piece)
    if piece.kind == "number" then
        art.number(piece, piece.value)
    else
        art.dots(piece, piece.value)
    end
end

local function drawPieceScaled(piece, scale)
    local centerX = piece.x + piece.width * 0.5
    local centerY = piece.y + piece.height * 0.5

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-piece.width * 0.5, -piece.height * 0.5)
    drawPiece({ x = 0, y = 0, width = piece.width, height = piece.height,
        kind = piece.kind, value = piece.value })
    love.graphics.pop()
end

local function drawPulse(state, piece)
    local remaining = state.pulseTimers[piece]
    if not remaining then
        return
    end

    local alpha = math.min(1, remaining / 0.7)
    love.graphics.setColor(GLOW_COLOR[1], GLOW_COLOR[2], GLOW_COLOR[3], alpha * 0.9)
    love.graphics.rectangle("line", piece.x - 6, piece.y - 6, piece.width + 12, piece.height + 12, 16, 16)
end

local function drawConnectHighlight(piece)
    love.graphics.setColor(CONNECT_COLOR[1], CONNECT_COLOR[2], CONNECT_COLOR[3], 0.95)
    love.graphics.rectangle("line", piece.x - 7, piece.y - 7, piece.width + 14, piece.height + 14, 18, 18)
end

local function drawPairHighlight(piece)
    local partner = piece.partner
    if not partner then
        return
    end

    local minX = math.min(piece.x, partner.x)
    local minY = math.min(piece.y, partner.y)
    local maxX = math.max(piece.x + piece.width, partner.x + partner.width)
    local maxY = math.max(piece.y + piece.height, partner.y + partner.height)

    love.graphics.setColor(GLOW_COLOR[1], GLOW_COLOR[2], GLOW_COLOR[3], 0.5)
    love.graphics.rectangle("line", minX - 8, minY - 8, (maxX - minX) + 16, (maxY - minY) + 16, 18, 18)
end

local function drawProgress(state, content)
    local stages = state.stages
    if not stages or #stages <= 1 then
        return
    end

    local y = state.layout.progressY or (content.y + content.height - 46)
    local spacing = 34
    local totalW = #stages * spacing - (spacing - 16)
    local startX = content.x + (content.width - totalW) * 0.5

    for index = 1, #stages do
        local cx = startX + (index - 1) * spacing
        if index == state.currentStage and state.phase ~= "celebrating" then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.circle("fill", cx, y, 10)
            love.graphics.setColor(0.82, 0.74, 0.58, 1)
            love.graphics.circle("line", cx, y, 10)
        elseif index < state.currentStage or state.phase == "celebrating" then
            love.graphics.setColor(0.98, 0.97, 0.94, 1)
            love.graphics.circle("fill", cx, y, 9)
            love.graphics.setColor(0.85, 0.82, 0.76, 1)
            love.graphics.circle("line", cx, y, 9)
        else
            love.graphics.setColor(0.90, 0.89, 0.86, 1)
            love.graphics.circle("line", cx, y, 10)
        end
    end
end

local function drawCelebration(state, content, moduleData)
    local elapsed = state.celebrateTimer
    local centerX = content.x + content.width * 0.5
    local centerY = content.y + content.height * 0.42

    local ringAlpha = math.max(0, 1 - elapsed / 1.6)
    local radius = 40 + elapsed * 180
    love.graphics.setColor(1, 0.86, 0.42, 0.45 * ringAlpha)
    love.graphics.circle("fill", centerX, centerY, radius)

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

    local text = moduleData.complete or ""
    love.graphics.setFont(art.font(content.height * 0.07))
    love.graphics.setColor(0.2, 0.14, 0.1, 1)
    love.graphics.printf(text, content.x, centerY - content.height * 0.06, content.width, "center")
end

function render.draw(state)
    local context = state.context
    local i18n = context.i18n
    local assets = context.assets
    local viewport = context.viewport
    local content = viewport:getContentArea()
    local moduleData = i18n:getModuleData("numbers")

    scene_shell.drawBackground(assets:get("panelBackground"), viewport)

    love.graphics.setFont(art.font(content.height * 0.045))
    scene_shell.drawTitle(moduleData.title or "Numbers", "", content, 20, 20)

    love.graphics.setFont(art.font(content.height * 0.026))
    love.graphics.setColor(0.35, 0.28, 0.22, 1)
    love.graphics.printf(moduleData.instruction or "", content.x, content.y + 62, content.width, "center")

    love.graphics.setFont(art.font(content.height * 0.03))
    scene_shell.drawBackButton(state.backButton, i18n)

    for _, piece in ipairs(state.pieces) do
        if piece.paired then
            drawPiece(piece)
        end
    end

    for _, piece in ipairs(state.pieces) do
        if not piece.paired and not piece.dragging then
            drawPiece(piece)
        end
    end

    for _, piece in ipairs(state.pieces) do
        if piece.paired then
            drawPulse(state, piece)
        end
    end

    for _, piece in ipairs(state.pieces) do
        if piece.paired and piece.kind == "dots" then
            drawPairHighlight(piece)
        end
    end

    for _, piece in ipairs(state.pieces) do
        if piece.dragging then
            love.graphics.setColor(SHADOW_COLOR)
            love.graphics.rectangle("fill", piece.x + 5, piece.y + 7, piece.width, piece.height, 14, 14)
            drawPieceScaled(piece, 1.05)
        end
    end

    if state.drag and state.connectCandidate then
        drawConnectHighlight(state.drag.piece)
        drawConnectHighlight(state.connectCandidate)
    end

    drawProgress(state, content)

    if state.phase == "celebrating" then
        drawCelebration(state, content, moduleData)
    end
end

return render
