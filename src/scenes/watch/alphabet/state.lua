local decks = require("src.data.content.alphabet_decks")

local state = {}
local FLIP_DURATION = 0.45
local SWIPE_ANIM_DURATION = 0.25

local spriteIndexByKey = {
    a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8, i = 9, j = 10,
    k = 11, l = 12, m = 13, n = 14, ntilde = 15, o = 16, p = 17, q = 18,
    r = 19, s = 20, t = 21, u = 22, v = 23, w = 24, x = 25, y = 26, z = 27
}

function state.create(context)
    local language = context.i18n:getLanguage()
    local deck = decks[language] or decks.en

    local cards = {}
    for _, card in ipairs(deck) do
        cards[#cards + 1] = {
            letter = card.letter,
            object = card.object,
            key = card.key,
            spriteIndex = spriteIndexByKey[card.key],
            isFront = true
        }
    end

    return {
        deck = cards,
        currentIndex = 1,
        flip = { active = false, time = 0, duration = FLIP_DURATION, swapped = false, targetIsFront = true },
        isFlipLocked = false,
        swipeAnim = { active = false, progress = 0, direction = 1 },
        pendingAudio = nil,
        language = language,
        context = context,
        activeTouchId = nil,
        touchStartX = 0,
        touchStartY = 0,
        touchCurrentX = nil
    }
end

function state.currentCard(s)
    return s.deck[s.currentIndex]
end

function state.navigate(s, direction)
    if s.isFlipLocked or s.swipeAnim.active then
        return
    end
    local total = #s.deck
    s.currentIndex = ((s.currentIndex - 1 + direction + total) % total) + 1
    s.pendingAutoLetter = s.deck[s.currentIndex]
    s.swipeAnim.active = true
    s.swipeAnim.progress = 0
    s.swipeAnim.direction = direction
end

function state.flipCurrent(s)
    if s.isFlipLocked or s.flip.active then
        return
    end
    s.flip.active = true
    s.flip.time = 0
    s.flip.swapped = false
    s.flip.targetIsFront = not s.deck[s.currentIndex].isFront
    s.isFlipLocked = true
end

function state.update(s, dt)
    -- Advance flip animation.
    if s.flip.active then
        s.flip.time = math.min(s.flip.time + dt, s.flip.duration)
        local progress = s.flip.time / s.flip.duration
        if not s.flip.swapped and progress >= 0.5 then
            local card = state.currentCard(s)
            card.isFront = s.flip.targetIsFront
            s.flip.swapped = true
        end
        if progress >= 1 then
            s.flip.active = false
            s.isFlipLocked = false
            return state.currentCard(s)
        end
        return nil
    end

    -- Advance swipe animation.
    if s.swipeAnim.active then
        s.swipeAnim.progress = math.min(s.swipeAnim.progress + dt / SWIPE_ANIM_DURATION, 1)
        if s.swipeAnim.progress >= 1 then
            s.swipeAnim.active = false
            local card = s.pendingAutoLetter
            s.pendingAutoLetter = nil
            s.touchCurrentX = nil
            return nil, card
        end
    end

    return nil
end

return state
