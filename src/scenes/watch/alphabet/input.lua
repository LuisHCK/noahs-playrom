local state = require("src.scenes.watch.alphabet.state")

local input = {}
local SWIPE_THRESHOLD = 40
local TAP_MAX_MOVE = 25

local function contains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height
end

function input.begin(stateObj, layout, pointerId, x, y)
    if stateObj.activeTouchId ~= nil then
        return
    end
    stateObj.activeTouchId = pointerId
    stateObj.touchStartX = x
    stateObj.touchStartY = y
    stateObj.touchCurrentX = x
end

function input.move(stateObj, layout, pointerId, x, y)
    if pointerId ~= stateObj.activeTouchId then
        return
    end
    stateObj.touchCurrentX = x
end

function input.finish(stateObj, layout, pointerId, x, y)
    if pointerId ~= stateObj.activeTouchId then
        return nil
    end

    stateObj.activeTouchId = nil
    stateObj.touchCurrentX = nil

    local deltaX = x - stateObj.touchStartX
    local deltaY = y - stateObj.touchStartY

    -- Swipe detection.
    if math.abs(deltaX) >= SWIPE_THRESHOLD and math.abs(deltaX) > math.abs(deltaY) then
        local dir = deltaX < 0 and 1 or -1
        state.navigate(stateObj, dir)
        return "swipe"
    end

    -- Tap detection.
    if math.abs(deltaX) < TAP_MAX_MOVE and math.abs(deltaY) < TAP_MAX_MOVE then
        if contains(layout.backButton, x, y) then
            return "back"
        end
        if contains(layout.cardRect, x, y) and not stateObj.isFlipLocked then
            state.flipCurrent(stateObj)
            return "flip"
        end
    end

    return nil
end

return input
