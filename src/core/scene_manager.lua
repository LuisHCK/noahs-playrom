local SceneryInit = require("libs.scenery.scenery")

local sceneManager = {
    scenery = nil
}

function sceneManager:build()
    -- Centralized scene registry for deterministic navigation keys.
    self.scenery = SceneryInit(
        { path = "src.scenes.boot", key = "boot", default = true },
        { path = "src.scenes.main_menu", key = "main_menu" },
        { path = "src.scenes.modules.alphabet_scene", key = "alphabet" },
        { path = "src.scenes.modules.animals", key = "animals" },
        { path = "src.scenes.modules.numbers", key = "numbers" },
        { path = "src.scenes.modules.universe", key = "universe" }
    )
    return self.scenery
end

return sceneManager
