local layout = require("src.scenes.watch.settings.layout")
local render = require("src.scenes.watch.settings.render")

local scene = {}

local function contains(rect, x, y)
    return x >= rect.x and x <= rect.x + rect.width and y >= rect.y and y <= rect.y + rect.height
end

function scene:load(context)
    self.context = context
    self.layout = layout.build(context.viewport)

    -- Store initial volume on the state.
    self.state = { volume = context.audio:getVolume() }

    self.viewportSnapshot = { w = context.viewport.width, h = context.viewport.height }
    context.audio:play("common.bgm.menu")
end

function scene:resize()
    self.layout = layout.build(self.context.viewport)
end

function scene:update(dt)
    local vp = self.context.viewport
    if vp.width ~= self.viewportSnapshot.w or vp.height ~= self.viewportSnapshot.h then
        self.layout = layout.build(vp)
        self.viewportSnapshot.w = vp.width
        self.viewportSnapshot.h = vp.height
    end
end

function scene:draw()
    render.draw(self.state, self.layout)
end

function scene:mousepressed(x, y)
    if contains(self.layout.backButton, x, y) then
        self.context.saveSettings()
        self.setScene("watch_main_menu", self.context)
        return
    end
    if contains(self.layout.volumeRect, x, y) then
        self.state.volume = self.layout.nextVolume(self.state.volume)
        self.context.audio:setVolume(self.state.volume)
        self.context.audio:play("alphabet.en.letters.a")
    end
end

function scene:mousereleased(x, y) end

function scene:touchpressed(id, x, y)
    if contains(self.layout.backButton, x, y) then
        self.context.saveSettings()
        self.setScene("watch_main_menu", self.context)
        return
    end
    if contains(self.layout.volumeRect, x, y) then
        self.state.volume = self.layout.nextVolume(self.state.volume)
        self.context.audio:setVolume(self.state.volume)
        self.context.audio:play("alphabet.en.letters.a")
    end
end

function scene:touchreleased(id, x, y) end

return scene
