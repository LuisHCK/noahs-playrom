local scene_shell = require("src.core.scene_shell")
local layout = require("src.modules.numbers.scene.layout")
local stateModule = require("src.modules.numbers.scene.state")
local input = require("src.modules.numbers.scene.input")
local render = require("src.modules.numbers.scene.render")
local audio = require("src.modules.numbers.scene.audio")

local scene = {}

local function handleAction(state, action)
    if action == "pickup" then
        audio.playPickup(state)
    elseif action == "dropped" then
        audio.playPlace(state)
    elseif action == "matched" then
        audio.playCorrect(state, state.lastMatchedValue)
        if state.phase == "celebrating" then
            audio.playCelebrate(state)
        end
    elseif action == "continue" then
        stateModule.startOver(state)
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
        stateModule.deal(self.state)
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
    handleAction(self.state, input.begin(self.state, nil, x, y))
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
    handleAction(self.state, input.begin(self.state, id, x, y))
end

function scene:touchreleased(id, x, y)
    self.state.backButton:release(x, y)
    handleAction(self.state, input.finish(self.state, id, x, y))
end

function scene:touchmoved(id, x, y)
    input.move(self.state, id, x, y)
end

return scene
