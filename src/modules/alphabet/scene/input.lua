local drawUtils = require("src.ui.draw_utils")

local input = {}

local TAP_THRESHOLD = 25

local function findCardIndex(state, x, y)
    for index, card in ipairs(state.cards) do
        if drawUtils.contains(card.rect, x, y) then
            return index
        end
    end

    return nil
end

function input.begin(state, pointerId, x, y)
    if state.activeTouchId and pointerId ~= nil then
        return
    end

    state.activeTouchId = pointerId
    state.pointer = { startX = x, startY = y, cardIndex = findCardIndex(state, x, y) }
end

function input.finish(state, pointerId, x, y)
    if pointerId ~= nil and state.activeTouchId and pointerId ~= state.activeTouchId then
        return nil
    end

    local pointer = state.pointer
    state.pointer = nil
    state.activeTouchId = nil

    if not pointer then
        return nil
    end

    local deltaX = x - pointer.startX
    local deltaY = y - pointer.startY

    if math.abs(deltaX) > TAP_THRESHOLD or math.abs(deltaY) > TAP_THRESHOLD then
        return nil
    end

    local releasedCardIndex = findCardIndex(state, x, y)
    if pointer.cardIndex and releasedCardIndex and pointer.cardIndex == releasedCardIndex then
        return {
            type = "flip",
            cardIndex = releasedCardIndex
        }
    end

    return nil
end

function input.isBackPressed(state, x, y)
    return drawUtils.contains(state.backButton, x, y)
end

return input
