local audio = {}

local function language(state)
    return state.context.i18n:getLanguage()
end

function audio.playIntro(state)
    state.context.audio:play(string.format("farm.%s.intro", language(state)))
end

function audio.playTap(state)
    state.context.audio:play("farm.common.sfx.tap")
end

function audio.playWrong(state)
    state.context.audio:play("farm.common.sfx.wrong")
end

function audio.playAnimalSound(state, key)
    state.context.audio:play(string.format("farm.common.sound.%s", key))
end

function audio.playAnimalName(state, key)
    state.context.audio:play(string.format("farm.%s.name.%s", language(state), key))
end

function audio.playCorrect(state)
    state.context.audio:play(string.format("farm.%s.correct", language(state)))
end

function audio.playCelebrate(state)
    state.context.audio:play(string.format("farm.%s.celebrate", language(state)))
end

function audio.playPrompt(state, key, prompt)
    if prompt == "name" then
        audio.playAnimalName(state, key)
    else
        audio.playAnimalSound(state, key)
    end
end

return audio
