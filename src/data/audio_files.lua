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
    for _, key in ipairs(keys) do
        names[key] = string.format("assets/audio/%s/farm/names/%s.ogg", lang, key)
    end

    return {
        intro = string.format("assets/audio/%s/farm/intro.wav", lang),
        correct = string.format("assets/audio/%s/farm/correct.wav", lang),
        celebrate = string.format("assets/audio/%s/farm/celebrate.wav", lang),
        name = names
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
                tap = "assets/audio/common/sfx/flip.wav",
                swipe = "assets/audio/common/sfx/swipe.wav",
                wrong = "assets/audio/common/sfx/flip.wav"
            },
            sound = buildFarmSounds(farmKeys)
        },
        en = buildFarmLanguage("en", farmKeys),
        es = buildFarmLanguage("es", farmKeys)
    }
}
