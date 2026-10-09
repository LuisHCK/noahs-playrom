local scene_shell = require("src.core.scene_shell")
local layout = require("src.modules.farm.scene.layout")
local stateModule = require("src.modules.farm.scene.state")
local input = require("src.modules.farm.scene.input")
local render = require("src.modules.farm.scene.render")
local audio = require("src.modules.farm.scene.audio")

local scene = {}

local function playFindPrompt(state)
    if state.find and state.find.target then
        audio.playPrompt(state, state.find.target.key, state.find.prompt)
    end
end

local function handleAction(state, action)
    if not action then
        return
    end

    if action == "sound" then
        if state.lastAnimal then
            audio.playAnimalSound(state, state.lastAnimal.key)
        end
    elseif action == "name" then
        if state.lastAnimal then
            audio.playAnimalName(state, state.lastAnimal.key)
        end
    elseif action == "correct" then
        audio.playCorrect(state)
    elseif action == "wrong" then
        audio.playWrong(state)
    elseif action == "complete" then
        audio.playCelebrate(state)
    elseif action == "repeat" then
        playFindPrompt(state)
    elseif action == "continue" then
        stateModule.restart(state)
        if state.mode == "find" then
            playFindPrompt(state)
        end
    elseif action:sub(1, 5) == "mode:" then
        local modeId = action:sub(6)
        stateModule.setMode(state, modeId)
        audio.playModeIntro(state, modeId)
    end
end

function scene:load(context)
    self.context = context
    self.layout = layout.build(context.viewport)
    self.state = stateModule.create(context, self.layout)
    self.state.backButton = scene_shell.buildBackButton(function()
        self.setScene("main_menu", context)
    end)

    audio.playIntro(self.state)
end

function scene:update(dt)
    local viewport = self.context.viewport
    local snapshot = self.state.viewportSnapshot
    if viewport.width ~= snapshot.w or viewport.height ~= snapshot.h then
        snapshot.w = viewport.width
        snapshot.h = viewport.height
        self.layout = layout.build(viewport)
        self.state.layout = self.layout
    end

    stateModule.update(self.state, dt)
end

function scene:draw()
    render.draw(self.state)
end

function scene:mousepressed(x, y)
    self.state.backButton:press(x, y)
    if self.state.backButton.pressed then
        return
    end
    input.begin(self.state, nil, x, y)
end

function scene:mousereleased(x, y)
    self.state.backButton:release(x, y)
    handleAction(self.state, input.finish(self.state, nil, x, y))
end

function scene:mousemoved(x, y)
    input.move(self.state, nil, x, y)
end

function scene:touchpressed(id, x, y)
    self.state.backButton:press(x, y)
    if self.state.backButton.pressed then
        return
    end
    input.begin(self.state, id, x, y)
end

function scene:touchreleased(id, x, y)
    self.state.backButton:release(x, y)
    handleAction(self.state, input.finish(self.state, id, x, y))
end

function scene:touchmoved(id, x, y)
    input.move(self.state, id, x, y)
end

function scene:keypressed(key)
    input.key(self.state, key)
end

function scene:wheelmoved(_, dy)
    input.wheel(self.state, nil, dy)
end

return scene
