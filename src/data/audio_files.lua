local function buildAlphabetLanguage(lang, keys)
    local letters = {}
    local objects = {}

    for _, key in ipairs(keys) do
        letters[key] = string.format("assets/audio/%s/alphabet/letters/%s.wav", lang, key)
        objects[key] = string.format("assets/audio/%s/alphabet/objects/%s.wav", lang, key)
    end

    return {
        intro = string.format("assets/audio/%s/alphabet/intro.wav", lang),
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
                volume = 0.4
            }
        }
    },
    alphabet = {
        common = {
            flip = "assets/audio/common/sfx/flip.wav",
            swipe = "assets/audio/common/sfx/swipe.wav"
        },
        en = buildAlphabetLanguage("en", {
            "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
            "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
        }),
        es = buildAlphabetLanguage("es", {
            "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
            "n", "ntilde", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
        })
    }
}
