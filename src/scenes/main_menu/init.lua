local layout = require("src.scenes.main_menu.layout")
local model = require("src.scenes.main_menu.model")
local input = require("src.scenes.main_menu.input")
local render = require("src.scenes.main_menu.render")

local menu = {}

function menu:load(context)
    self.layout = layout.build()
    self.state = model.createState(context, self.layout)
end

function menu:update(dt)
    -- Smooth press/release scale animation for tiles.
    local animationSpeed = 12
    for _, button in ipairs(self.state.moduleButtons) do
        local target = button.pressed and 0.96 or 1
        button.visualScale = button.visualScale + (target - button.visualScale) * math.min(1, dt * animationSpeed)
    end

    -- Transition timer gate (starts on tile click).
    if self.state.transitionTimer > 0 then
        self.state.transitionTimer = math.max(0, self.state.transitionTimer - dt)
        if self.state.transitionTimer == 0 and self.state.queuedScene then
            self.state.nextScene = self.state.queuedScene
            self.state.queuedScene = nil
        end
    end

    -- Execute scene change once timer completes.
    if self.state.nextScene then
        local nextScene = self.state.nextScene
        self.state.nextScene = nil
        self.setScene(nextScene, self.state.context)
    end
end

function menu:draw()
    render.draw(self.state)
end

function menu:mousepressed(x, y)
    input.press(self.state, x, y)
end

function menu:mousereleased(x, y)
    input.release(self.state, x, y)
end

function menu:touchpressed(_, x, y)
    input.press(self.state, x, y)
end

function menu:touchreleased(_, x, y)
    input.release(self.state, x, y)
end

function menu:keypressed(key)
    if key == "p" then
        self.state.toggleAssetProfile()
    end
end

return menu
