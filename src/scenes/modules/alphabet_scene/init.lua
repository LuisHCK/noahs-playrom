local Button = require("src.ui.button")
local stateFactory = require("src.scenes.modules.alphabet_scene.state")
local input = require("src.scenes.modules.alphabet_scene.input")
local render = require("src.scenes.modules.alphabet_scene.render")
local audio = require("src.scenes.modules.alphabet_scene.audio")

local scene = {}
-- Delay card voice slightly so it does not overlap the flip SFX.
local CARD_AUDIO_DELAY = 0.18

-- Handles high-level actions emitted by input and triggers side effects.
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
    -- Create scene state and hook the back button to return to main menu.
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

    -- Intro audio is played once when entering the scene.
    audio.playIntro(self.state)
end

function scene:draw()
    render.draw(self.state)
end

function scene:update(dt)
    -- Drain queued card audio after the configured delay.
    if self.state.pendingCardAudio then
        local pending = self.state.pendingCardAudio
        pending.delay = pending.delay - dt

        if pending.delay <= 0 then
            if pending.side == "letter" then
                audio.playCurrentLetter(self.state, pending.card)
            else
                audio.playCurrentObject(self.state, pending.card)
            end

            self.state.pendingCardAudio = nil
        end
    end

    -- Advance flip animations and queue audio for cards that just finished flipping.
    local completed = stateFactory.update(self.state, dt)
    for _, card in ipairs(completed) do
        self.state.pendingCardAudio = {
            card = card,
            side = card.isFront and "letter" or "object",
            delay = CARD_AUDIO_DELAY
        }
    end
end

function scene:mousepressed(x, y)
    self.state.backButton:press(x, y)
    input.begin(self.state, nil, x, y)
end

function scene:mousereleased(x, y)
    self.state.backButton:release(x, y)
    -- Ignore card interactions when the back button is released.
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
    -- Ignore card interactions when the back button is released.
    if input.isBackPressed(self.state, x, y) then
        return
    end

    handleAction(self.state, input.finish(self.state, id, x, y))
end

function scene:keypressed(key)
    -- Keyboard shortcut to quickly test the first card flip.
    if key == "space" and self.state.cards[1] then
        handleAction(self.state, { type = "flip", cardIndex = 1 })
    end
end

return scene
