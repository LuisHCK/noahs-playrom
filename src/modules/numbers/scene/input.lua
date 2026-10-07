local stateModule = require("src.modules.numbers.scene.state")

local input = {}

local function clampToContent(state, piece)
    local content = state.layout.content
    local minX = content.x
    local minY = content.y
    local maxX = content.x + content.width - piece.width
    local maxY = content.y + content.height - piece.height

    piece.x = math.max(minX, math.min(maxX, piece.x))
    piece.y = math.max(minY, math.min(maxY, piece.y))
end

function input.begin(state, pointerId, x, y)
    if state.phase == "celebrating" then
        state.pendingContinue = true
        return nil
    end

    if state.phase ~= "playing" then
        return nil
    end

    if state.drag then
        return nil
    end

    local piece = stateModule.pieceAt(state, x, y)
    if not piece then
        return nil
    end

    state.drag = {
        piece = piece,
        pointerId = pointerId,
        offsetX = x - piece.x,
        offsetY = y - piece.y
    }
    state.connectCandidate = nil
    piece.dragging = true
    return "pickup"
end

function input.move(state, pointerId, x, y)
    local drag = state.drag
    if not drag then
        return
    end
    if pointerId ~= nil and drag.pointerId ~= nil and pointerId ~= drag.pointerId then
        return
    end

    drag.piece.x = x - drag.offsetX
    drag.piece.y = y - drag.offsetY
    clampToContent(state, drag.piece)
    state.connectCandidate = stateModule.findConnectCandidate(state, drag.piece)
end

function input.finish(state, pointerId, x, y)
    if state.pendingContinue then
        state.pendingContinue = false
        return "continue"
    end

    local drag = state.drag
    if not drag then
        return nil
    end
    if pointerId ~= nil and drag.pointerId ~= nil and pointerId ~= drag.pointerId then
        return nil
    end

    state.drag = nil
    drag.piece.dragging = false

    local connected = stateModule.tryMatch(state, drag.piece)
    state.connectCandidate = nil

    if connected then
        state.lastMatchedValue = drag.piece.value
        return "matched"
    end

    return "dropped"
end

return input
