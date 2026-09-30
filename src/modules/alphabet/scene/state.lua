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

local function buildGrid(deck, content)
    local columns = 9
    local rows = math.ceil(#deck / columns)
    local gap = 10
    local startX = content.x + 40
    local startY = content.y + 130
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

local function layoutCards(cards, content)
    local columns = 9
    local rows = math.ceil(#cards / columns)
    local gap = 10
    local startX = content.x + 40
    local startY = content.y + 130
    local areaWidth = 1200
    local areaHeight = 540
    local cardWidth = (areaWidth - (columns - 1) * gap) / columns
    local cardHeight = (areaHeight - (rows - 1) * gap) / rows

    for index, card in ipairs(cards) do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        card.rect.x = startX + column * (cardWidth + gap)
        card.rect.y = startY + row * (cardHeight + gap)
        card.rect.width = cardWidth
        card.rect.height = cardHeight
    end
end

function state.create(context)
    local language = context.i18n:getLanguage()
    local deck = decks[language] or decks.en
    local content = context.viewport:getContentArea()

    return {
        context = context,
        language = language,
        deck = deck,
        isFlipLocked = false,
        activeTouchId = nil,
        pointer = nil,
        pendingCardAudio = nil,
        contentLayout = {
            x = content.x,
            y = content.y,
            width = content.width,
            height = content.height
        },
        cards = buildGrid(deck, content)
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

function state.relayout(self)
    local content = self.context.viewport:getContentArea()
    layoutCards(self.cards, content)
    self.contentLayout.x = content.x
    self.contentLayout.y = content.y
    self.contentLayout.width = content.width
    self.contentLayout.height = content.height
end

function state.ensureLayout(self)
    local content = self.context.viewport:getContentArea()
    local layout = self.contentLayout
    if layout.x ~= content.x or layout.y ~= content.y or layout.width ~= content.width or layout.height ~= content.height then
        state.relayout(self)
    end
end

return state
