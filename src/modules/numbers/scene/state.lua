local config = require("src.modules.numbers.content.config")

local state = {}

local STAGE_ADVANCE_DELAY = 1.2

local function randomInt(n)
    if love and love.math and love.math.random then
        return love.math.random(n)
    end
    return math.random(n)
end

local function shuffledIndices(n)
    local order = {}
    for index = 1, n do
        order[index] = index
    end
    for index = n, 2, -1 do
        local swap = randomInt(index)
        order[index], order[swap] = order[swap], order[index]
    end
    return order
end

local function rectGap(a, b)
    -- Distance between the two rectangles' edges (0 when touching or overlapping).
    local dx = math.max(b.x - (a.x + a.width), a.x - (b.x + b.width), 0)
    local dy = math.max(b.y - (a.y + a.height), a.y - (b.y + b.height), 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function buildStages()
    local stages = {}
    local index = 1
    while index <= #config.values do
        local stage = {}
        for offset = 0, config.stageSize - 1 do
            local value = config.values[index + offset]
            if value then
                stage[#stage + 1] = value
            end
        end
        stages[#stages + 1] = stage
        index = index + config.stageSize
    end
    return stages
end

function state.deal(self)
    self.pieces = {}
    self.pulseTimers = {}
    self.drag = nil
    self.activeTouchId = nil
    self.connectCandidate = nil
    self.stageCompleted = 0
    self.lastMatchedValue = nil
    self.phase = "playing"

    local stage = self.stages[self.currentStage]
    local numberOrder = shuffledIndices(#self.layout.numberSlots)
    local dotsOrder = shuffledIndices(#self.layout.dotsSlots)

    for valueIndex, value in ipairs(stage) do
        local numberSlot = self.layout.numberSlots[numberOrder[valueIndex]]
        local dotsSlot = self.layout.dotsSlots[dotsOrder[valueIndex]]

        self.pieces[#self.pieces + 1] = {
            id = "number-" .. value,
            kind = "number",
            value = value,
            x = numberSlot.x,
            y = numberSlot.y,
            width = numberSlot.width,
            height = numberSlot.height,
            paired = false
        }

        self.pieces[#self.pieces + 1] = {
            id = "dots-" .. value,
            kind = "dots",
            value = value,
            x = dotsSlot.x,
            y = dotsSlot.y,
            width = dotsSlot.width,
            height = dotsSlot.height,
            paired = false
        }
    end
end

function state.create(context, layout)
    local self = {
        context = context,
        layout = layout,
        stages = buildStages(),
        currentStage = 1,
        pieces = {},
        stageCompleted = 0,
        completedCount = 0,
        celebrateTimer = 0,
        stageTimer = 0,
        pulseTimers = {},
        drag = nil,
        activeTouchId = nil,
        connectCandidate = nil,
        phase = "dealing",
        viewportSnapshot = {
            w = context.viewport.width,
            h = context.viewport.height
        }
    }

    state.deal(self)
    return self
end

function state.startOver(self)
    self.currentStage = 1
    self.completedCount = 0
    state.deal(self)
end

function state.pieceAt(self, x, y)
    for index = #self.pieces, 1, -1 do
        local piece = self.pieces[index]
        if not piece.paired
            and x >= piece.x and x <= piece.x + piece.width
            and y >= piece.y and y <= piece.y + piece.height then
            return piece
        end
    end
    return nil
end

local function pair(self, dragged, target)
    local numberPiece = dragged.kind == "number" and dragged or target
    local dotsPiece = dragged.kind == "dots" and dragged or target

    numberPiece.paired = true
    dotsPiece.paired = true
    numberPiece.partner = dotsPiece
    dotsPiece.partner = numberPiece

    numberPiece.x = dotsPiece.x - numberPiece.width - config.joinGap
    numberPiece.y = dotsPiece.y + (dotsPiece.height - numberPiece.height) * 0.5

    self.pulseTimers[numberPiece] = 0.7
    self.pulseTimers[dotsPiece] = 0.7
    self.stageCompleted = self.stageCompleted + 1
    self.completedCount = self.completedCount + 1

    local stage = self.stages[self.currentStage]
    if self.stageCompleted >= #stage then
        if self.currentStage < #self.stages then
            self.phase = "stageComplete"
            self.stageTimer = 0
        else
            self.phase = "celebrating"
            self.celebrateTimer = 0
        end
    end

    return true
end

function state.findNearest(self, piece, gap)
    local best = nil
    local bestGap = nil

    for _, other in ipairs(self.pieces) do
        if other ~= piece and not other.paired and other.kind ~= piece.kind then
            local currentGap = rectGap(piece, other)
            if currentGap <= gap and (bestGap == nil or currentGap < bestGap) then
                best = other
                bestGap = currentGap
            end
        end
    end

    return best
end

function state.findConnectCandidate(self, piece)
    -- Generous threshold: highlight while the pieces are still approaching.
    return state.findNearest(self, piece, config.highlightGap)
end

function state.tryMatch(self, piece)
    -- Tighter threshold: the connection only completes once dropped close enough.
    local best = state.findNearest(self, piece, config.connectGap)
    if best and best.value == piece.value then
        return pair(self, piece, best)
    end

    return false
end

function state.update(self, dt)
    for piece, remaining in pairs(self.pulseTimers) do
        local nextValue = remaining - dt
        if nextValue <= 0 then
            self.pulseTimers[piece] = nil
        else
            self.pulseTimers[piece] = nextValue
        end
    end

    if self.phase == "stageComplete" then
        self.stageTimer = self.stageTimer + dt
        if self.stageTimer >= STAGE_ADVANCE_DELAY then
            self.currentStage = self.currentStage + 1
            state.deal(self)
        end
    elseif self.phase == "celebrating" then
        self.celebrateTimer = self.celebrateTimer + dt
    end
end

return state
