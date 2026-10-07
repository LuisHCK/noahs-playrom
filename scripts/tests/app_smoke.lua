package.path = "./?.lua;./?/init.lua;" .. package.path

local function noop() end

local function flex()
    return setmetatable({}, {
        __index = function() return flex() end,
        __call = function() return flex() end
    })
end

love = {
    filesystem = {
        getInfo = function() return nil end,
        getDirectoryItems = function() return {} end,
        load = function() return nil end,
        write = noop
    },
    graphics = setmetatable({
        newImage = function() return flex() end,
        newQuad = function() return flex() end,
        newFont = function() return flex() end,
        getFont = function() return flex() end,
        getDimensions = function() return 1280, 720 end
    }, { __index = function() return noop end }),
    audio = { newSource = function() return flex() end },
    window = { setFullscreen = noop, getMode = function() return 1280, 720, {} end },
    system = { getOS = function() return "OS X" end },
    handlers = {
        mousepressed = true,
        mousereleased = true,
        mousemoved = true,
        touchpressed = true,
        touchreleased = true,
        touchmoved = true,
        keypressed = true,
        wheelmoved = true,
        resize = true
    },
    timer = { getFPS = function() return 60 end }
}

local app = require("src.core.app")

local function step(label)
    app:update(0.016)
    app:draw()
    print("ok: " .. label)
end

app:load()
step("boot -> main_menu draw/update")

-- Visit every module tile (returning to the menu in between) and draw each.
local layout = require("src.scenes.main_menu.layout")
local viewport = require("src.core.viewport")
local menuLayout = layout.build(viewport)

for index = 1, #menuLayout.moduleSlots do
    local slot = menuLayout.moduleSlots[index]
    local cx, cy = slot.x + slot.width / 2, slot.y + slot.height / 2
    app:mousepressed(cx, cy)
    app:mousereleased(cx, cy)
    for _ = 1, 40 do
        app:update(0.05)
        app:draw()
    end
    print("ok: visited module slot " .. index)

    app:mousepressed(40, 40)
    app:mousereleased(40, 40)
    for _ = 1, 5 do
        app:update(0.05)
        app:draw()
    end
end
print("ok: visited all modules and returned to the menu")

print("APP SMOKE PASSED")
