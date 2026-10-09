local audio = {}

local FIND_NEXT_DELAY = 1.0

local function language(state)
    return state.context.i18n:getLanguage()
end

local function key(state, suffix)
    return string.format("farm.%s.%s", language(state), suffix)
end

local function promptKeys(state, animalKey, prompt)
    local keys = {}
    if prompt == "name" then
        keys[#keys + 1] = key(state, "question")
        keys[#keys + 1] = key(state, "nameQuestion." .. animalKey)
    else
        keys[#keys + 1] = key(state, "listen")
        keys[#keys + 1] = "farm.common.sound." .. animalKey
    end
    return keys
end

local function appendNextPrompt(state, keys)
    if state.mode == "find" and state.find and state.find.target then
        for _, item in ipairs(promptKeys(state, state.find.target.key, state.find.prompt)) do
            keys[#keys + 1] = item
        end
    end
end

function audio.playIntro(state)
    state.context.audio:playSequence({
        key(state, "intro"),
        key(state, "modeExplore")
    })
end

function audio.playAnimalSound(state, animalKey)
    state.context.audio:play("farm.common.sound." .. animalKey)
end

function audio.playAnimalName(state, animalKey)
    state.context.audio:play(key(state, "name." .. animalKey))
end

function audio.playModeIntro(state, mode)
    local ids = {
        explore = "modeExplore",
        learn = "modeLearn",
        find = "modeFind"
    }

    local id = ids[mode]
    if not id then
        return
    end

    local keys = { key(state, id) }
    if mode == "find" then
        appendNextPrompt(state, keys)
    end
    state.context.audio:playSequence(keys)
end

function audio.playPrompt(state, animalKey, prompt)
    state.context.audio:playSequence(promptKeys(state, animalKey, prompt))
end

function audio.playCorrect(state)
    local core = state.context.audio
    local correctKey = key(state, "correct")
    local keys = { correctKey }

    -- Show "Correct" until the next prompt actually starts speaking.
    local feedback = core:getDuration(correctKey)
    if state.lastAnimal then
        local nameKey = key(state, "name." .. state.lastAnimal.key)
        keys[#keys + 1] = nameKey
        feedback = feedback + core:getDuration(nameKey)
    end
    feedback = feedback + 2 * core.sequenceGap + FIND_NEXT_DELAY
    if state.find then
        state.find.feedbackTimer = feedback
    end

    -- Give the child a beat after the correct answer before the next prompt.
    keys[#keys + 1] = FIND_NEXT_DELAY
    appendNextPrompt(state, keys)
    core:playSequence(keys)
end

function audio.playWrong(state)
    if not state.context.audio:play(key(state, "wrong")) then
        state.context.audio:play("farm.common.sfx.wrong")
    end
end

function audio.playCelebrate(state)
    local keys = { key(state, "correct") }
    if state.lastAnimal then
        keys[#keys + 1] = key(state, "name." .. state.lastAnimal.key)
    end
    keys[#keys + 1] = key(state, "celebrate")
    state.context.audio:playSequence(keys)
end

return audio
