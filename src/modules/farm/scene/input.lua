local config = require("src.modules.farm.content.config")
local camera = require("src.modules.farm.scene.camera")
local stateModule = require("src.modules.farm.scene.state")

local input = {}

local function inside(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width
        and y >= rect.y and y <= rect.y + rect.height
end

local function modeButtonAt(layout, x, y)
    for _, id in ipairs(layout.modeBar.order) do
        if inside(layout.modeBar.buttons[id], x, y) then
            return id
        end
    end
    return nil
end

function input.begin(state, pointerId, x, y)
    if state.phase == "celebrating" then
        state.pendingContinue = true
        return nil
    end

    local modeId = modeButtonAt(state.layout, x, y)
    if modeId then
        state.pendingMode = modeId
        return nil
    end

    if state.mode == "find" and state.find and state.find.target
        and inside(state.layout.banner, x, y) then
        state.pendingBanner = true
        return nil
    end

    state.pointer = {
        id = pointerId,
        startX = x,
        startY = y,
        lastX = x,
        startTime = state.time,
        velocity = 0,
        dragging = false
    }
    return nil
end

function input.move(state, pointerId, x, y)
    local pointer = state.pointer
    if not pointer then
        return
    end
    if pointerId ~= nil and pointer.id ~= nil and pointerId ~= pointer.id then
        return
    end

    local dx = x - pointer.lastX
    if not pointer.dragging
        and (math.abs(x - pointer.startX) > config.tapMaxMove
            or math.abs(y - pointer.startY) > config.tapMaxMove) then
        pointer.dragging = true
    end

    if pointer.dragging then
        state.camera.x = camera.clamp(
            state.camera.x - dx,
            config.worldWidth,
            state.layout.content.width
        )
        pointer.velocity = dx / math.max(0.001, state.lastDt)
    end

    pointer.lastX = x
end

function input.finish(state, pointerId, x, y)
    if state.pendingContinue then
        state.pendingContinue = false
        return "continue"
    end

    if state.pendingMode then
        local modeId = state.pendingMode
        state.pendingMode = nil
        return "mode:" .. modeId
    end

    if state.pendingBanner then
        state.pendingBanner = false
        return "repeat"
    end

    local pointer = state.pointer
    if not pointer then
        return nil
    end
    if pointerId ~= nil and pointer.id ~= nil and pointerId ~= pointer.id then
        return nil
    end
    state.pointer = nil

    local duration = state.time - pointer.startTime
    local moved = math.abs(x - pointer.startX) > config.tapMaxMove
        or math.abs(y - pointer.startY) > config.tapMaxMove

    if not pointer.dragging and not moved and duration <= config.tapMaxTime then
        local worldX = x - state.layout.content.x + state.camera.x
        local worldY = y - state.layout.content.y
        local animal = stateModule.animalAt(state, worldX, worldY)
        if animal then
            return stateModule.interact(state, animal)
        end
        return nil
    end

    local velocity = -(pointer.velocity or 0)
    local maxVelocity = config.maxVelocity
    if velocity > maxVelocity then
        velocity = maxVelocity
    elseif velocity < -maxVelocity then
        velocity = -maxVelocity
    end
    state.camera.velocity = velocity

    return nil
end

function input.wheel(state, _, dy)
    state.camera.x = camera.clamp(
        state.camera.x + dy * 80,
        config.worldWidth,
        state.layout.content.width
    )
    state.camera.velocity = 0
end

function input.key(state, key)
    local step = 80
    if key == "left" or key == "a" then
        state.camera.x = camera.clamp(state.camera.x - step, config.worldWidth, state.layout.content.width)
        state.camera.velocity = 0
    elseif key == "right" or key == "d" then
        state.camera.x = camera.clamp(state.camera.x + step, config.worldWidth, state.layout.content.width)
        state.camera.velocity = 0
    end
end

return input
