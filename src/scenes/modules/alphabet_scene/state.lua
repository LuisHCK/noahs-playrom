local decks = require("src.data.content.alphabet_decks")

local state = {}
local FLIP_DURATION = 0.45
local spriteIndexByKey = {
    a = 1,
    b = 2,
    c = 3,
    d = 4,
    e = 5,
    f = 6,
    g = 7,
    h = 8,
    i = 9,
    j = 10,
    k = 11,
    l = 12,
    m = 13,
    n = 14,
    ntilde = 15,
    o = 16,
    p = 17,
    q = 18,
    r = 19,
    s = 20,
    t = 21,
    u = 22,
    v = 23,
    w = 24,
    x = 25,
    y = 26,
    z = 27
}

local function buildGrid(deck)
    local columns = 9
    local rows = math.ceil(#deck / columns)
    local gap = 10
    local startX = 40
    local startY = 130
    local areaWidth = 1200
    local areaHeight = 540
    local cardWidth = (areaWidth - (columns - 1) * gap) / columns
    local cardHeight = (areaHeight - (rows - 1) * gap) / rows

    local cards = {}
    for index, card in ipairs(deck) do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        cards[index] = {
            letter = card.letter,
            object = card.object,
            key = card.key,
            spriteIndex = spriteIndexByKey[card.key],
            isFront = true,
            flip = {
                active = false,
                time = 0,
                duration = FLIP_DURATION,
                swapped = false,
                targetIsFront = true
            },
            rect = {
                x = startX + column * (cardWidth + gap),
                y = startY + row * (cardHeight + gap),
                width = cardWidth,
                height = cardHeight
            }
        }
    end

    return cards
end

function state.create(context)
    local language = context.i18n:getLanguage()
    local deck = decks[language] or decks.en

    return {
        context = context,
        language = language,
        deck = deck,
        isFlipLocked = false,
        activeTouchId = nil,
        pointer = nil,
        pendingCardAudio = nil,
        cards = buildGrid(deck)
    }
end

function state.flipCard(self, cardIndex)
    if self.isFlipLocked then
        return nil
    end

    local card = self.cards[cardIndex]
    if not card then
        return nil
    end

    if card.flip.active then
        return nil
    end

    card.flip.active = true
    card.flip.time = 0
    card.flip.swapped = false
    card.flip.targetIsFront = not card.isFront
    self.isFlipLocked = true
    return card
end

function state.update(self, dt)
    local completed = {}
    local hasActiveFlip = false

    for _, card in ipairs(self.cards) do
        local flip = card.flip
        if flip.active then
            hasActiveFlip = true
            flip.time = math.min(flip.time + dt, flip.duration)
            local progress = flip.time / flip.duration

            if not flip.swapped and progress >= 0.5 then
                card.isFront = flip.targetIsFront
                flip.swapped = true
            end

            if progress >= 1 then
                flip.active = false
                completed[#completed + 1] = card
            end
        end
    end

    self.isFlipLocked = hasActiveFlip

    return completed
end

return state
