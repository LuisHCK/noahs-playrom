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
        getInfo = function(path) if path and (path:find("numbers%-spritesheet") or path:find("dots%-spritesheet")) then return { type = "file" } end return nil end,
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

local config = require("src.modules.numbers.content.config")
local layoutModule = require("src.modules.numbers.scene.layout")
local stateModule = require("src.modules.numbers.scene.state")
local input = require("src.modules.numbers.scene.input")
local render = require("src.modules.numbers.scene.render")

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

local function findPiece(state, kind, value)
    for _, piece in ipairs(state.pieces) do
        if piece.kind == kind and piece.value == value then
            return piece
        end
    end
    return nil
end

local function dragTogether(state, value)
    local number = assert(findPiece(state, "number", value), "missing number " .. value)
    local object = assert(findPiece(state, "dots", value), "missing object " .. value)
    local targetX = object.x + object.width * 0.5
    local targetY = object.y + object.height * 0.5
    assert(input.begin(state, nil, number.x + number.width * 0.5, number.y + number.height * 0.5) == "pickup")
    input.move(state, nil, targetX, targetY)
    return input.finish(state, nil, targetX, targetY)
end

-- 1) Wrong drop must not pair.
do
    local state = newState()
    local number = findPiece(state, "number", 1)
    local wrongObject = findPiece(state, "dots", 2)
    local rightObject = findPiece(state, "dots", 1)
    rightObject.x, rightObject.y = 9999, 9999
    number.x = wrongObject.x + (wrongObject.width - number.width) * 0.5
    number.y = wrongObject.y + (wrongObject.height - number.height) * 0.5
    assert(stateModule.tryMatch(state, number) == false, "wrong drop paired")
    assert(state.completedCount == 0, "wrong drop counted")
    print("ok: wrong drop does not pair")
end

-- 2) Clear both stages to reach the final celebration.
do
    local state = newState()
    render.draw(state)

    local stageCount = #state.stages
    assert(stageCount >= 2, "expected multiple stages, got " .. stageCount)

    for stageIndex = 1, stageCount do
        local stage = state.stages[stageIndex]
        for _, value in ipairs(stage) do
            local action = dragTogether(state, value)
            assert(action == "matched", "value " .. value .. " -> " .. tostring(action))
        end

        if stageIndex < stageCount then
            assert(state.phase == "stageComplete", "stage " .. stageIndex .. " did not complete")
            for _ = 1, 40 do
                stateModule.update(state, 0.1)
            end
            assert(state.currentStage == stageIndex + 1, "did not advance stage")
        end
        render.draw(state)
    end

    assert(state.completedCount == 10, "expected 10 total matches, got " .. state.completedCount)
    assert(state.phase == "celebrating", "expected celebrating, got " .. state.phase)
    render.draw(state)
    print("ok: cleared both stages and reached the final celebration")
end

-- 3) Tap during celebration restarts from stage 1.
do
    local state = newState()
    for stageIndex = 1, #state.stages do
        for _, value in ipairs(state.stages[stageIndex]) do
            dragTogether(state, value)
        end
        if stageIndex < #state.stages then
            for _ = 1, 40 do
                stateModule.update(state, 0.1)
            end
        end
    end
    assert(state.phase == "celebrating")

    input.begin(state, nil, 100, 100)
    local action = input.finish(state, nil, 100, 100)
    assert(action == "continue", "expected continue, got " .. tostring(action))
    stateModule.startOver(state)
    assert(state.currentStage == 1 and state.completedCount == 0 and state.phase == "playing")
    print("ok: tap after celebration restarts at stage 1")
end

-- 4) Proximity highlight for any opposite piece; connect only on drop.
do
    local state = newState()
    local number = findPiece(state, "number", 1)
    local wrong = findPiece(state, "dots", 2)

    input.begin(state, nil, number.x + number.width * 0.5, number.y + number.height * 0.5)
    input.move(state, nil, wrong.x + wrong.width * 0.5, wrong.y + wrong.height * 0.5)
    assert(state.connectCandidate == wrong, "expected non-matching candidate to highlight")
    render.draw(state)
    local action = input.finish(state, nil, wrong.x + wrong.width * 0.5, wrong.y + wrong.height * 0.5)
    assert(action == "dropped", "non-matching drop should not connect")
    assert(state.connectCandidate == nil, "candidate not cleared after drop")
    assert(not number.paired and not wrong.paired, "pieces paired without a value match")
    print("ok: proximity highlights any opposite piece; connection only on drop")
end

print("NUMBERS HARNESS PASSED")
