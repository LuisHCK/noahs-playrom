local model = require("src.scenes.watch.main_menu.model")

local input = {}
local SWIPE_THRESHOLD = 40
local TAP_MAX_MOVE = 25

function input.begin(state, pointerId, x, y)
    if state.activeTouchId ~= nil or state.swipeAnim.active or state.transitionTimer > 0 then
        return
    end
    state.activeTouchId = pointerId
    state.touchStartX = x
    state.touchStartY = y
    state.touchCurrentX = x
end

function input.move(state, pointerId, x, y)
    if pointerId ~= state.activeTouchId then
        return
    end
    state.touchCurrentX = x
end

function input.finish(state, pointerId, x, y)
    if pointerId ~= state.activeTouchId or state.transitionTimer > 0 then
        return
    end

    state.activeTouchId = nil
    state.touchCurrentX = nil

    local deltaX = x - state.touchStartX
    local deltaY = y - state.touchStartY

    if math.abs(deltaX) >= SWIPE_THRESHOLD and math.abs(deltaX) > math.abs(deltaY) then
        -- Swipe left (deltaX negative) moves to next card.
        local dir = deltaX < 0 and 1 or -1
        model.navigateTo(state, dir)
        return "swipe"
    end

    if math.abs(deltaX) < TAP_MAX_MOVE and math.abs(deltaY) < TAP_MAX_MOVE then
        model.tapModule(state)
        return "tap"
    end
end

return input
