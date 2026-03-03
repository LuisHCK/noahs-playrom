local Button = require("src.ui.button")
local stateFactory = require("src.scenes.modules.alphabet_scene.state")
local input = require("src.scenes.modules.alphabet_scene.input")
local render = require("src.scenes.modules.alphabet_scene.render")
local audio = require("src.scenes.modules.alphabet_scene.audio")

local scene = {}

local function handleAction(state, action)
    if action and action.type == "flip" then
        local card = stateFactory.flipCard(state, action.cardIndex)
        if not card then
            return
        end

        audio.playFlip(state)
    end
end

function scene:load(context)
    self.state = stateFactory.create(context)
    self.state.backButton = Button.new({
        id = "back",
        x = 40,
        y = 40,
        width = 140,
        height = 50,
        onClick = function()
            self.setScene("main_menu", context)
        end
    })

    audio.playIntro(self.state)
end

function scene:draw()
    render.draw(self.state)
end

function scene:update(dt)
    local completed = stateFactory.update(self.state, dt)
    for _, card in ipairs(completed) do
        if card.isFront then
            audio.playCurrentLetter(self.state, card)
        else
            audio.playCurrentObject(self.state, card)
        end
    end
end

function scene:mousepressed(x, y)
    self.state.backButton:press(x, y)
    input.begin(self.state, nil, x, y)
end

function scene:mousereleased(x, y)
    self.state.backButton:release(x, y)
    if input.isBackPressed(self.state, x, y) then
        return
    end

    handleAction(self.state, input.finish(self.state, nil, x, y))
end

function scene:touchpressed(id, x, y)
    self.state.backButton:press(x, y)
    input.begin(self.state, id, x, y)
end

function scene:touchreleased(id, x, y)
    self.state.backButton:release(x, y)
    if input.isBackPressed(self.state, x, y) then
        return
    end

    handleAction(self.state, input.finish(self.state, id, x, y))
end

function scene:keypressed(key)
    if key == "space" and self.state.cards[1] then
        handleAction(self.state, { type = "flip", cardIndex = 1 })
    end
end

return scene
