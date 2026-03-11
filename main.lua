local app = require("src.core.app")

function love.load(args)
    app:load(args)
end

function love.update(dt)
    app:update(dt)
end

function love.draw()
    app:draw()
end

function love.resize(w, h)
    app:resize(w, h)
end

function love.mousepressed(x, y, button, istouch, presses)
    app:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    app:mousereleased(x, y, button, istouch, presses)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    app:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    app:touchreleased(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    app:touchmoved(id, x, y, dx, dy, pressure)
end

function love.keypressed(key, scancode, isrepeat)
    app:keypressed(key, scancode, isrepeat)
end
