local decks = require("src.data.content.alphabet_decks")

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
                volume = 0.2
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
    }
}
