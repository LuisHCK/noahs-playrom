local modes = {}

modes.ids = { "explore", "learn", "find" }

local function randomInt(n)
    if love and love.math and love.math.random then
        return love.math.random(n)
    end
    return math.random(n)
end

function modes.shuffled(n)
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

function modes.nextPrompt(state)
    local find = state.find
    if not find then
        return nil
    end

    find.index = find.index + 1
    if find.index > #find.order then
        find.order = modes.shuffled(#state.animals)
        find.index = 1
    end

    local animal = state.animals[find.order[find.index]]
    -- Avoid asking for the same animal twice in a row.
    if find.lastKey and animal and animal.key == find.lastKey and #find.order > 1 then
        local nextIndex = find.index % #find.order + 1
        find.order[find.index], find.order[nextIndex] = find.order[nextIndex], find.order[find.index]
        animal = state.animals[find.order[find.index]]
    end

    find.target = animal
    find.lastKey = animal and animal.key or nil
    find.prompt = (randomInt(2) == 1) and "name" or "sound"
    return animal
end

function modes.beginFind(state)
    state.find = {
        order = modes.shuffled(#state.animals),
        index = 0,
        target = nil,
        prompt = "name",
        foundCount = 0,
        celebrateT = 0,
        lastKey = nil
    }
    modes.nextPrompt(state)
end

function modes.answer(state, animal)
    local find = state.find
    if not find or not find.target then
        return "none"
    end

    if animal == find.target then
        find.foundCount = find.foundCount + 1
        if find.foundCount >= #state.animals then
            state.phase = "celebrating"
            find.celebrateT = 0
            return "complete"
        end
        modes.nextPrompt(state)
        return "correct"
    end

    return "wrong"
end

return modes
