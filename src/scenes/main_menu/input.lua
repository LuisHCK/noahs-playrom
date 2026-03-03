local input = {}

local function forEachButton(state, callback)
    for _, button in ipairs(state.moduleButtons) do
        callback(button)
    end
    callback(state.profileButton)
    callback(state.languageButton)
end

function input.press(state, x, y)
    if state.transitionTimer and state.transitionTimer > 0 then
        return
    end

    forEachButton(state, function(button)
        button:press(x, y)
    end)
end

function input.release(state, x, y)
    if state.transitionTimer and state.transitionTimer > 0 then
        return
    end

    forEachButton(state, function(button)
        button:release(x, y)
    end)
end

return input
