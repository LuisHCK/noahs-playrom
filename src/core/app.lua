local config = require("src.core.config")
local viewport = require("src.core.viewport")
local storage = require("src.core.storage")
local i18n = require("src.core.i18n")
local assets = require("src.core.assets")
local audio = require("src.core.audio")
local fonts = require("src.core.fonts")
local sceneManager = require("src.core.scene_manager")

local app = {
    scenery = nil,
    settings = {}
}

-- Shared services exposed to all scenes.
local function buildContext()
    return {
        i18n = i18n,
        assets = assets,
        audio = audio,
        fonts = fonts,
        viewport = viewport,
        saveSettings = function()
            storage:save({
                language = i18n:getLanguage(),
                assetProfile = assets:getProfile()
            })
        end
    }
end

function app:load()
    -- Restore persisted user preferences.
    self.settings = storage:load()
    i18n:setLanguage(self.settings.language or config.defaultLanguage)
    assets:setProfile(self.settings.assetProfile or config.defaultAssetProfile)

    viewport:update(love.graphics.getDimensions())

    self.scenery = sceneManager:build()
    self.scenery:load(buildContext())
end

function app:update(dt)
    self.scenery:update(dt)
end

function app:draw()
    -- Render everything in virtual 16:9 space.
    viewport:beginDraw()
    self.scenery:draw()
    viewport:endDraw()
end

function app:resize(w, h)
    viewport:update(w, h)
    if self.scenery.resize then
        self.scenery:resize(config.baseWidth, config.baseHeight)
    end
end

function app:mousepressed(x, y, button, istouch, presses)
    -- Convert raw screen coords to virtual coords before dispatch.
    local vx, vy = viewport:toVirtual(x, y)
    if self.scenery.mousepressed then
        self.scenery:mousepressed(vx, vy, button, istouch, presses)
    end
end

function app:mousereleased(x, y, button, istouch, presses)
    local vx, vy = viewport:toVirtual(x, y)
    if self.scenery.mousereleased then
        self.scenery:mousereleased(vx, vy, button, istouch, presses)
    end
end

function app:touchpressed(id, x, y, dx, dy, pressure)
    -- Love touch coords are normalized [0..1], so map to pixels first.
    local windowW, windowH = love.graphics.getDimensions()
    local px = x * windowW
    local py = y * windowH
    local vx, vy = viewport:toVirtual(px, py)

    if self.scenery.touchpressed then
        self.scenery:touchpressed(id, vx, vy, dx, dy, pressure)
    end
end

function app:touchreleased(id, x, y, dx, dy, pressure)
    local windowW, windowH = love.graphics.getDimensions()
    local px = x * windowW
    local py = y * windowH
    local vx, vy = viewport:toVirtual(px, py)

    if self.scenery.touchreleased then
        self.scenery:touchreleased(id, vx, vy, dx, dy, pressure)
    end
end

function app:keypressed(key, scancode, isrepeat)
    if self.scenery.keypressed then
        self.scenery:keypressed(key, scancode, isrepeat)
    end
end

return app
