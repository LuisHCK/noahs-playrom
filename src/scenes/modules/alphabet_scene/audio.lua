local audio = {}

function audio.playIntro(state)
    local key = string.format("alphabet.%s.intro", state.language)
    state.context.audio:play(key)
end

function audio.playSwipe(state)
    state.context.audio:play("common.sfx.swipe")
end

function audio.playFlip(state)
    state.context.audio:play("common.sfx.flip")
end

function audio.playCurrentLetter(state, card)
    if not card then
        return
    end

    local letterKey = string.format("alphabet.%s.letters.%s", state.language, card.key)
    local ok = state.context.audio:play(letterKey)
    if not ok then
        state.context.audio:play("common.sfx.flip")
    end
end

function audio.playCurrentObject(state, card)
    if not card then
        return
    end

    local objectKey = string.format("alphabet.%s.objects.%s", state.language, card.key)
    local ok = state.context.audio:play(objectKey)
    if not ok then
        state.context.audio:play("common.sfx.flip")
    end
end

return audio
