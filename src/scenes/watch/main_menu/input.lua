local model = require("src.scenes.watch.main_menu.model")

local input = {}
local SWIPE_THRESHOLD = 40
local TAP_MAX_MOVE = 25

local function contains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height
end

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

function input.finish(state, layout, pointerId, x, y)
    if pointerId ~= state.activeTouchId or state.transitionTimer > 0 then
        return
    end

    state.activeTouchId = nil
    state.touchCurrentX = nil

    local deltaX = x - state.touchStartX
    local deltaY = y - state.touchStartY

    -- Check settings button tap first (small area, not a swipe).
    if math.abs(deltaX) < TAP_MAX_MOVE and math.abs(deltaY) < TAP_MAX_MOVE then
        if contains(layout.settingsButton, x, y) then
            model.tapSettings(state)
            return "settings"
        end
        model.tapModule(state)
        return "tap"
    end

    if math.abs(deltaX) >= SWIPE_THRESHOLD and math.abs(deltaX) > math.abs(deltaY) then
        local dir = deltaX < 0 and 1 or -1
        model.navigateTo(state, dir)
        return "swipe"
    end
end

return input
