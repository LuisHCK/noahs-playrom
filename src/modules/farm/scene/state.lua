local config = require("src.modules.farm.content.config")
local farmContent = require("src.modules.farm.content.farm")
local camera = require("src.modules.farm.scene.camera")
local modes = require("src.modules.farm.scene.modes")

local state = {}

local function buildAnimals()
    local animals = {}
    for index, def in ipairs(farmContent.animals) do
        local baseline = def.y or config.baselineY
        animals[index] = {
            key = def.key,
            home = def.home,
            x = def.x - def.w * 0.5,
            y = baseline - def.h,
            width = def.w,
            height = def.h,
            animT = 0,
            shakeT = 0
        }
    end
    return animals
end

local function buildStructures()
    local structures = {}
    for index, def in ipairs(farmContent.structures) do
        local baseline = def.y or config.baselineY
        structures[index] = {
            id = def.id,
            kind = def.kind,
            x = def.x - def.w * 0.5,
            y = baseline - def.h,
            width = def.w,
            height = def.h
        }
    end
    return structures
end

function state.create(context, layout)
    local self = {
        context = context,
        layout = layout,
        mode = "explore",
        phase = "playing",
        camera = { x = 0, velocity = 0 },
        pointer = nil,
        time = 0,
        lastDt = 1 / 60,
        animals = buildAnimals(),
        structures = buildStructures(),
        find = nil,
        viewportSnapshot = {
            w = context.viewport.width,
            h = context.viewport.height
        }
    }
    return self
end

function state.animalAt(self, worldX, worldY)
    for index = #self.animals, 1, -1 do
        local animal = self.animals[index]
        if worldX >= animal.x and worldX <= animal.x + animal.width
            and worldY >= animal.y and worldY <= animal.y + animal.height then
            return animal
        end
    end
    return nil
end

function state.worldFromVirtual(self, virtualX, virtualY)
    return virtualX - self.layout.content.x + self.camera.x, virtualY - self.layout.content.y
end

function state.interact(self, animal)
    self.lastAnimal = animal
    animal.animT = config.bounceDuration

    if self.mode == "explore" then
        return "sound"
    elseif self.mode == "learn" then
        return "name"
    elseif self.mode == "find" then
        local result = modes.answer(self, animal)
        if result == "wrong" then
            animal.shakeT = config.shakeDuration
            return "wrong"
        elseif result == "correct" then
            return "correct"
        elseif result == "complete" then
            return "complete"
        end
    end

    return nil
end

function state.setMode(self, mode)
    self.mode = mode
    self.phase = "playing"
    if mode == "find" then
        modes.beginFind(self)
    end
end

function state.restart(self)
    self.phase = "playing"
    if self.mode == "find" then
        modes.beginFind(self)
    end
end

function state.update(self, dt)
    self.time = self.time + dt
    self.lastDt = dt

    for _, animal in ipairs(self.animals) do
        if animal.animT > 0 then
            animal.animT = math.max(0, animal.animT - dt)
        end
        if animal.shakeT > 0 then
            animal.shakeT = math.max(0, animal.shakeT - dt)
        end
    end

    camera.update(self.camera, dt, config, config.worldWidth, self.layout.content.width)

    if self.find then
        if self.find.feedbackTimer and self.find.feedbackTimer > 0 then
            self.find.feedbackTimer = math.max(0, self.find.feedbackTimer - dt)
        end
        if self.phase == "celebrating" then
            self.find.celebrateT = (self.find.celebrateT or 0) + dt
        end
    end
end

return state
