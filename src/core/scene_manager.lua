local SceneryInit = require("libs.scenery.scenery")
local config = require("src.core.config")

local sceneManager = {
    scenery = nil
}

function sceneManager:build()
    -- Base scenes always registered.
    local entries = {
        { path = "src.scenes.boot", key = "boot", default = true },
        { path = "src.scenes.main_menu", key = "main_menu" },
        { path = "src.scenes.modules.alphabet_scene", key = "alphabet" },
        { path = "src.scenes.modules.animals", key = "animals" },
        { path = "src.scenes.modules.numbers", key = "numbers" },
        { path = "src.scenes.modules.universe", key = "universe" }
    }

    -- Register watch-mode scenes when deviceProfile is "watch".
    if config.deviceProfile == "watch" then
        entries[#entries + 1] = { path = "src.scenes.watch.main_menu", key = "watch_main_menu" }
        entries[#entries + 1] = { path = "src.scenes.watch.alphabet", key = "watch_alphabet" }
        entries[#entries + 1] = { path = "src.scenes.watch.settings", key = "watch_settings" }
    end

    self.scenery = SceneryInit(unpack(entries))
    return self.scenery
end

return sceneManager
