local modulesData = require("src.data.content.modules")

local model = {}
local SWIPE_DURATION = 0.25
local TRANSITION_DELAY = 0.4
local TOAST_DURATION = 0.8

local moduleOrder = { "alphabet", "animals", "numbers", "universe" }

-- Add enabled flag to each module entry.
local function buildModules()
    local modules = {}
    for _, id in ipairs(moduleOrder) do
        modules[#modules + 1] = {
            key = id,
            scene = modulesData[id].scene,
            enabled = (id == "alphabet")
        }
    end
    return modules
end

function model.create(context, setScene)
    return {
        modules = buildModules(),
        currentIndex = 1,
        swipeAnim = { active = false, progress = 0, direction = 1 },
        transitionTimer = 0,
        queuedScene = nil,
        toastTimer = 0,
        activeTouchId = nil,
        touchStartX = 0,
        touchStartY = 0,
        touchCurrentX = nil,
        context = context,
        setScene = setScene
    }
end

function model.navigateTo(state, direction)
    if state.swipeAnim.active then
        return
    end
    local total = #state.modules
    state.currentIndex = ((state.currentIndex - 1 + direction + total) % total) + 1
    state.swipeAnim.active = true
    state.swipeAnim.progress = 0
    state.swipeAnim.direction = direction
end

function model.tapModule(state)
    local module = state.modules[state.currentIndex]
    if module.enabled then
        state.queuedScene = module.scene
        state.transitionTimer = TRANSITION_DELAY
    else
        state.toastTimer = TOAST_DURATION
    end
end

function model.update(state, dt)
    if state.swipeAnim.active then
        state.swipeAnim.progress = math.min(state.swipeAnim.progress + dt / SWIPE_DURATION, 1)
        if state.swipeAnim.progress >= 1 then
            state.swipeAnim.active = false
            state.touchCurrentX = nil
        end
    end

    if state.transitionTimer > 0 then
        state.transitionTimer = math.max(0, state.transitionTimer - dt)
        if state.transitionTimer == 0 and state.queuedScene then
            local scene = "watch_" .. state.queuedScene
            state.setScene(scene, state.context)
        end
    end

    if state.toastTimer > 0 then
        state.toastTimer = math.max(0, state.toastTimer - dt)
    end
end

return model
