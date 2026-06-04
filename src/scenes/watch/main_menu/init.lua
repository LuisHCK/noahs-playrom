local layout = require("src.scenes.watch.main_menu.layout")
local model = require("src.scenes.watch.main_menu.model")
local input = require("src.scenes.watch.main_menu.input")
local render = require("src.scenes.watch.main_menu.render")

local menu = {}

function menu:load(context)
    self.layout = layout.build(context.viewport)
    self.state = model.create(context, self.setScene)
    self.viewportSnapshot = { w = context.viewport.width, h = context.viewport.height }
    context.audio:play("common.bgm.menu")
end

function menu:resize()
    self.layout = layout.build(self.state.context.viewport)
end

function menu:update(dt)
    local vp = self.state.context.viewport
    if vp.width ~= self.viewportSnapshot.w or vp.height ~= self.viewportSnapshot.h then
        self.layout = layout.build(vp)
        self.viewportSnapshot.w = vp.width
        self.viewportSnapshot.h = vp.height
    end
    model.update(self.state, dt)
end

function menu:draw()
    render.draw(self.state, self.layout)
end

function menu:mousepressed(x, y)
    input.begin(self.state, "mouse", x, y)
end

function menu:mousereleased(x, y)
    input.finish(self.state, "mouse", x, y)
end

function menu:touchpressed(id, x, y)
    input.begin(self.state, id, x, y)
end

function menu:touchreleased(id, x, y)
    input.finish(self.state, id, x, y)
end

function menu:touchmoved(id, x, y)
    input.move(self.state, id, x, y)
end

return menu
