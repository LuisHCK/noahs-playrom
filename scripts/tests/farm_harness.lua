package.path = "./?.lua;./?/init.lua;" .. package.path

local function noop() end
local function flex()
    return setmetatable({}, {
        __index = function() return flex() end,
        __call = function() return flex() end
    })
end

love = {
    filesystem = {
        getInfo = function() return nil end,
        getDirectoryItems = function() return {} end,
        load = function() return nil end,
        write = noop
    },
    graphics = setmetatable({
        newImage = function() return flex() end,
        newQuad = function() return flex() end,
        newFont = function() return flex() end,
        getFont = function() return flex() end,
        getDimensions = function() return 1280, 720 end
    }, { __index = function() return noop end }),
    audio = { newSource = function() return flex() end },
    window = { setFullscreen = noop },
    system = { getOS = function() return "OS X" end },
    handlers = {}
}

local viewport = require("src.core.viewport")
viewport:update(1280, 720)

local i18n = require("src.core.i18n")
local assets = require("src.core.assets")
local audio = require("src.core.audio")
local fonts = require("src.core.fonts")
local Button = require("src.ui.button")

local config = require("src.modules.farm.content.config")
local layoutModule = require("src.modules.farm.scene.layout")
local stateModule = require("src.modules.farm.scene.state")
local input = require("src.modules.farm.scene.input")
local render = require("src.modules.farm.scene.render")

local context = {
    i18n = i18n,
    assets = assets,
    audio = audio,
    fonts = fonts,
    viewport = viewport,
    saveSettings = noop
}

local function newState()
    local layout = layoutModule.build(viewport)
    local state = stateModule.create(context, layout)
    state.backButton = Button.new({ id = "back", x = 32, y = 32, width = 140, height = 50 })
    return state
end

local function viewCoords(state, worldX, worldY)
    return state.layout.content.x + worldX - state.camera.x,
        state.layout.content.y + worldY
end

local function tapWorld(state, worldX, worldY)
    local vx, vy = viewCoords(state, worldX, worldY)
    input.begin(state, nil, vx, vy)
    return input.finish(state, nil, vx, vy)
end

local function tapAnimal(state, animal)
    return tapWorld(state, animal.x + animal.width * 0.5, animal.y + animal.height * 0.5)
end

local function applyAction(state, action)
    if type(action) ~= "string" then
        return action
    end
    if action:sub(1, 5) == "mode:" then
        stateModule.setMode(state, action:sub(6))
    elseif action == "continue" then
        stateModule.restart(state)
    end
    return action
end

local function tapMode(state, id)
    local button = state.layout.modeBar.buttons[id]
    local vx = button.x + button.width * 0.5
    local vy = button.y + button.height * 0.5
    input.begin(state, nil, vx, vy)
    return applyAction(state, input.finish(state, nil, vx, vy))
end

-- 1) Drag scrolls and clamps; inertia settles within bounds.
do
    local state = newState()
    assert(state.camera.x == 0, "camera should start at 0")

    input.begin(state, nil, 700, 300)
    input.move(state, nil, 500, 300)
    assert(state.pointer.dragging, "large move should start a drag")
    input.finish(state, nil, 500, 300)
    assert(state.camera.x > 0, "dragging left should scroll the camera right")

    for _ = 1, 600 do
        stateModule.update(state, 0.016)
    end

    local maxX = config.worldWidth - state.layout.content.width
    assert(state.camera.x >= 0 and state.camera.x <= maxX, "camera out of bounds after inertia")
    assert(state.camera.velocity == 0, "velocity should settle to zero")

    state.camera.x = 999999
    stateModule.update(state, 0.016)
    assert(state.camera.x == maxX, "camera should clamp to the world's right edge")

    state.camera.x = -999999
    stateModule.update(state, 0.016)
    assert(state.camera.x == 0, "camera should clamp to the world's left edge")
    render.draw(state)
    print("ok: drag scrolls, clamps, and settles")
end

-- 2) Tap-vs-drag: a small press interacts; a drag does not.
do
    local state = newState()
    local cow = state.animals[1]

    local action = tapAnimal(state, cow)
    assert(action == "sound", "explore tap should play a sound, got " .. tostring(action))
    assert(cow.animT > 0, "tap should trigger a bounce animation")
    render.draw(state)

    cow.animT = 0
    local vx, vy = viewCoords(state, cow.x + cow.width * 0.5, cow.y + cow.height * 0.5)
    input.begin(state, nil, vx, vy)
    input.move(state, nil, vx + 80, vy + 4)
    local dragAction = input.finish(state, nil, vx + 80, vy + 4)
    assert(dragAction == nil, "drag should not interact")
    assert(cow.animT == 0, "drag should not bounce the animal")
    render.draw(state)
    print("ok: tap interacts, drag scrolls without interacting")
end

-- 3) Mode switching: learn plays the name; find asks for a target.
do
    local state = newState()
    assert(tapMode(state, "learn") == "mode:learn", "learn mode button")
    assert(state.mode == "learn", "mode should be learn")

    local cow = state.animals[1]
    assert(tapAnimal(state, cow) == "name", "learn tap should speak the name")
    render.draw(state)

    assert(tapMode(state, "find") == "mode:find", "find mode button")
    assert(state.mode == "find", "mode should be find")
    assert(state.find and state.find.target, "find mode should pick a target")

    local banner = state.layout.banner
    local bx = banner.x + banner.width * 0.5
    local by = banner.y + banner.height * 0.5
    input.begin(state, nil, bx, by)
    assert(input.finish(state, nil, bx, by) == "repeat", "tapping the prompt should repeat the question")

    render.draw(state)
    print("ok: mode switching works, find picks a target, prompt repeats on tap")
end

-- 4) Find mode: wrong taps only shake; correct taps advance; all found celebrates.
do
    local state = newState()
    stateModule.setMode(state, "find")

    local target = state.find.target
    local wrong = state.animals[1] == target and state.animals[2] or state.animals[1]
    assert(tapAnimal(state, wrong) == "wrong", "wrong animal should be marked wrong")
    assert(wrong.shakeT > 0, "wrong animal should shake")
    assert(state.phase == "playing", "a wrong tap should not end the round")
    render.draw(state)

    local completed = false
    for _ = 1, #state.animals do
        local action = tapAnimal(state, state.find.target)
        if action == "complete" then
            completed = true
            break
        end
        assert(action == "correct", "expected correct, got " .. tostring(action))
        render.draw(state)
    end
    assert(completed, "finding every animal should complete the round")
    assert(state.phase == "celebrating", "round completion should celebrate")
    assert(state.find.foundCount == #state.animals, "found count should equal animal count")

    input.begin(state, nil, 640, 360)
    assert(input.finish(state, nil, 640, 360) == "continue", "tap should continue")
    stateModule.restart(state)
    assert(state.phase == "playing", "restart should resume play")
    assert(state.find.foundCount == 0, "restart should reset progress")
    assert(state.find.target, "restart should ask a new prompt")
    render.draw(state)
    print("ok: find wrong/correct/complete/restart")
end

print("FARM HARNESS PASSED")
