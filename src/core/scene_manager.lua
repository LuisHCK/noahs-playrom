local SceneryInit = require("libs.scenery.scenery")
local modules = require("src.core.modules")

local sceneManager = {
    scenery = nil
}

function sceneManager:build()
    -- Base scenes always registered.
    local entries = {
        { path = "src.scenes.boot", key = "boot", default = true },
        { path = "src.scenes.main_menu", key = "main_menu" }
    }

    -- Register every module scene declared in the module manifest.
    for _, entry in ipairs(modules.sceneEntries()) do
        entries[#entries + 1] = entry
    end

    self.scenery = SceneryInit(unpack(entries))
    return self.scenery
end

return sceneManager
