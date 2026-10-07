local audio = {}

local function language(state)
    return state.context.i18n:getLanguage()
end

function audio.playIntro(state)
    state.context.audio:play(string.format("numbers.%s.intro", language(state)))
end

function audio.playPickup(state)
    state.context.audio:play("numbers.common.pickup")
end

function audio.playPlace(state)
    state.context.audio:play("numbers.common.place")
end

function audio.playCorrect(state, value)
    state.context.audio:play(string.format("numbers.%s.correct", language(state)))
    if value then
        state.context.audio:play(string.format("numbers.%s.number.%d", language(state), value))
    end
end

function audio.playCelebrate(state)
    state.context.audio:play(string.format("numbers.%s.celebrate", language(state)))
end

return audio
