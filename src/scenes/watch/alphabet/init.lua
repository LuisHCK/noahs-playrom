local stateModule = require("src.scenes.watch.alphabet.state")
local layoutModule = require("src.scenes.watch.alphabet.layout")
local inputModule = require("src.scenes.watch.alphabet.input")
local renderModule = require("src.scenes.watch.alphabet.render")
local audio = require("src.scenes.modules.alphabet_scene.audio")

local scene = {}
local CARD_AUDIO_DELAY = 0.18

function scene:load(context)
    self.context = context
    self.state = stateModule.create(context)
    self.layout = layoutModule.build(context.viewport)
    self.viewportSnapshot = { w = context.viewport.width, h = context.viewport.height }

    audio.playIntro(self.state)

    -- Queue letter audio for first card with 1s delay on initial load.
    local firstCard = self.state.deck[1]
    firstCard.playedAutoLetter = true
    self.state.pendingAudio = {
        card = firstCard,
        side = "letter",
        delay = 1.0
    }
end

function scene:resize()
    self.layout = layoutModule.build(self.context.viewport)
end

function scene:update(dt)
    local vp = self.context.viewport
    if vp.width ~= self.viewportSnapshot.w or vp.height ~= self.viewportSnapshot.h then
        self.layout = layoutModule.build(vp)
        self.viewportSnapshot.w = vp.width
        self.viewportSnapshot.h = vp.height
    end

    -- Advance pending audio timer.
    if self.state.pendingAudio then
        self.state.pendingAudio.delay = self.state.pendingAudio.delay - dt
        if self.state.pendingAudio.delay <= 0 then
            local p = self.state.pendingAudio
            if p.side == "letter" then
                audio.playCurrentLetter(self.state, p.card)
            else
                audio.playCurrentObject(self.state, p.card)
            end
            self.state.pendingAudio = nil
        end
    end

    -- Advance flip/swipe animations.
    local completedCard, autoLetterCard = stateModule.update(self.state, dt)
    if completedCard then
        -- Flip completed: queue letter/object audio with short delay.
        self.state.pendingAudio = {
            card = completedCard,
            side = completedCard.isFront and "letter" or "object",
            delay = CARD_AUDIO_DELAY
        }
    end
    if autoLetterCard then
        -- Swipe landed on a card whose letter hasn't been played yet.
        autoLetterCard.playedAutoLetter = true
        self.state.pendingAudio = {
            card = autoLetterCard,
            side = "letter",
            delay = 0
        }
    end
end

function scene:draw()
    renderModule.draw(self.state, self.layout)
end

function scene:mousepressed(x, y)
    inputModule.begin(self.state, self.layout, "mouse", x, y)
end

function scene:mousereleased(x, y)
    local act = inputModule.finish(self.state, self.layout, "mouse", x, y)
    if act == "flip" then
        audio.playFlip(self.state)
    elseif act == "swipe" then
        audio.playSwipe(self.state)
    elseif act == "back" then
        self.setScene("watch_main_menu", self.context)
    end
end

function scene:touchpressed(id, x, y)
    inputModule.begin(self.state, self.layout, id, x, y)
end

function scene:touchreleased(id, x, y)
    local act = inputModule.finish(self.state, self.layout, id, x, y)
    if act == "flip" then
        audio.playFlip(self.state)
    elseif act == "swipe" then
        audio.playSwipe(self.state)
    elseif act == "back" then
        self.setScene("watch_main_menu", self.context)
    end
end

function scene:touchmoved(id, x, y)
    inputModule.move(self.state, self.layout, id, x, y)
end

return scene
