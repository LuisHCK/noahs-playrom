local Button = require("src.ui.button")
local modulesData = require("src.data.content.modules")

local model = {}

local moduleOrder = { "alphabet", "animals", "numbers", "universe" }

function model.createState(context, layout)
    local state = {
        context = context,
        layout = layout,
        moduleButtons = {},
        languageButton = nil,
        profileButton = nil,
        transitionDelay = 0.5,
        transitionTimer = 0,
        queuedScene = nil
    }

    state.toggleAssetProfile = function()
        if context.assets:getProfile() == "prototype" then
            context.assets:setProfile("final")
        else
            context.assets:setProfile("prototype")
        end
        context.saveSettings()
    end

    for index, moduleId in ipairs(moduleOrder) do
        local slot = layout.moduleSlots[index]
        state.moduleButtons[index] = Button.new({
            id = moduleId,
            x = slot.x,
            y = slot.y,
            width = slot.width,
            height = slot.height,
            text = moduleId,
            onClick = function(id)
                -- Delay transition to let tap animation breathe.
                if state.transitionTimer <= 0 then
                    state.queuedScene = modulesData[id].scene
                    state.transitionTimer = state.transitionDelay
                end
            end
        })
        state.moduleButtons[index].visualScale = 1
    end

    state.languageButton = Button.new({
        id = "language",
        x = layout.languageButton.x,
        y = layout.languageButton.y,
        width = layout.languageButton.width,
        height = layout.languageButton.height,
        text = "LANG",
        onClick = function()
            context.i18n:toggleLanguage()
            context.saveSettings()
        end
    })

    state.profileButton = Button.new({
        id = "profile",
        x = layout.profileButton.x,
        y = layout.profileButton.y,
        width = layout.profileButton.width,
        height = layout.profileButton.height,
        text = "PROFILE",
        onClick = function()
            state.toggleAssetProfile()
        end
    })

    return state
end

return model
