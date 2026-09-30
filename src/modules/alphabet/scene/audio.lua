local audio = {}

function audio.playIntro(state)
    local key = string.format("alphabet.%s.intro", state.language)
    state.context.audio:play(key)
end

function audio.playSwipe(state)
    local swipeKey = string.format("alphabet.%s.swipe", state.language)
    local ok = state.context.audio:play(swipeKey)
    if not ok then
        state.context.audio:play("common.sfx.swipe")
    end
end

function audio.playFlip(state)
    state.context.audio:play("common.sfx.flip")
end

function audio.playCurrentLetter(state, card)
    if not card then
        return
    end

    local letterKey = string.format("alphabet.%s.letters.%s", state.language, card.key)
    state.context.audio:play(letterKey)
end

function audio.playCurrentObject(state, card)
    if not card then
        return
    end

    local objectKey = string.format("alphabet.%s.objects.%s", state.language, card.key)
    state.context.audio:play(objectKey)
end

return audio
