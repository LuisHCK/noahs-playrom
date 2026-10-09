local decks = require("src.modules.alphabet.content.decks")
local farmContent = require("src.modules.farm.content.farm")

local function buildAlphabetLanguage(lang, cards)
    local letters = {}
    local objects = {}

    for _, card in ipairs(cards) do
        letters[card.key] = card.audio.front
        objects[card.key] = card.audio.back
    end

    return {
        intro = string.format("assets/audio/%s/alphabet/intro.wav", lang),
        flip = string.format("assets/audio/%s/alphabet/flip.wav", lang),
        swipe = string.format("assets/audio/%s/alphabet/swipe.wav", lang),
        letters = letters,
        objects = objects
    }
end

local function buildNumbersLanguage(lang)
    local numbers = {}
    for value = 1, 10 do
        numbers[tostring(value)] = string.format("assets/audio/%s/numbers/%d.ogg", lang, value)
    end

    return {
        intro = string.format("assets/audio/%s/numbers/intro.wav", lang),
        correct = string.format("assets/audio/%s/numbers/correct.wav", lang),
        celebrate = string.format("assets/audio/%s/numbers/celebrate.wav", lang),
        number = numbers
    }
end

local function farmAnimalKeys()
    local keys = {}
    for _, animal in ipairs(farmContent.animals) do
        keys[#keys + 1] = animal.key
    end
    return keys
end

local function buildFarmSounds(keys)
    local sounds = {}
    for _, key in ipairs(keys) do
        sounds[key] = string.format("assets/audio/sfx/farm/%s.ogg", key)
    end
    return sounds
end

local function buildFarmLanguage(lang, keys)
    local names = {}
    local namesQuestion = {}
    for _, key in ipairs(keys) do
        names[key] = string.format("assets/audio/%s/farm/names/%s.ogg", lang, key)
        namesQuestion[key] = string.format("assets/audio/%s/farm/names_question/%s.ogg", lang, key)
    end

    local base = string.format("assets/audio/%s/farm", lang)
    return {
        intro = base .. "/intro.ogg",
        correct = base .. "/correct.ogg",
        celebrate = base .. "/celebrate.ogg",
        wrong = base .. "/wrong.ogg",
        question = base .. "/question.ogg",
        listen = base .. "/listen.ogg",
        modeExplore = base .. "/mode_explore.ogg",
        modeLearn = base .. "/mode_learn.ogg",
        modeFind = base .. "/mode_find.ogg",
        name = names,
        nameQuestion = namesQuestion
    }
end

local farmKeys = farmAnimalKeys()

return {
    common = {
        sfx = {
            flip = "assets/audio/common/sfx/flip.wav",
            swipe = "assets/audio/common/sfx/swipe.wav"
        },
        bgm = {
            menu = {
                path = "assets/audio/common/bgm/menu.ogg",
                mode = "stream",
                loop = true,
                volume = 0.1
            }
        }
    },
    alphabet = {
        common = {
            flip = "assets/audio/common/sfx/flip.wav",
            swipe = "assets/audio/common/sfx/swipe.wav"
        },
        en = buildAlphabetLanguage("en", decks.en),
        es = buildAlphabetLanguage("es", decks.es)
    },
    numbers = {
        common = {
            pickup = "assets/audio/common/sfx/flip.wav",
            place = "assets/audio/common/sfx/flip.wav"
        },
        en = buildNumbersLanguage("en"),
        es = buildNumbersLanguage("es")
    },
    farm = {
        common = {
            sfx = {
                swipe = "assets/audio/common/sfx/swipe.wav",
                wrong = "assets/audio/common/sfx/flip.wav"
            },
            sound = buildFarmSounds(farmKeys)
        },
        en = buildFarmLanguage("en", farmKeys),
        es = buildFarmLanguage("es", farmKeys)
    }
}
